# ParkOps — Week 7 Clean Architecture Code Review

> Mobile Programming · Politeknik Negeri Malang · Group Activity: *15-Minute Code Review*

## 1. Scope and method

We audited the `lib/` folder **before** any refactoring, following the Week 7 steps: map every file to a layer, run the three violation-hunting greps, then record findings.

> **Note on stack:** Currently ParkOps has **no Dio and no SQLite**. Its data sources are **Cloud Firestore**, **SharedPreferences** and **in-memory dummy data**. So we applied the same rules to the equivalent classes: `FirebaseFirestore`, `SharedPreferences` and `dummyLots` play the role of Dio/SQLite.

> **Limitation:** the archive contains `lib/` only (no `pubspec.yaml`, no `test/`), so `flutter analyze` and `flutter test` were not run in this review. Grep results below are real output from the extracted code.

### Current dependency arrows (before)

```
pages ──► widgets/dummy_lots.dart (data + entity + UI + global state)
pages ──► SharedPreferences (directly)
widgets/app_bottom_nav ──► pages            ← arrow points OUTWARD
camera_pages ◄──► map_pages                 ← circular import
providers ──► FirebaseService (concrete) ──► FirebaseFirestore.instance
        └─ never consumed by any page
```

Target (slide 7): `presentation → domain ← data`

---

## 2. File → layer map

| File | Layer today | Problem? |
|---|---|---|
| `main.dart` | presentation | `RootGate` reads `SharedPreferences` itself (l.50); plain `StatefulWidget`, not Riverpod |
| `firebase_options.dart` | config (generated) | OK |
| `models/parking_zone.dart` | **domain + data mixed** | `fromFirestore` mapping inside the business object; `status` is a magic string |
| `services/firebase_service.dart` | data | No interface; hard-codes `FirebaseFirestore.instance` |
| `providers/parking_provider.dart` | presentation (DI) | Typed to concrete `FirebaseService`; **no page uses it** |
| `providers/auth_provider.dart` | — | **Empty file (0 bytes)** |
| `data/api_clients.dart`, `auth_repo.dart`, `token_store.dart` | — | **Empty files (0 bytes)** |
| `pages/login_pages.dart`, `register_page.dart` | presentation | Call `SharedPreferences` directly; credentials never used |
| `pages/onboarding_pages.dart` | presentation | `SharedPreferences` (l.144); defines the storage key `kOnboardingDoneKey` |
| `pages/information_pages.dart` | presentation | `SharedPreferences` (l.346); "Login as Admin" has no auth check |
| `pages/homepage.dart`, `camera_pages.dart`, `map_pages.dart` | presentation | Read `dummyLots` + global `selectedLotIndex`; aggregation inside `build()` |
| `pages/admin_dashboard_page.dart` | presentation | Hard-coded values (e.g. a fixed date string) |
| `widgets/dummy_lots.dart` | **mixed (4 roles)** | Dummy data + entity + `Color` + shared widgets + global state |
| `widgets/app_bottom_nav.dart` | presentation | Imports 4 pages (dependency points outward) |
| `theme/app_colors.dart` | presentation | OK |

---

## 3. The three sterility greps (BEFORE refactoring)

**Grep 1 — widgets touching data directly** (`lib/pages`, `lib/widgets`)

Literal slide pattern `Dio( | openDatabase | FlutterSecureStorage` → **0 hits** (this project has neither).
Stack-equivalent pattern `SharedPreferences | cloud_firestore | FirebaseFirestore | FirebaseService` → **5 hits:**

```
lib/pages/login_pages.dart:30         SharedPreferences.getInstance()
lib/pages/register_page.dart:35       SharedPreferences.getInstance()
lib/pages/onboarding_pages.dart:144   SharedPreferences.getInstance()
lib/pages/information_pages.dart:346  SharedPreferences.getInstance()
lib/pages/onboarding_pages.dart:8     (comment referencing SharedPreferences)
```

**Grep 2 — business logic in `build()`** (`DateFormat | jsonDecode | toIso8601String`) → **0 hits.**
Equivalent logic that *is* present:

```
lib/pages/homepage.dart:18-19   dummyLots.fold(...) aggregating free/total slots inside build()
lib/widgets/dummy_lots.dart:35  available <= total * 0.2   (status rule, duplicated in parking_zone.dart:25)
```

**Grep 3 — leaking DI** (`Repository( | Dio(BaseOptions | FirebaseService(`) → **1 hit:**

```
lib/providers/parking_provider.dart:7   return FirebaseService();
```

**Status: FAIL** — Grep 1 must reach zero hits in presentation before the refactor is "done" (slide 21).

---

## 4. Findings

### 4.1 Dependency violations (required: 2 · found: 3)

| ID | Where | What is wrong | Fix |
|---|---|---|---|
| **DV-1** | `login_pages.dart:30`, `register_page.dart:35` | `_login()` / `_register()` call `SharedPreferences` straight from the widget state. Username/password controllers are never read, so there is no real auth either. | Introduce `AuthRepository` (interface in domain) and call it through a Riverpod notifier. |
| **DV-2** | `onboarding_pages.dart:144`, `information_pages.dart:346`, `main.dart:50` | The same "onboarding done" flag is read/written from **5 places**. The storage key `kOnboardingDoneKey` is declared inside a *page* file and imported by others, so a data detail lives in the UI. | One `OnboardingRepository` (`isDone()` / `setDone()`) + a provider. Move the key into `data/`. |
| **DV-3** | `homepage.dart:18-32`, `camera_pages.dart:30-32`, `map_pages.dart:21-27`; also `app_bottom_nav.dart:2-5` | Pages depend directly on the in-memory data source `dummyLots` and a global `selectedLotIndex`. Separately, `widgets/` imports `pages/` and `camera_pages ↔ map_pages` import each other (circular). | Pages read zones through providers; selected lot becomes a Riverpod `Notifier`; navigation moves to a single `routes.dart`. |

### 4.2 Contract issues (required: 2 · found: 3)

| ID | Where | What is wrong | Fix |
|---|---|---|---|
| **CI-1** | `services/firebase_service.dart`, `providers/parking_provider.dart:6` | **No repository contract.** The concrete Firestore class *is* the contract, and the provider is typed `Provider<FirebaseService>`. `data/auth_repo.dart` was meant to hold one but is empty. | `abstract class ParkingRepository` in `domain/repositories/`, `ParkingRepositoryImpl` in `data/repositories/`. |
| **CI-2** | `models/parking_zone.dart:30,58`, `widgets/dummy_lots.dart:39` | **Entity and model are merged and leak into the UI.** `ParkingZone` / `ParkingSlot` contain `fromFirestore()` mapping and are returned by providers to widgets. `DummyLot` is a second, parallel "entity" that even holds a Flutter `Color`. The status rule (`full/tight/ok`) is duplicated in both with magic strings. | Pure entities in `domain/` (with a `ZoneStatus` enum); `ParkingZoneModel.fromFirestore().toEntity()` in `data/models/`. Delete `DummyLot`. |
| **CI-3** | `firebase_service.dart:21`, `parking_zone.dart:37` | **Failures are not part of the contract.** No `Failure` type exists; raw Firestore exceptions reach the UI. `doc.data()!` crashes if a document is deleted. `data['lastUpdated'] as DateTime?` is very likely a runtime bug: Firestore returns a `Timestamp`, not a `DateTime` *(verify on real data)*. | Map exceptions to `Failure` in the repository; convert `Timestamp → DateTime` inside the model. |

### 4.3 Over-engineering (required: 1 · found: 1)

| ID | Where | What is wrong | Decision |
|---|---|---|---|
| **OE-1** | `data/api_clients.dart`, `data/auth_repo.dart`, `data/token_store.dart`, `providers/auth_provider.dart` | Four **0-byte** files: scaffolding for an HTTP client + token store + auth repository that the app does not use (it has no REST backend). This is speculative structure with no code behind it. | **Delete now**, add back when a real backend exists. |
| **OE-1b** | *(proposal-level)* | An AI-style proposal would add `WatchZones`, `WatchZone`, `WatchSlots` use cases. Each would be a one-line pass-through to the repository. | **Reject.** Slide 18: a use case is needed only when it combines >1 repo or owns rules. Providers call the repository directly. |

### 4.4 DI issue (required: 1 · found: 1 main + 2 related)

| ID | Where | What is wrong | Fix |
|---|---|---|---|
| **DI-1** | `parking_provider.dart:7`, `firebase_service.dart:5` | `FirebaseService()` is constructed inside the provider, and the service hard-codes `FirebaseFirestore.instance` in a field initializer. A test **cannot** swap in a fake. | Provider returns `ParkingRepository`; `ParkingRepositoryImpl({required FirebaseFirestore firestore})` receives Firestore via constructor. |
| DI-2 | `main.dart`, all `pages/` | Riverpod is installed (`ProviderScope`) but **no page uses it**: zero `ref.watch`, zero `ConsumerWidget`. The three stream providers are dead code, so the real Firestore pipeline is never displayed. | Convert pages to `ConsumerWidget`; replace `dummyLots` with `zonesStreamProvider`. |
| DI-3 | 5 call sites of `SharedPreferences.getInstance()` | Acts as a hidden service locator. | Single `sharedPreferencesProvider`, overridden in `main()`. |

## Refactor plan

Target structure:

```
lib/
├── core/failures.dart
├── features/
│   ├── parking/
│   │   ├── domain/{entities, repositories/parking_repository.dart}
│   │   ├── data/{models, repositories/parking_repository_impl.dart}
│   │   └── presentation/{providers, pages}
│   ├── onboarding/   (domain / data / presentation)
│   └── auth/         (add only when a backend exists)
├── theme/app_colors.dart
└── routes.dart
```
