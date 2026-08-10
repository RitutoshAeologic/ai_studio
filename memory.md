# memory.md — Project Memory & Architecture Log

This document records essential architectural decisions, system configurations, design tokens, dependency constraints, and non-negotiable coding rules established for **AI Studio**.

---

## 1. Environment & Project Metadata

| Key | Value / Details |
|---|---|
| **App Name** | `AI Studio` |
| **Android Package Name** | `com.aistudio.mobile` |
| **Firebase Project** | `ai-studio-637ab` (Project # `799730875496`) |
| **Android Build Specs** | `compileSdk 36`, `targetSdk 35`, `minSdk 21` |
| **Android Gradle Overrides** | Top-level `android/build.gradle.kts` uses `afterEvaluate` / `plugins.withId` to force all plugin subprojects to `compileSdkVersion(36)`. |

---

## 2. Dependency Constraints & Versions

| Package | Version | Purpose |
|---|---|---|
| `get` | `^4.7.3` | State management, reactive controllers, GetPage routing, DI |
| `get_storage` | `^2.1.1` | GetX-native local session & cache storage |
| `flutter_screenutil_plus` | `^1.5.0` | Viewport-adaptive scaling (`.w`, `.h`, `.sp`, `.r`) |
| `dio` | `^5.8.0` | HTTP client with auth interceptors & error mapping |
| `firebase_core` | `^4.12.1` | Core Firebase SDK |
| `firebase_auth` | `^6.2.1` | Authentication (Email/Password + Firestore profile) |
| `cloud_firestore` | `^6.1.1` | Real-time database (`users/{uid}` and `wallets/{uid}`) |
| `firebase_storage` | `^13.1.1` | Cloud file storage for generated assets |
| `cached_network_image` | `^3.4.1` | Efficient image caching with memory limits |
| `image_picker` | `^1.1.4` | Media file selection |
| `image_cropper` | `^9.0.1` | Image cropping utility |
| `video_player` | `^2.10.1` | Native video playback |
| `chewie` | `^1.9.1` | Video player UI controller |
| `o3d` | `^3.1.3` | Interactive 3D model viewer (`.glb` / `.usdz`) |

---

## 3. UI Design System & Theme Tokens

- **Theme Mode**: **Sleek Modern Light Mode** (`AppTheme.lightTheme`).
- **Color Palette (`AppColors`)**:
  - `bgApp` / `bgPrimary`: `#F8F9FE` (Soft clean off-white background).
  - `surfaceCard` / `surfacePanel`: `#FFFFFF` (Pure white crisp container surfaces).
  - `surfaceInput`: `#F3F5FA` (Soft light grey text input container background).
  - `textPrimary`: `#1E1E2E` (Deep charcoal primary text for ultra-high contrast).
  - `textMuted`: `#6C728F` (Subtle balanced mid-grey for secondary/meta text).
  - `primaryAction`: `#6C5CE7` → `#A64CE7` (Vibrant indigo-to-violet linear gradient).
  - `creditGoldBg` / `creditGoldIcon`: `#FFFBEB` background, `#FDE68A` border, `#D97706` bolt icon, `#B45309` title text for 100 Free Credits badge.
- **Viewport Responsiveness (`flutter_screenutil_plus`)**:
  - Initialized with `designSize: Size(390, 844)` in `lib/app/app.dart`.
  - All typography uses `.sp`, heights `.h`, widths `.w`, radii `.r`.
- **Top Navigation Headers**:
  - Integrated navigation bars on all screens.
  - Sign Up page features a styled pill `Back` button (icon + text label).

---

## 4. Non-Negotiable Coding Standards & Rules

1. **Zero Hardcoded Constants Rule**:
   - ALL user-facing static strings MUST come from `AppStrings` (`lib/core/constants/app_strings.dart`).
   - ALL UI colors MUST come from `AppColors` (`lib/core/constants/app_colors.dart`).
   - ALL layout paddings/margins MUST use `AppSpacing` (`lib/core/constants/app_spacing.dart`).
   - ALL text styles MUST use `AppTextStyles` (`lib/core/constants/app_text_styles.dart`).
   - Inline raw strings, hardcoded `Color()` hex values, or raw magic numbers for paddings in views are strictly forbidden.

2. **Clean Architecture Layering**:
   - **Domain Layer** (`lib/domain/`): Pure Dart, no Flutter UI or Firebase SDK imports. Features `UserEntity`, `AuthRepository`, `StorageRepository` abstract interfaces, and `Result<S, F>` functional wrappers.
   - **Data Layer** (`lib/data/`): `UserModel` (with `fromFirebaseUser`, `fromFirestore`, `toFirestore`), `AuthRepositoryImpl` (with 4-second timeouts & fallback handling), and `StorageRepositoryImpl` connecting `FirebaseStorage`.
   - **Core Layer** (`lib/core/`): Centralized `ErrorHandler`, `Failure` sealed hierarchy, `Logger` (no raw `print()`), and shared widgets (`AppButton`, `AppTextField`).
   - **Presentation Layer** (`lib/features/`): Features `AuthController` (with guaranteed `finally` loading state reset), scoped `AuthBinding`, `LoginView`, and `SignupView`.

3. **Input Field Error Layout Discipline**:
   - `AppTextField` renders error text **OUTSIDE & BELOW** the container box with an error icon, suppressing default `InputDecoration` inline error strings to prevent box overflow and text overlap.

4. **Real-Time Reactive Form Validation**:
   - Real-time field validation is managed reactively via `AuthController` observables (`loginEmailError`, `loginPasswordError`, `signupNameError`, `signupEmailError`, `signupPasswordError`, `signupConfirmPasswordError`).

5. **Frontend Image Validation Pipeline (`ImageValidator`)**:
   - Executes before uploading to Firebase Storage/GPU pipelines. Runs pixel matrix analysis in a background Isolate (`compute(...)`).
   - Checks: File format, file size (512B–20MB), resolution (256x256–4096x4096), corruption, blank/white/black screens, contrast/detail score, Laplacian blur variance, and feature-dependent subject detection (`AiFeatureTarget`).

6. **ScreenUtil Responsive Scaling & Zero Hardcoded Constants**:
   - Every font size uses `.sp` scaling (`AppTextStyles.displayXL`, `headingM`, `bodyL`, `caption`).
   - Every dimension, padding, border radius, and icon size uses `.w`, `.h`, `.r` extensions.
   - 100% of user-facing strings are defined in `AppStrings` (`lib/core/constants/app_strings.dart`). Zero raw inline strings exist in views or widgets.
   - All colors are mapped to `AppColors` tokens.
