# architecture.md — Technical Blueprint

## AI Studio — Flutter Client Architecture (Phase 1, Fast Tier)

---

## 1. Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (stable channel) |
| State Management | **GetX** — controllers, reactive state, dependency injection, routing |
| Backend | Firebase Cloud Functions / Cloud Run (Node.js) — not built by Flutter devs |
| Auth | Firebase Authentication (Google, Apple, Anonymous) |
| Realtime Data | Cloud Firestore (snapshot listeners) |
| File Storage | Firebase Cloud Storage |
| 3D Rendering | `o3d` or `flutter_scene` (interactive `.glb`/`.usdz` viewer) |
| Video Playback | `video_player` + `chewie` |
| Image Handling | `image_picker`, `image_cropper`, `cached_network_image` |
| Networking | `dio` (with interceptors for auth token + error mapping) |
| Local Persistence | `get_storage` (GetX-native) for lightweight local cache/session data |

**Explicitly not used on-device:** any LLM runtime, any GGUF/ONNX bundled model. All AI inference is 100% backend/API — see `prd.md` §7.

---

## 2. Folder Structure (Clean Architecture + GetX)

```
lib/
├── main.dart
├── app/
│   ├── app.dart                        # GetMaterialApp root
│   ├── bindings/
│   │   └── initial_binding.dart        # Global dependency injection
│   └── routes/
│       ├── app_pages.dart              # GetPage route table
│       └── app_routes.dart             # Route name constants
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   ├── app_spacing.dart
│   │   └── app_strings.dart
│   ├── theme/
│   │   └── app_theme.dart
│   ├── network/
│   │   ├── api_client.dart             # Dio instance + interceptors
│   │   ├── api_endpoints.dart
│   │   └── network_exceptions.dart
│   ├── error/
│   │   ├── failure.dart                # Sealed failure types
│   │   └── error_handler.dart          # Central error → UI message mapper
│   ├── utils/
│   │   ├── validators.dart
│   │   ├── logger.dart                 # Wraps all logging — no print()
│   │   └── image_compressor.dart
│   └── widgets/                        # Shared dumb widgets only
│       ├── app_button.dart
│       ├── app_loader.dart
│       ├── credit_badge.dart
│       └── error_state_widget.dart
│
├── data/
│   ├── models/
│   │   ├── job_model.dart              # Matches Firestore job schema exactly
│   │   ├── wallet_model.dart
│   │   └── user_model.dart
│   ├── repositories/
│   │   ├── job_repository.dart         # Impl — talks to API + Firestore
│   │   ├── wallet_repository.dart
│   │   └── auth_repository.dart
│   └── datasources/
│       ├── firestore_datasource.dart
│       └── job_api_datasource.dart     # POST /v1/generateJob wrapper
│
├── domain/
│   ├── entities/                       # Pure Dart, no Firestore/Dio types
│   │   ├── job_entity.dart
│   │   └── wallet_entity.dart
│   ├── repositories/                   # Abstract contracts
│   │   ├── i_job_repository.dart
│   │   └── i_wallet_repository.dart
│   └── usecases/
│       ├── submit_job_usecase.dart
│       ├── watch_job_status_usecase.dart
│       └── watch_wallet_usecase.dart
│
└── features/
    ├── auth/
    │   ├── bindings/auth_binding.dart
    │   ├── controllers/auth_controller.dart
    │   └── views/
    │       ├── login_view.dart
    │       └── splash_view.dart
    │
    ├── home_shell/
    │   ├── bindings/shell_binding.dart
    │   ├── controllers/shell_controller.dart
    │   └── views/home_shell_view.dart   # Bottom nav + persistent credit header
    │
    ├── wallet/
    │   ├── bindings/wallet_binding.dart
    │   ├── controllers/wallet_controller.dart
    │   └── views/wallet_debug_view.dart # Dev/debug credit modal
    │
    ├── image_to_3d/
    │   ├── bindings/
    │   ├── controllers/
    │   │   └── image_to_3d_controller.dart
    │   └── views/
    │       ├── image_to_3d_upload_view.dart
    │       └── model_viewer_view.dart   # Interactive .glb/.usdz viewer
    │
    ├── theme_change/
    │   ├── bindings/
    │   ├── controllers/theme_change_controller.dart
    │   └── views/
    │       ├── theme_preset_picker_view.dart
    │       └── theme_result_view.dart
    │
    ├── background_change/
    │   ├── bindings/
    │   ├── controllers/background_change_controller.dart
    │   └── views/
    │       ├── background_upload_view.dart
    │       └── background_result_view.dart
    │
    ├── video_gen/
    │   ├── bindings/
    │   ├── controllers/video_gen_controller.dart
    │   └── views/
    │       ├── video_script_input_view.dart
    │       └── video_player_view.dart
    │
    └── job_history/
        ├── bindings/
        ├── controllers/job_history_controller.dart
        └── views/job_history_view.dart  # Gallery-style grid, editing-app look
```

**Layer rule:** `features/` depends on `domain/`, `domain/` depends on nothing (pure Dart), `data/` implements `domain/` contracts. `core/` is shared utilities only — never feature-specific logic.

---

## 3. GetX Usage Rules

- **Controllers:** one per feature/view, extends `GetxController`. All mutable UI state is `.obs` (Rx types) — `RxBool`, `RxString`, `Rxn<T>`, `RxList<T>`.
- **No `setState` anywhere a controller exists.** If a widget needs local-only ephemeral state with zero business logic (e.g., a text field's obscure-password toggle with no side effects), a `StatefulWidget` is permissible **only** for that narrow case — document why in a code comment.
- **Dependency injection:** via `Bindings` (`InitialBinding` for app-wide singletons like `AuthController`, `WalletController`; feature `Bindings` for scoped controllers).
- **Lifecycle discipline:**
  - Every `StreamSubscription` (Firestore listeners) must be cancelled in `onClose()`.
  - Every `AnimationController` must be disposed in `onClose()`.
  - Use `Get.lazyPut()` for feature controllers (not `Get.put()` at app root) so they're disposed when the route is popped — prevents memory leaks from orphaned controllers.
- **Navigation:** `Get.toNamed()` / `Get.offNamed()` only — no `Navigator.push` directly, to keep routing centralized and testable.
- **Reactive UI:** `Obx(() => ...)` or `GetX<Controller>(builder: ...)` — wrap the smallest possible widget subtree, never wrap an entire screen in one `Obx` (causes unnecessary full-tree rebuilds → UI jank).

---

## 4. Firestore Job Schema (Contract — Do Not Modify Without Backend Sign-off)

```json
{
  "jobId": "job_998877",
  "userId": "usr_12345",
  "type": "IMAGE_GEN",
  "tier": "FAST",
  "status": "pending",
  "cost": 3,
  "params": {
    "userPrompt": "Cyberpunk city with neon rain",
    "themeId": null
  },
  "outputUrl": null,
  "error": null,
  "createdAt": "2026-08-10T11:37:19Z"
}
```

**Flutter's contract:**
- **Creates** the job document (via `POST /v1/generateJob`) and **listens** to `jobs/{jobId}` for status changes.
- **Never writes** `status`, `outputUrl`, or `error` directly — those are backend-owned fields.
- Status state machine to render in UI: `idle → deducting_credits → queued → processing → completed / error`

---

## 5. Wallet Schema

```
wallets/{userId}
{
  "balance": 100
}
```

- Read via reactive Firestore stream in `WalletController` — balance badge in the persistent header must update live, no polling.
- Never mutate `balance` from the client. All deduction happens via backend transactional function.

---

## 6. API Contract

```
POST /v1/generateJob
Body: { jobType, tier, params }
Response: { jobId }
```

All job submission goes through this single endpoint — Flutter does not call model-specific endpoints directly.

---

## 7. Error Handling Architecture

- All repository methods return a `Result<Failure, T>` (or equivalent sealed-class pattern) — **never throw raw exceptions up to the UI layer**.
- `core/error/failure.dart` defines sealed failure types: `NetworkFailure`, `InsufficientCreditsFailure`, `JobFailedFailure`, `AuthFailure`, `UnknownFailure`.
- `core/error/error_handler.dart` maps each `Failure` → a user-facing message string. UI widgets only ever render mapped messages, never raw error objects.
- Every async call in a controller is wrapped in try/catch at the repository boundary — controllers consume `Result`, they don't catch raw exceptions themselves.

---

## 8. Performance & Memory Rules

- Image previews use `cached_network_image` with defined `memCacheWidth`/`memCacheHeight` — never load full-resolution images into memory for thumbnail grids.
- Job history grid uses `GridView.builder` (lazy) — never `GridView.count` with a pre-built list for potentially large histories.
- All Firestore listeners are scoped to the current screen/controller lifecycle — no app-wide listeners left running after navigating away.
- 3D viewer and video player controllers are disposed on `onClose()` — verify via DevTools memory profiler before merging any PR touching these views.

---

## 9. Naming Conventions

- Files: `snake_case.dart`
- Classes: `PascalCase`
- Controllers: `{Feature}Controller` (e.g., `ImageTo3dController`)
- Bindings: `{Feature}Binding`
- Rx variables: prefix not required, but must be typed explicitly (`RxBool isLoading = false.obs;`, never `var`)
- Routes: constants in `app_routes.dart`, referenced as `Routes.imageTo3d`, never hardcoded strings
