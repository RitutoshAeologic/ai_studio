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

- **Theme Mode**: **Darkroom Dark Mode** (`AppTheme.darkTheme` / `ThemeMode.dark`) per revision `cf6dff878693f1759a868d5c4231771b2b14e3a9`.
- **Color Palette (`AppColors`)**:
  - `ink`: `Color(0xFF111318)` (Base app background — deepest layer).
  - `surface`: `Color(0xFF1B1E26)` (Cards, sheets, elevated surface).
  - `surfaceInput`: `Color(0xFF23262F)` (Input field backgrounds).
  - `borderSubtle`: `Color(0xFF2A2D38)` / `borderFocus`: `Color(0xFFFF7A45)`.
  - `bone`: `Color(0xFFF3F1EA)` (Primary high-contrast text on dark surfaces).
  - `slate`: `Color(0xFF8A93A6)` (Secondary text & inactive icons).
  - `textDisabled`: `Color(0xFF4A4E5A)` (Disabled text).
  - `ember`: `Color(0xFFFF7A45)` (Primary accent / CTA / credit badge / progress fills).
  - `emberSoft`: `Color(0x1FFF7A45)` (Subtle 12% opacity background tint).
  - `emberPressed`: `Color(0xFFE0622E)` (CTA pressed state).
  - `signalViolet`: `Color(0xFF6E56CF)` (Reserved exclusively for 3D/MESH screens).
  - `statusSuccess`: `Color(0xFF2DD58C)`, `statusWarning`: `Color(0xFFFACC15)`, `statusError`: `Color(0xFFFF4757)`.
  - `emberGradient`: `LinearGradient(colors: [Color(0xFFFF7A45), Color(0xFFFF5722)])`.
  - `meshGradient`: `LinearGradient(colors: [Color(0xFF6E56CF), Color(0xFF4A35A8)])`.
- **Typography Pairing (`AppTextStyles`)**:
  - **Space Grotesk** (`GoogleFonts.spaceGrotesk`): Display & Headings (`displayLarge`, `displayMedium`, `headingLarge`, `headingMedium`, `headingSmall`).
  - **Inter** (`GoogleFonts.inter`): Body & UI text (`bodyLarge`, `bodyMedium`, `bodySmall`, `labelLarge`, `labelMedium`, `buttonLabel`).
  - **JetBrains Mono** (`GoogleFonts.jetBrainsMono`): Data & Readouts (`creditCounter`, `jobStatus`, `jobId`, `dataLabel`).
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
   - **`AppTextStyles` Parameter Factory Pattern**: Typography styles use direct parameter functions (`AppTextStyles.bodyMedium(color: AppColors.textMuted)`, `AppTextStyles.caption(color: AppColors.errorIndicator)`) rather than `.copyWith(...)` to avoid double-allocation overhead per rebuild frame.
