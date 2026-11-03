# RecipeBox verification checklist

Student: qe190133 — Phạm Hồng Phúc

Status terms: **ĐẠT**, **CHƯA ĐẠT**, **CHƯA KIỂM TRA**. Writing implementation alone does not establish a pass. Evidence below will be updated only after actual execution.

## Đáp ứng đề

| ID | Requirement | Verification | Evidence | Status |
|---|---|---|---|---|
| A01 | Public Home, Login, Register and at least 3 feature cards | Device + small-screen widget test | Pending | CHƯA KIỂM TRA |
| A02 | Real Email/Password registration and successful message | Live Firebase device flow | Pending | CHƯA KIỂM TRA |
| A03 | Login validation, wrong password error, valid login and Logout | Device + widget validation | Pending | CHƯA KIỂM TRA |
| A04 | Protected List/Detail, loading guard, no return to auth form after login | Runtime + navigation inspection | Pending | CHƯA KIỂM TRA |
| D01 | Exact recipes collection fields and valid sample data | Live Firestore data | Pending | CHƯA KIỂM TRA |
| D02 | Owner-only read/create/update/delete and anonymous denial | Rules emulator suite | Firebase agent | CHƯA KIỂM TRA |
| D03 | Database rejects bad fields, invalid integer boundaries, foreign owner | Rules suite + live invalid update | Pending | CHƯA KIỂM TRA |
| D04 | Case-insensitive per-owner unique recipe name | Rules suite + live duplicate attempt | Pending | CHƯA KIỂM TRA |
| F01 | Add validation exact messages, initially hidden and independently corrected | Widget and device test | Pending | CHƯA KIỂM TRA |
| F02 | Add saves live, clears form and shows Recipe added with new item | Device screenshot | Pending | CHƯA KIỂM TRA |
| L01 | Sort ascending cookTime; ties by case-insensitive name | Unit + seeded device list | Pending | CHƯA KIỂM TRA |
| L02 | Live favorite toggle, details entry, No recipes found | Device flow | Pending | CHƯA KIỂM TRA |
| L03 | Category/difficulty/favorites/search combine; search name or notes trimmed/case-insensitive | Unit + device flow | Pending | CHƯA KIỂM TRA |
| L04 | Clear resets all four controls; unfavorite while filtered removes matching item | Device flow | Pending | CHƯA KIỂM TRA |
| S01 | Visible Recipes/Favorites/Total time values and category breakdown order | Unit + device flow | Pending | CHƯA KIỂM TRA |
| E01 | Detail full fields and favorite | Device screenshot | Pending | CHƯA KIỂM TRA |
| E02 | Edit validation, Save, Cancel and real persistence | Device flow | Pending | CHƯA KIỂM TRA |
| E03 | Edited cookTime changes List position | Device flow | Pending | CHƯA KIỂM TRA |
| E04 | Delete Cancel/Delete dialog, immediate removal and persistence | Device flow + restart | Pending | CHƯA KIỂM TRA |
| I01 | Second account sees empty own list | Live second-account flow | Pending | CHƯA KIỂM TRA |
| P01 | Restart retains sign-in, records and favorites | Release restart | Pending | CHƯA KIỂM TRA |
| B01 | Analyze, release build, fresh ZIP build and APK install/open | CLI + device | Root | CHƯA KIỂM TRA |
| B02 | Public repository and durable APK link match submitted source | Git/archive/download verification | Root | CHƯA KIỂM TRA |
| B03 | Word exact metadata, genuine captioned screenshots and clean ZIP root | Artifact verification | Root | CHƯA KIỂM TRA |

## Chất lượng giao diện

| ID | Requirement | Verification | Evidence | Status |
|---|---|---|---|---|
| U01 | Consistent Material3 colors, type, forms, cards and buttons | Actual screenshots | Pending | CHƯA KIỂM TRA |
| U02 | No horizontal overflow on small phone | 320px widget test + screenshots | Pending | CHƯA KIỂM TRA |
| U03 | Scrolling and keyboard permit access to inputs/actions | Device form flow | Pending | CHƯA KIỂM TRA |
| U04 | Loading, empty, error and success states readable | Device flow + code inspection identified separately | Pending | CHƯA KIỂM TRA |
| U05 | Evidence image includes required matching message and data | Full-size screenshot review | Pending | CHƯA KIỂM TRA |
