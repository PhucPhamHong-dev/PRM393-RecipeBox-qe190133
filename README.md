# RecipeBox

PRM393 practical exam implementation for qe190133, Phạm Hồng Phúc.

A Flutter Android app with real Firebase Email/Password Authentication and a private Firestore recipe collection. Material 3 uses a warm cream background, terracotta actions and native food illustrations.

## Run

Use Flutter 3.47.8 / Dart 3.13.7 or a compatible newer SDK, Java 21 and the Android SDK. Client Firebase configuration is included for `recipebox-qe190133`, Android package `com.qe190133.recipebox`. No admin credentials are required.

```sh
flutter pub get
flutter run
flutter build apk --release
```

A fresh checkout builds without source edits. The grader account and password are in the private submission report, not in this public source.

## Behavior

- Public Home with Login, Register and three feature cards.
- Protected List and Detail screens; Firebase auth state gates the initial screen.
- Real registration/login, field validation and Firebase errors under the submit button.
- Add, edit, confirmed delete and favorite actions persist to Firestore.
- Sorting uses ascending cookTime, then case-insensitive recipe name.
- Category, difficulty, favorites and trimmed case-insensitive name-or-notes search combine immediately.
- Summary describes visible results: Recipes, Favorites, Total time, then category counts ordered by descending count and fixed category order for ties.
- Shared form and consistent buttons, inputs, notice and recipe cards.
- Recipe added is cleared when another action starts, including opening Detail, changing filters, favoriting or starting another add. It cannot linger after editing or deleting a recipe.

## Database and uniqueness

Only the top-level `recipes` collection stores application data. Fields are exactly `id`, `userId`, `name`, `category`, `difficulty`, `cookTime`, `servings`, `favorite`, `notes`, `createdAt`.

Document ID = Firebase Auth UID + `_` + lowercase SHA-256 hex of `name.trim().toLowerCase()`. Rules independently recompute this ID, so a client cannot insert duplicate case-insensitive names under arbitrary IDs. Different users have separate IDs. Changing a name performs an atomic create/delete transaction while preserving the creation date and favorite flag.

`cookTime` is an integer from 1 through 600. `servings` is absent/null or an integer from 1 through 20. Notes default to an empty string. Creation uses a server timestamp. Rules validate all fields, ownership, allowed categories and difficulties, and deny access to every other collection. Existing documents can only be read or mutated by their owner. Authenticated transactions may check that a target ID does not yet exist.

## Validation

The form uses the exact exam messages and delays validation until submission. Add and Edit share the same validators. Rules repeat required database constraints independently of the form.

## Verification

```sh
flutter analyze
flutter test
```

Rules tests require the development packages listed in package.json and Java:

```sh
npm install
firebase emulators:exec --only firestore --project demo-recipebox "node --test tests/firestore.rules.test.cjs"
```

For live integration evidence, supply a fresh disposable test email and password privately using `--dart-define-from-file`; never commit that file. See the integration test for keys and test variables. App screenshots are captured from a real emulator session and kept outside the public source.

The focused `integration_test/notice_and_duplicate_test.dart` uses the seeded grader account to verify a mixed-case duplicate is rejected with unchanged document IDs and count, and checks that the add notice is absent after edit/delete. It restores the five-record collection after testing.

Deploy the checked-in Rules with the Firebase CLI after signing in to the intended project:

```sh
firebase deploy --only firestore --project recipebox-qe190133
```

The private `submission` directory contains the required student-code Word report and clean source ZIP. `pubspec.yaml` is at the archive root; build/cache, Git metadata, reports and admin keys are excluded.
