const { before, after, beforeEach, test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { createHash } = require('node:crypto');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, setDoc, getDoc, getDocs, updateDoc, deleteDoc, collection, query, where, writeBatch, serverTimestamp, Timestamp } = require('firebase/firestore');
let env;
const foldSource = fs.readFileSync(path.join(__dirname, '../lib/models/unicode_casefold.dart'), 'utf8');
const folds = new Map([...foldSource.matchAll(/0x([A-F0-9]+): 0x([A-F0-9]+)/g)].map(m => [parseInt(m[1],16),parseInt(m[2],16)]));
const nameKeyFor = name => [...name.trim()].map(c=>String.fromCodePoint(folds.get(c.codePointAt(0)) ?? c.codePointAt(0))).join('');
const idFor = (uid, name) => `${uid}_${createHash('sha256').update(nameKeyFor(name)).digest('hex')}`;
const recipe = (uid = 'alice', overrides = {}) => {
  const data = { userId: uid, name: 'Pho Bo', category: 'Lunch', difficulty: 'Medium', cookTime: 60, servings: null, favorite: false, notes: '', createdAt: serverTimestamp(), ...overrides };
  return { ...data, nameKey: nameKeyFor(typeof data.name === 'string' ? data.name : 'Pho Bo'), id: idFor(uid, typeof data.name === 'string' ? data.name : 'Pho Bo') };
};
const db = (uid = 'alice') => env.authenticatedContext(uid).firestore();
before(async () => {
  env = await initializeTestEnvironment({ projectId: 'demo-recipebox-qe190133', firestore: { host: '127.0.0.1', port: 8081, rules: fs.readFileSync(path.join(__dirname, '../firestore.rules'), 'utf8') } });
});
beforeEach(async () => env.clearFirestore());
after(async () => env?.cleanup());

test('valid owner create, scoped list, update, favorite and delete succeed', async () => {
  const store = db(), data = recipe(), ref = doc(store, 'recipes', data.id);
  await assertSucceeds(setDoc(ref, data));
  await assertSucceeds(getDoc(ref));
  assert.equal((await assertSucceeds(getDocs(query(collection(store, 'recipes'), where('userId', '==', 'alice'))))).size, 1);
  await assertSucceeds(updateDoc(ref, { difficulty: 'Hard', cookTime: 120, servings: 4, favorite: true, notes: 'Simmer slowly.' }));
  await assertSucceeds(deleteDoc(ref));
});
test('unauthenticated create, read, query, update and delete are refused', async () => {
  const data = recipe(); await setDoc(doc(db(), 'recipes', data.id), data);
  const store = env.unauthenticatedContext().firestore(), ref = doc(store, 'recipes', data.id);
  await assertFails(getDoc(ref)); await assertFails(getDocs(collection(store, 'recipes')));
  await assertFails(setDoc(doc(store, 'recipes', 'new'), data));
  await assertFails(updateDoc(ref, { favorite: true })); await assertFails(deleteDoc(ref));
});
test('other user cannot read, modify, delete or claim a recipe', async () => {
  const data = recipe(); await setDoc(doc(db(), 'recipes', data.id), data);
  const ref = doc(db('bob'), 'recipes', data.id);
  await assertFails(getDoc(ref)); await assertFails(updateDoc(ref, { userId: 'bob' }));
  await assertFails(updateDoc(ref, { favorite: true })); await assertFails(deleteDoc(ref));
  await assertFails(setDoc(doc(db('bob'), 'recipes', data.id), data));
});
test('unscoped and foreign-owner collection queries are refused', async () => {
  await assertFails(getDocs(collection(db(), 'recipes')));
  await assertFails(getDocs(query(collection(db('bob'), 'recipes'), where('userId', '==', 'alice'))));
});
for (const [label, overrides] of [
  ['empty name', { name: '' }], ['spaces-only name', { name: '  \t\n  ' }], ['long name', { name: 'a'.repeat(81) }],
  ['non-string name', { name: 42 }], ['unknown category', { category: 'Snack' }], ['unknown difficulty', { difficulty: 'Expert' }],
  ['fractional cookTime', { cookTime: 1.5 }], ['zero cookTime', { cookTime: 0 }], ['negative cookTime', { cookTime: -1 }],
  ['cookTime over 600', { cookTime: 601 }], ['string cookTime', { cookTime: '25' }], ['null cookTime', { cookTime: null }],
  ['fractional servings', { servings: 2.5 }], ['zero servings', { servings: 0 }], ['negative servings', { servings: -1 }],
  ['servings over 20', { servings: 21 }], ['string servings', { servings: '4' }],
  ['long notes', { notes: 'a'.repeat(301) }], ['non-string notes', { notes: 5 }],
  ['non-boolean favorite', { favorite: 'yes' }], ['invalid timestamp', { createdAt: 'today' }], ['extra field', { admin: true }],
]) {
  test(`direct invalid create rejected: ${label}`, async () => {
    const data = recipe('alice', overrides); await assertFails(setDoc(doc(db(), 'recipes', data.id), data));
  });
  test(`direct invalid update rejected: ${label}`, async () => {
    const data = recipe(), ref = doc(db(), 'recipes', data.id); await setDoc(ref, data);
    await assertFails(updateDoc(ref, overrides));
  });
}
test('missing required fields are refused', async () => {
  for (const key of ['id','userId','name','category','difficulty','cookTime','favorite','createdAt','nameKey']) {
    const data=recipe(); const id=data.id; delete data[key];
    await assertFails(setDoc(doc(db(),'recipes',id),data));
  }
});
test('boundary values and absent optional fields are valid', async () => {
  for (const [cookTime,servings] of [[1,1],[600,20],[25,null]]) {
    const data = recipe('alice', { name: `${cookTime}`.padEnd(80,'n'), cookTime, servings, notes:'n'.repeat(300) });
    await assertSucceeds(setDoc(doc(db(),'recipes',data.id),data));
  }
  const data=recipe('alice',{name:'Optional fields'});delete data.servings;delete data.notes;
  await assertSucceeds(setDoc(doc(db(),'recipes',data.id),data));
});
test('arbitrary IDs and case-variant duplicate documents are refused', async () => {
  const original=recipe();await setDoc(doc(db(),'recipes',original.id),original);
  const duplicate=recipe('alice',{name:' pho BO '});assert.equal(duplicate.id,original.id);
  await assertFails(setDoc(doc(db(),'recipes','random-second-document'),{...duplicate,id:'random-second-document'}));
  await assertFails(setDoc(doc(db(),'recipes',duplicate.id),duplicate));
  assert.equal((await getDocs(query(collection(db(),'recipes'),where('userId','==','alice')))).size,1);
});
test('different people may save the same recipe name', async () => {
  for(const uid of ['alice','bob']){const data=recipe(uid);await assertSucceeds(setDoc(doc(db(uid),'recipes',data.id),data));}
});
test('rename is atomic and preserves original creation time',async()=>{
  const store=db(),original=recipe(),oldRef=doc(store,'recipes',original.id);await setDoc(oldRef,original);
  const saved=(await getDoc(oldRef)).data();const renamed={...saved,name:'Pho Ga',nameKey:nameKeyFor('Pho Ga')};renamed.id=idFor('alice',renamed.name);
  const batch=writeBatch(store);batch.set(doc(store,'recipes',renamed.id),renamed);batch.delete(oldRef);await assertSucceeds(batch.commit());
  assert.equal((await getDoc(oldRef)).exists(),false);
  assert.equal((await getDoc(doc(store,'recipes',renamed.id))).data().createdAt.toMillis(),saved.createdAt.toMillis());
});
test('creation time and owner cannot be changed',async()=>{
  const data=recipe(),ref=doc(db(),'recipes',data.id);await setDoc(ref,data);
  await assertFails(updateDoc(ref,{createdAt:Timestamp.fromMillis(0)}));await assertFails(updateDoc(ref,{userId:'bob'}));
});
test('unrelated collections remain denied',async()=>{
  await assertFails(setDoc(doc(db(),'users','alice'),{name:'Alice'}));await assertFails(getDoc(doc(db(),'users','alice')));
});

for (const [upper, lower] of [['PHỞ BÒ','phở bò'],['Éclair','éclair'],['ĐẬU','đậu'],['Σ','ς'],['S','ſ'],['Μ','µ'],['ẞ','ß']]) {
 test(`Unicode name succeeds and direct alternate-key duplicate is refused: ${upper}`,async()=>{
  const store=db(),first=recipe('alice',{name:upper});await assertSucceeds(setDoc(doc(store,'recipes',first.id),first));
  const second=recipe('alice',{name:lower});assert.equal(first.id,second.id);
  const alternate=lower.trim();const badId=`alice_${createHash('sha256').update(alternate).digest('hex')}`;
  if(alternate!==nameKeyFor(lower))await assertFails(setDoc(doc(store,'recipes',badId),{...second,id:badId,nameKey:alternate}));
  await assertFails(setDoc(doc(store,'recipes',first.id),second));
  assert.equal((await getDocs(query(collection(store,'recipes'),where('userId','==','alice')))).size,1);
 });
}
for(const name of ['İstanbul','Soup (A+B) [2].*?^$|\\x','A\\E.*B','Emoji 🍲 soup','e\u0301clair']) {
 test(`Valid literal Unicode/punctuation name: ${name}`,async()=>{
  const data=recipe('alice',{name});await assertSucceeds(setDoc(doc(db(),'recipes',data.id),data));
 });
}
test('forged nameKey cannot redirect the name to a different canonical ID',async()=>{
 for(const key of ['eclair','Éclair','a.*','bad\\E.*\\Q']){
  const data=recipe('alice',{name:'Éclair'});data.nameKey=key;data.id=`alice_${createHash('sha256').update(key).digest('hex')}`;
  if(key!==nameKeyFor(data.name))await assertFails(setDoc(doc(db(),'recipes',data.id),data));
 }
});

for(const [source,target] of [['ᲀ','в'],['ᲁ','д'],['ᲂ','о'],['ᲃ','с'],['ᲄ','т'],['ᲅ','т'],['ᲆ','ъ'],['ᲇ','ѣ'],['ᲈ','ꙋ']]){
 test(`historical Cyrillic case-fold compatibility ${source}`,async()=>{
  const first=recipe('alice',{name:source});assert.equal(first.nameKey,target);await assertSucceeds(setDoc(doc(db(),'recipes',first.id),first));
  const invalid={...first,nameKey:source,id:`alice_${createHash('sha256').update(source).digest('hex')}`};await assertFails(setDoc(doc(db(),'recipes',invalid.id),invalid));
 });
}
