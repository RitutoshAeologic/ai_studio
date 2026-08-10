# phases.md — Execution Roadmap

## AI Studio — Flutter Client, Phase 1 (Fast Tier)

> Task ownership follows the agreed Team Work Breakdown Structure. Flutter Dev #1 owns Auth/Shell/Wallet/State. Flutter Dev #2 owns Editor Canvas/Media/3D Viewer. Both depend on the Shared Contracts (Firestore schema + API payload) — do not diverge from `architecture.md` §4 and §6 without backend sign-off.

---

## Phase 0 — Project Setup

- [ ] Initialize Flutter project, configure `analysis_options.yaml` with strict lint rules
- [ ] Add core dependencies: `get`, `get_storage`, `dio`, `cached_network_image`, `image_picker`, `image_cropper`, `video_player`, `chewie`, 3D viewer package (`o3d` or `flutter_scene`)
- [ ] Set up folder structure exactly as defined in `architecture.md` §2
- [ ] Configure `core/theme/app_theme.dart` using tokens from `ui_ux.md`
- [ ] Set up Firebase project config (client-side only — Auth, Firestore, Storage SDKs)
- [ ] Set up `InitialBinding` with app-wide singleton controllers stubbed (empty shells)
- [ ] Confirm CI lint/format check passes on empty scaffold

---

## Phase 1 — Auth, Shell & Wallet (Flutter Dev #1)

**Depends on:** Backend Task B1 (Firestore wallet auto-provisioning) being available or mocked.

- [ ] `AuthController` — Firebase Auth integration (Google, Apple, Anonymous sign-in)
- [ ] `SplashView` → routes to `LoginView` or `HomeShellView` based on auth state
- [ ] `LoginView` — matches `ui_ux.md` visual direction, all three sign-in methods
- [ ] `HomeShellView` — bottom navigation shell + persistent header with credit badge
- [ ] `WalletController` — reactive Firestore stream on `wallets/{userId}`, exposes `balance` as `RxInt`
- [ ] Credit badge widget — animated on balance change, per `ui_ux.md` §5
- [ ] `WalletDebugView` — dev-only modal to inspect current balance/transactions (behind a debug flag, not shipped to production build)
- [ ] Verify: no memory leak on repeated login/logout cycles (check listener disposal)
- [ ] Verify: `setState` audit — zero instances where GetX should apply

**Exit criteria:** User can sign in, see live credit balance update in header, navigate the empty-state shell.

---

## Phase 2 — Job Submission & Status State Machine (Flutter Dev #1)

**Depends on:** Backend Task B4 (`POST /v1/generateJob` endpoint) available or mocked with a stub server.

- [ ] `JobModel` / `JobEntity` matching the exact Firestore schema in `architecture.md` §4
- [ ] `JobRepository` — implements job submission (API call) + job status watching (Firestore listener), returns `Result<Failure, T>`
- [ ] `SubmitJobUseCase`, `WatchJobStatusUseCase`
- [ ] Generic job state machine UI components: queued / processing / completed / error states (per `ui_ux.md` §5) — built as reusable widgets other features will consume
- [ ] Error mapping verified for: insufficient credits, network failure, malformed response, job failure from backend
- [ ] Verify: Firestore listener correctly disposed when leaving a job's detail screen mid-processing

**Exit criteria:** A stubbed job (any type) can be submitted, and its full state machine (queued → processing → completed/error) renders correctly and updates in real time.

---

## Phase 3 — Preset Library & Media Input (Flutter Dev #2)

- [ ] `ThemePresetPickerView` — chip-based preset selector (per `ui_ux.md` §5), fetches static preset templates
- [ ] Image picker + crop + compression utility (`core/utils/image_compressor.dart`)
- [ ] Direct-to-Cloud-Storage upload flow for source images
- [ ] Upload progress UI — no blocking spinner-only state, show real progress where possible
- [ ] Verify: large image upload does not block UI thread (compression/upload run without janking scroll/animations)

**Exit criteria:** User can pick/crop/compress an image and see it uploaded with progress feedback.

---

## Phase 4 — Feature: Background Change (Flutter Dev #2)

- [ ] `BackgroundChangeController` + `BackgroundUploadView`
- [ ] Submits job with `type: BACKGROUND_CHANGE`, `tier: FAST`, cost `3`
- [ ] `BackgroundResultView` — displays result, download + share actions
- [ ] Empty/error/loading states per `ui_ux.md` §7
- [ ] Full error handling per `rules.md` §3

**Exit criteria:** End-to-end background change flow works against real or staged backend.

---

## Phase 5 — Feature: Theme Change (Flutter Dev #2)

- [ ] `ThemeChangeController` + reuses `ThemePresetPickerView` from Phase 3
- [ ] Submits job with `type: IMAGE_GEN`, `tier: FAST`, `params.themeId`, cost `3`
- [ ] `ThemeResultView` — result display, download + share
- [ ] Full error handling + empty/loading states

**Exit criteria:** End-to-end theme change flow works against real or staged backend.

---

## Phase 6 — Feature: Image → 3D (Flutter Dev #2)

- [ ] `ImageTo3dController` + `ImageTo3dUploadView`
- [ ] Submits job with `type: IMAGE_TO_3D`, `tier: FAST`, cost `5`
- [ ] Integrate 3D viewer package — orbit/pinch-zoom/pan/reset controls per `ui_ux.md` §5
- [ ] Download + local caching of `.glb` (Android) / `.usdz` (iOS) assets
- [ ] Loading state: shimmer/skeleton placeholder, not a plain spinner
- [ ] Verify: 3D viewer controller disposed correctly on screen exit — check for GPU/memory leak via profiler

**Exit criteria:** End-to-end 3D generation flow works, result is interactively viewable, correctly disposed on exit.

---

## Phase 7 — Feature: 10-Second Video (Flutter Dev #2 + Flutter Dev #1 collab)

- [ ] `VideoGenController` + `VideoScriptInputView` (script/prompt text input)
- [ ] Submits job with `type: VIDEO_GEN`, `tier: FAST`, cost `40`
- [ ] Longer async wait handling — ensure job status UI clearly communicates expected wait time (20–40 sec range)
- [ ] `VideoPlayerView` — custom-skinned playback controls per `ui_ux.md` §5
- [ ] Full error handling + empty/loading states
- [ ] Verify: video player controller disposed correctly, no leaked native video resources

**Exit criteria:** End-to-end video generation flow works, playback is smooth, no resource leaks.

---

## Phase 8 — Job History / Gallery

- [ ] `JobHistoryController` + `JobHistoryView` — `GridView.builder`, editing-app-style gallery
- [ ] Status badges per job card (processing/completed/failed) per `ui_ux.md` §5
- [ ] Tap-through to appropriate result view based on job type
- [ ] Empty state for no history
- [ ] Verify: grid scroll performance with large history (test with 100+ mock jobs) — no jank

**Exit criteria:** Full gallery of past jobs, smooth scroll, correct navigation per job type.

---

## Phase 9 — Cross-Cutting Polish & Hardening

- [ ] Full `setState` audit across entire codebase — zero violations
- [ ] Full memory leak audit — DevTools profiler pass on every screen (navigate in/out repeatedly, confirm no growth)
- [ ] Full error-state audit — trigger every `Failure` type manually, confirm correct user-facing message per `rules.md` §3
- [ ] Design QA pass against `ui_ux.md` — confirm no ad-hoc colors/spacing/fonts anywhere
- [ ] Accessibility pass — tap targets, contrast, `Semantics` labels, font scaling
- [ ] Performance pass — confirm 60fps on a mid-range test device across all core flows
- [ ] Platform-specific QA — 3D viewer on both iOS (AR Quick Look/.usdz) and Android (.glb), per platform notes in the feasibility doc

**Exit criteria:** App is demo-ready — no known jank, leaks, unhandled errors, or design inconsistencies.

---

## Out of Scope for This Roadmap (Do Not Build)

- In-app purchase / credit top-up UI (tracked separately)
- Any Pro-tier feature or UI toggle
- Any on-device LLM/model bundling
