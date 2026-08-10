# rules.md — Coding Standards & Enterprise Rules

## AI Studio — Flutter Development Rules (Non-Negotiable)

> These rules apply to every file, every PR, every AI-assisted code generation. If a generated suggestion violates any rule below, it must be rejected or corrected before merge.

---

## 1. State Management

- **GetX only.** No `Provider`, `Bloc`, `Riverpod`, or mixed state management patterns anywhere in the codebase.
- **`setState` is forbidden** in any widget where a `GetxController` is available or should be available. The only narrow exception: a `StatefulWidget` for purely ephemeral, zero-business-logic local UI state (e.g., a `TextField`'s obscure toggle) — must be commented with `// setState justified: <reason>` or it fails review.
- All observable state must be explicitly typed Rx (`RxBool`, `RxString`, `RxInt`, `Rxn<T>`, `RxList<T>`) — never `dynamic` or untyped `var` for reactive state.
- Wrap the **smallest possible widget** in `Obx`/`GetX` — never wrap a full screen body in a single `Obx` unless the entire screen genuinely depends on one observable.

---

## 2. Architecture Rules

- Strict adherence to the layer structure in `architecture.md`. `domain/` must never import from `data/` or `features/`.
- Every feature has its own `Binding` — controllers are provided via `Get.lazyPut()`, never instantiated inline in a widget (`Get.put()` inside `build()` is forbidden — causes recreation on every rebuild).
- Repositories return a `Result<Failure, T>` pattern — no repository method may throw an uncaught exception to the controller layer.
- No business logic in widgets. Widgets read from controllers and call controller methods — they do not contain calculation, formatting logic beyond trivial display formatting, or direct API/Firestore calls.

---

## 3. Error Handling — Mandatory Pattern

```dart
// ✅ Correct pattern
Future<void> submitJob() async {
  isLoading.value = true;
  final result = await _jobRepository.submitJob(params);
  result.fold(
    (failure) => errorMessage.value = ErrorHandler.map(failure),
    (job) => currentJob.value = job,
  );
  isLoading.value = false;
}
```

- **Never** use a bare `catch (e) {}` that swallows the error silently.
- **Never** show `e.toString()` directly to the user — always pass through `ErrorHandler.map()` (see `architecture.md` §7).
- Every network call must handle: timeout, no connection, 4xx, 5xx, and malformed response — each maps to a distinct `Failure` type, not a generic catch-all.
- Log every caught error via `core/utils/logger.dart` — never `print()`. Logger must be no-op or minimal in release builds.

---

## 4. Memory & Performance Rules

- Every `StreamSubscription` must be cancelled in `onClose()`. No exceptions.
- Every `AnimationController`, `TextEditingController`, `ScrollController` created in a controller must be disposed in `onClose()`.
- No Firestore listener may outlive its owning controller — verify listeners stop firing after navigating away from a screen (check via debug logs or DevTools during development).
- Image loading must always specify `cacheWidth`/`cacheHeight` or use `cached_network_image` with `memCacheWidth`/`memCacheHeight` set — never load a full-resolution image just to display a thumbnail.
- Long lists (job history, gallery) must use `.builder` constructors — never eagerly build full lists.
- No `Future.delayed` used as a substitute for proper async/state-driven logic (e.g., don't fake a loading state with a timer — drive it from actual job status).

---

## 5. Code Style

- Files: `snake_case.dart`. Classes: `PascalCase`. Constants: `camelCase` (or `SCREAMING_CASE` only for true global constants in `app_strings.dart`/`app_colors.dart`).
- No inline magic numbers/strings for colors, spacing, or repeated text — always reference `core/constants/`.
- No `// TODO` left in code merged to main — either resolved or tracked in `phases.md` / an issue tracker.
- No commented-out dead code blocks — delete it, git history preserves it.
- Prefer `const` constructors everywhere possible — flag any widget that could be `const` but isn't.
- Null safety is strict — no `!` (bang operator) without a preceding explicit null check or a code comment justifying why it's provably safe at that point.

---

## 6. Naming & File Conventions

- One public class per file, filename matches class name in `snake_case`.
- Controllers: `{feature}_controller.dart` → class `{Feature}Controller`.
- No abbreviated/ambiguous names (`ctrl`, `mgr`, `tmp`) in any committed code — full descriptive names only.
- Route names centralized in `app_routes.dart` — no hardcoded route strings anywhere else in the codebase.

---

## 7. API & Data Contract Discipline

- Flutter never writes `status`, `outputUrl`, or `error` fields on a job document — those are backend-owned (see `architecture.md` §4). Any code attempting to write these fields from the client fails review immediately.
- All API calls go through `core/network/api_client.dart` (single `Dio` instance with interceptors) — no ad-hoc `Dio()` or `http.get()` calls scattered in feature code.
- Any change to the Firestore job schema or API contract requires explicit backend team sign-off before implementation — do not unilaterally add/rename fields.

---

## 8. Security Rules

- No API keys, tokens, or secrets hardcoded in Flutter client code — ever. This includes Hugging Face tokens, any backend service keys, etc. Client only holds Firebase client config (which is safe to expose) and calls backend endpoints for everything else.
- No sensitive user data logged, even in debug builds.

---

## 9. Testing Expectations

- Every `UseCase` and `Repository` implementation needs at minimum a happy-path and a failure-path unit test.
- Controllers handling job submission/status must have tests covering: successful submission, insufficient credits, network failure, malformed backend response.
- Widget tests required for: empty states, error states, and loading states of each core feature screen.

---

## 10. PR / Review Checklist (Every PR Must Confirm)

- [ ] No `setState` used where GetX applies
- [ ] All controllers use `Get.lazyPut()`, disposed correctly (`onClose()` implemented)
- [ ] No raw exceptions surfaced to UI — all errors go through `ErrorHandler`
- [ ] No hardcoded colors/spacing/strings — all from `core/constants/`
- [ ] No memory leaks — subscriptions/controllers verified disposed
- [ ] No business logic inside widgets
- [ ] Matches `ui_ux.md` design tokens exactly (no ad-hoc colors/spacing)
- [ ] No secrets/keys present in client code
