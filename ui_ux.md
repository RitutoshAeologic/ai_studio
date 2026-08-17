# ui_ux.md — Design System & Guidelines

## AI-Studio App — Visual Identity, Geometry & Interaction Standards

> Reference design draft resolution: **1440×900** (desktop baseline). All `ScreenUtil` values in this document assume `ScreenUtil.init(designSize: Size(1440, 900))` configured in `main.dart`.

---

## 1. VISUAL VIBE & AESTHETIC

### Direction: "Cyberpunk / Minimalist Slate"

AI-Studio's visual identity is a **dark-mode premium interface** built on a foundation of near-black slate surfaces, sharp geometric structure, and restrained neon-violet accent glows used only at points of AI activity or user action.

**Why this fits an AI image/3D editor:**

- **Dark surfaces make generated media the hero.** Photos, theme-swapped renders, and 3D meshes are visually loud — busy backgrounds or light-mode chrome compete with the actual output. A near-black slate canvas lets every generated asset read with maximum contrast and color fidelity, exactly like professional grading/editing tools (DaVinci Resolve, Lightroom Dark, Blender).
- **"Cyberpunk" accent glows signal "AI is working here."** A soft violet/magenta glow isn't decorative — it's a functional language: glowing border = active AI control, glowing button = generation in progress, pulsing glow = processing. Users learn this vocabulary in seconds.
- **"Minimalist Slate" keeps the chrome quiet.** Outside of the accent glow moments, every panel, card, and control uses flat, low-contrast slate tones with hairline borders — never competing for attention against the canvas. This is what separates a *premium* AI tool from a *toy* AI app: restraint everywhere except the moment of interaction.
- **Sharp geometry over soft skeuomorphism.** Minimal corner radii on structural containers (panels, toolbars), slightly higher radii on interactive elements (buttons, chips, cards) — reinforces a precise, technical, "studio" feeling rather than a playful consumer-app feeling.

**One-line brief for any AI tool generating UI code from this file:**
> Near-black slate background, flat low-contrast panels with hairline borders, violet-to-magenta gradient glow reserved exclusively for active/AI-processing states, sharp structural corners, soft rounded interactive corners.

---

## 2. COLOR PALETTE TOKENS

All colors defined as both hex reference and exact Flutter `Color(0xFF...)` constructors. `AA` alpha-channel variants included where translucency is required (glows, overlays, disabled states).

| Token | Hex | Flutter Constructor | Usage |
|---|---|---|---|
| `bgApp` | `#0B0B10` | `Color(0xFF0B0B10)` | App root background |
| `bgCanvas` | `#08080C` | `Color(0xFF08080C)` | Central viewport canvas (Column B) — slightly darker than app bg to recede behind media |
| `surfaceCard` | `#15151D` | `Color(0xFF15151D)` | Cards, preset tiles, list rows |
| `surfacePanel` | `#121218` | `Color(0xFF121218)` | Toolbar (Column A) and Control Panel (Column C) backgrounds |
| `surfaceElevated` | `#1C1C26` | `Color(0xFF1C1C26)` | Modals, dropdowns, dialogs, popovers |
| `surfaceInput` | `#191922` | `Color(0xFF191922)` | Text fields, dropdown inputs, sliders track background |
| `primaryAction` | `#7B5CFA` | `Color(0xFF7B5CFA)` | Primary AI action buttons, active tab indicators |
| `primaryActionHover` | `#8F73FF` | `Color(0xFF8F73FF)` | Primary button hover state |
| `primaryActionPressed` | `#6947E0` | `Color(0xFF6947E0)` | Primary button pressed state |
| `accentGlowStart` | `#7B5CFA` | `Color(0xFF7B5CFA)` | Gradient glow — start (violet) |
| `accentGlowEnd` | `#E24CE0` | `Color(0xFFE24CE0)` | Gradient glow — end (magenta) |
| `accentGlowSoft` | `#7B5CFA33` | `Color(0x337B5CFA)` | 20% alpha glow — ambient border/shadow glow, non-interactive |
| `successIndicator` | `#33D189` | `Color(0xFF33D189)` | Completed job, success toast, "generation complete" badge |
| `successIndicatorSoft` | `#33D18926` | `Color(0x2633D189)` | Success background tint |
| `warningIndicator` | `#F5B84C` | `Color(0xFFF5B84C)` | Queued/processing badge |
| `errorIndicator` | `#FF5C6C` | `Color(0xFFFF5C6C)` | Failed job, destructive action, error border |
| `errorIndicatorSoft` | `#FF5C6C26` | `Color(0x26FF5C6C)` | Error background tint |
| `textPrimary` | `#F2F2F6` | `Color(0xFFF2F2F6)` | Primary text on all dark surfaces |
| `textMuted` | `#8B8B99` | `Color(0xFF8B8B99)` | Secondary/meta text, placeholder text, captions |
| `textDisabled` | `#4A4A55` | `Color(0xFF4A4A55)` | Disabled labels |
| `borderSubtle` | `#26262F` | `Color(0xFF26262F)` | Hairline borders on panels, cards, dividers |
| `borderFocus` | `#7B5CFA` | `Color(0xFF7B5CFA)` | Focused input border (solid, no glow) |

### Gradient Definition (reused across primary buttons + active glow states)

```dart
const LinearGradient aiActionGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF7B5CFA), // accentGlowStart
    Color(0xFFE24CE0), // accentGlowEnd
  ],
);
```

### Centralized Token File

```dart
// core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const bgApp = Color(0xFF0B0B10);
  static const bgCanvas = Color(0xFF08080C);
  static const surfaceCard = Color(0xFF15151D);
  static const surfacePanel = Color(0xFF121218);
  static const surfaceElevated = Color(0xFF1C1C26);
  static const surfaceInput = Color(0xFF191922);

  static const primaryAction = Color(0xFF7B5CFA);
  static const primaryActionHover = Color(0xFF8F73FF);
  static const primaryActionPressed = Color(0xFF6947E0);

  static const accentGlowStart = Color(0xFF7B5CFA);
  static const accentGlowEnd = Color(0xFFE24CE0);
  static const accentGlowSoft = Color(0x337B5CFA);

  static const successIndicator = Color(0xFF33D189);
  static const successIndicatorSoft = Color(0x2633D189);
  static const warningIndicator = Color(0xFFF5B84C);
  static const errorIndicator = Color(0xFFFF5C6C);
  static const errorIndicatorSoft = Color(0x26FF5C6C);

  static const textPrimary = Color(0xFFF2F2F6);
  static const textMuted = Color(0xFF8B8B99);
  static const textDisabled = Color(0xFF4A4A55);

  static const borderSubtle = Color(0xFF26262F);
  static const borderFocus = Color(0xFF7B5CFA);

  static const LinearGradient aiActionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentGlowStart, accentGlowEnd],
  );
}
```

---

## 3. SCREENUTIL GEOMETRY RULES

**Design draft size:** `1440 × 900` (desktop-first, since the primary experience is the 3-column desktop/web layout — mobile collapses from this baseline, it is not designed mobile-first).

```dart
// main.dart
ScreenUtilInit(
  designSize: const Size(1440, 900),
  minTextAdapt: true,
  splitScreenMode: true,
  builder: (context, child) => MaterialApp(
    // ...
  ),
);
```

### 3.1 Strict Usage Rules — When to Use Each Extension

| Extension | Use For | Never Use For |
|---|---|---|
| `.sp` | **Font sizes only.** Every `TextStyle.fontSize` in the app. | Padding, margins, icon sizes, container dimensions |
| `.h` | **Vertical dimensions** — heights, vertical padding/margin, `SizedBox(height:)`, row spacing. | Horizontal spacing, font size, radius |
| `.w` | **Horizontal dimensions** — widths, horizontal padding/margin, `SizedBox(width:)`, fixed column widths. | Vertical spacing, font size, radius |
| `.r` | **Radius and uniform/symmetric spacing** — `BorderRadius.circular(x.r)`, icon sizes, symmetric padding (`EdgeInsets.all(x.r)`), stroke widths. `.r` scales proportionally using the *shorter* screen dimension ratio, keeping circular/square elements visually proportional regardless of aspect ratio. | Directional-only spacing where width/height must diverge (use `.w`/`.h` explicitly instead) |

**Rule of thumb:**
> If it has direction (top/bottom vs left/right), use `.h`/`.w`. If it's symmetric or radial (radius, icon size, uniform padding), use `.r`. Font size is always `.sp`, without exception.

### 3.2 Practical Examples

```dart
// Correct
Container(
  width: 380.w,                              // Column C fixed width
  padding: EdgeInsets.symmetric(
    horizontal: 20.w,                        // horizontal -> .w
    vertical: 16.h,                          // vertical -> .h
  ),
  decoration: BoxDecoration(
    color: AppColors.surfacePanel,
    borderRadius: BorderRadius.circular(16.r), // radius -> .r
    border: Border.all(color: AppColors.borderSubtle, width: 1.r),
  ),
  child: Text(
    'AI Controls',
    style: TextStyle(fontSize: 16.sp, color: AppColors.textPrimary), // font -> .sp
  ),
);

// Incorrect — do not do this
Container(
  padding: EdgeInsets.all(20.h),   // wrong: symmetric padding should use .r
  child: Text('Label', style: TextStyle(fontSize: 16.w)), // wrong: font must use .sp
);
```

### 3.3 Typography Scale Hierarchy

All values below are the **unscaled `.sp` input** — ScreenUtil scales them at runtime relative to the 1440×900 draft.

| Style Token | Size (`.sp`) | Weight | Line Height | Usage |
|---|---|---|---|---|
| `displayXL` | `32.sp` | `700` | `1.2` | Studio/app title, empty-state hero text |
| `headingL` | `24.sp` | `700` | `1.25` | Screen/section titles ("Theme Swap", "3D Viewer") |
| `headingM` | `18.sp` | `600` | `1.3` | Panel section headers ("Presets", "Parameters") |
| `bodyL` | `15.sp` | `400` | `1.5` | Primary body text, control panel labels |
| `bodyM` | `13.sp` | `400` | `1.5` | Secondary text, helper text under inputs |
| `caption` | `11.sp` | `500` | `1.4` | Meta info, credit cost tags, timestamps |
| `buttonLabel` | `14.sp` | `600` | `1.0` | All button text |
| `mono` (params) | `12.sp` | `500` | `1.4` | Numeric parameter readouts (sliders, coordinates) — monospace font |

```dart
// core/constants/app_text_styles.dart
class AppTextStyles {
  AppTextStyles._();

  static TextStyle displayXL = TextStyle(
    fontSize: 32.sp, fontWeight: FontWeight.w700, height: 1.2,
    color: AppColors.textPrimary,
  );
  static TextStyle headingL = TextStyle(
    fontSize: 24.sp, fontWeight: FontWeight.w700, height: 1.25,
    color: AppColors.textPrimary,
  );
  static TextStyle headingM = TextStyle(
    fontSize: 18.sp, fontWeight: FontWeight.w600, height: 1.3,
    color: AppColors.textPrimary,
  );
  static TextStyle bodyL = TextStyle(
    fontSize: 15.sp, fontWeight: FontWeight.w400, height: 1.5,
    color: AppColors.textPrimary,
  );
  static TextStyle bodyM = TextStyle(
    fontSize: 13.sp, fontWeight: FontWeight.w400, height: 1.5,
    color: AppColors.textMuted,
  );
  static TextStyle caption = TextStyle(
    fontSize: 11.sp, fontWeight: FontWeight.w500, height: 1.4,
    color: AppColors.textMuted,
  );
  static TextStyle buttonLabel = TextStyle(
    fontSize: 14.sp, fontWeight: FontWeight.w600, height: 1.0,
    color: AppColors.textPrimary,
  );
  static TextStyle mono = TextStyle(
    fontSize: 12.sp, fontWeight: FontWeight.w500, height: 1.4,
    fontFamily: 'RobotoMono',
    color: AppColors.textPrimary,
  );
}
```

### 3.4 Spacing Scale (8pt-equivalent, expressed for `.h`/`.w`/`.r`)

```
spacingXs  = 4
spacingSm  = 8
spacingMd  = 16
spacingLg  = 24
spacingXl  = 32
spacingXxl = 48
```

Applied contextually: `4.r`, `8.r`, `16.w`, `24.h`, etc. — always via the rules in §3.1, never as bare `EdgeInsets` numbers.

---

## 4. 3-COLUMN RESPONSIVE LAYOUT MATRIX

### 4.1 Breakpoints

| Breakpoint | Range | Layout |
|---|---|---|
| Desktop/Web | `> 1024.w` | Full 3-column layout (A + B + C simultaneously visible) |
| Tablet | `600.w – 1024.w` | Column A collapses to icon-rail; Column C becomes a slide-over drawer triggered by a "Controls" FAB |
| Mobile | `< 600.w` | Column A collapses into a bottom sheet handle; Column B is full-screen; Column C becomes a bottom drawer/modal sheet triggered by a persistent "Adjust" button |

### 4.2 ASCII Wireframe — Desktop (`> 1024.w`)

```
+----+------------------------------------------------------+----------------------+
|    |  AI-Studio        [Theme Swap v]      (bell) (user)  |                      |
|    +------------------------------------------------------+                      |
| A  |                                                        |   AI CONTROL PANEL   |
|    |                                                        |   ------------------ |
|80w |                                                        |   Presets            |
|    |                                                        |   [th][th][th][th]  |
|home|                                                        |                      |
|img |              CENTRAL VIEWPORT CANVAS                   |   Custom Prompt      |
|hist|           (Before/After Slider OR o3d Viewer)          |   +----------------+ |
|clk |                                                        |   | Describe your  | |
|    |                                                        |   | style...       | |
|set |                                                        |   +----------------+ |
|    |                                                        |                      |
|    |                                                        |   Strength  o------- |
|    |                                                        |   0.75               |
|    |                                                        |                      |
|    |                                                        |  +------------------+|
|    |                                                        |  |  Generate (3 cr) ||
|    |                                                        |  +------------------+|
+----+------------------------------------------------------+----------------------+
  A=80.w              B = Expanded (flex: 1)                    C = 380.w
```

### 4.3 Column Specifications

**Column A — Slim Utility / History Toolbar**
```dart
SizedBox(
  width: 80.w,
  child: Container(
    color: AppColors.surfacePanel,
    child: Column(
      children: [
        SizedBox(height: 24.h),
        _ToolbarIcon(icon: Icons.home_rounded, isActive: true),
        SizedBox(height: 8.h),
        _ToolbarIcon(icon: Icons.image_rounded),
        SizedBox(height: 8.h),
        _ToolbarIcon(icon: Icons.history_rounded),
        const Spacer(),
        _ToolbarIcon(icon: Icons.settings_rounded),
        SizedBox(height: 24.h),
      ],
    ),
  ),
);
```
- Fixed width: `80.w`, full height, `surfacePanel` background, hairline right border (`borderSubtle`, `1.r`)
- Icon-only, no labels — vertically centered icon stack with active-state glow indicator (left-edge `3.w` accent bar in `primaryAction`)

**Column B — Central Interactive Viewport Canvas**
```dart
Expanded(
  flex: 1,
  child: Container(
    color: AppColors.bgCanvas,
    child: viewMode == ViewMode.image
        ? BeforeAfterSlider(before: sourceImage, after: resultImage)
        : O3DViewerWidget(   // o3d plugin integration point
            src: meshAssetUrl,
            ar: false,
            autoRotate: true,
            cameraControls: true,
          ),
  ),
);
```
- Takes all remaining horizontal space (`Expanded(flex: 1)`), no fixed width
- Background: `bgCanvas` (darker than surrounding panels, to recede)
- Two interchangeable content modes, switched by the active job's output type:
  - **Image mode:** Before/After comparison slider (draggable divider, `primaryAction` colored handle)
  - **3D mode:** `o3d` widget fills the canvas edge-to-edge, floating control pill (per §5) anchored bottom-center for orbit/reset/zoom

**Column C — AI Control Panel Drawer**
```dart
SizedBox(
  width: 380.w,
  child: Container(
    color: AppColors.surfacePanel,
    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
    child: ListView(
      children: [
        Text('Presets', style: AppTextStyles.headingM),
        SizedBox(height: 12.h),
        PresetCardGrid(),          // preset theme tiles
        SizedBox(height: 24.h),
        Text('Custom Prompt', style: AppTextStyles.headingM),
        SizedBox(height: 12.h),
        PromptInputField(),        // custom text prompt injection
        SizedBox(height: 24.h),
        ParameterSlider(label: 'Strength'),
        SizedBox(height: 32.h),
        GenerateActionButton(),
      ],
    ),
  ),
);
```
- Fixed width: `380.w`, full height, `surfacePanel` background, hairline left border
- Hosts: preset grid, custom prompt text injection field, parameter sliders/knobs, and the primary generate action button (always pinned visually at the bottom of the scrollable panel content)

### 4.4 Responsive Collapse Behavior

```dart
Widget buildLayout(BuildContext context) {
  if (1024.w < ScreenUtil().screenWidth) {
    return _DesktopThreeColumnLayout();
  } else if (600.w < ScreenUtil().screenWidth) {
    return _TabletCollapsedLayout();   // A -> icon rail, C -> slide-over drawer
  } else {
    return _MobileStackedLayout();     // A -> bottom sheet handle, C -> modal bottom sheet
  }
}
```

- **Tablet (`600.w–1024.w`):** Column A remains as a slim icon rail (unchanged), Column B expands to fill remaining space, Column C becomes a `showGeneralDialog` slide-over panel triggered by a floating "Controls" button (bottom-right, `primaryAction` gradient FAB).
- **Mobile (`< 600.w`):** Column A collapses entirely into a bottom navigation bar or a swipe-up handle. Column B becomes full-screen (the canvas is the entire visible app). Column C becomes a `showModalBottomSheet` (draggable, snap points at 40%/90% height) triggered by a persistent "Adjust" pill button floating above the bottom edge of the canvas.

---

## 5. STATE BEHAVIORS & MICRO-INTERACTIONS

### 5.1 Primary Buttons ("Generate", "Apply", "Export")

| State | Visual Treatment |
|---|---|
| **Default** | `aiActionGradient` fill, `borderRadius: 12.r`, no shadow |
| **Hover** (desktop/web) | Gradient brightens (`primaryActionHover` tint overlay at 10% opacity), cursor -> pointer, `120ms` ease-out transition |
| **Active/Pressed** | Scale to `0.97`, gradient darkens toward `primaryActionPressed`, `100ms` ease-out |
| **Disabled** | Flat `textDisabled` fill, no gradient, no shadow, `bodyM`-weight label in `textMuted`, cursor -> not-allowed |
| **AI Processing/Loading** | Gradient fill remains but animates — a slow left-to-right shimmer sweep across the gradient (`1.2s` loop), label replaced with a `16.r`-sized spinner + "Generating…" text, button width locked (no layout shift), button becomes non-interactive but visually distinct from Disabled (still shows the gradient, just animated, signaling "working" not "unavailable") |

```dart
AnimatedContainer(
  duration: const Duration(milliseconds: 120),
  height: 48.h,
  decoration: BoxDecoration(
    gradient: isProcessing
        ? _shimmerGradient(animationValue)
        : (isDisabled ? null : AppColors.aiActionGradient),
    color: isDisabled ? AppColors.textDisabled : null,
    borderRadius: BorderRadius.circular(12.r),
  ),
  child: Center(
    child: isProcessing
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16.r, height: 16.r,
                child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 8.w),
              Text('Generating…', style: AppTextStyles.buttonLabel),
            ],
          )
        : Text(label, style: AppTextStyles.buttonLabel),
  ),
);
```

### 5.2 Input Fields (Prompt Injection, Text Parameters)

| State | Visual Treatment |
|---|---|
| **Default** | `surfaceInput` fill, `1.r` border in `borderSubtle`, `borderRadius: 10.r`, placeholder text in `textMuted` |
| **Hover** | Border brightens to a lighter neutral (no color change yet — hover ≠ focus) |
| **Focused** | Border becomes solid `borderFocus` (`1.5.r` width) **plus** a soft outer glow (`accentGlowSoft`, `8.r` blur) — this is the one input state allowed to show the accent glow, signaling active AI-prompt entry |
| **Disabled** | `surfaceInput` at 50% opacity, `textDisabled` placeholder, border removed |
| **Error** | Border becomes `errorIndicator`, helper text below in `errorIndicator` at `caption` size |

```dart
Container(
  height: 44.h,
  padding: EdgeInsets.symmetric(horizontal: 14.w),
  decoration: BoxDecoration(
    color: AppColors.surfaceInput,
    borderRadius: BorderRadius.circular(10.r),
    border: Border.all(
      color: isFocused ? AppColors.borderFocus : AppColors.borderSubtle,
      width: isFocused ? 1.5.r : 1.r,
    ),
    boxShadow: isFocused
        ? [BoxShadow(color: AppColors.accentGlowSoft, blurRadius: 8.r, spreadRadius: 1.r)]
        : null,
  ),
  child: TextField(
    style: AppTextStyles.bodyL,
    decoration: InputDecoration(
      hintText: 'Describe your style…',
      hintStyle: AppTextStyles.bodyL.copyWith(color: AppColors.textMuted),
      border: InputBorder.none,
    ),
  ),
);
```

### 5.3 Theme/Preset Selection Cards

| State | Visual Treatment |
|---|---|
| **Default** | `surfaceCard` background, `1.r` `borderSubtle` border, `borderRadius: 14.r`, thumbnail image fills card, label overlay at bottom in `bodyM` |
| **Hover** | Card lifts — `scale(1.03)` + soft ambient shadow (`accentGlowSoft`, `16.r` blur), `150ms` ease-out |
| **Selected/Active** | `2.r`-width solid border using `aiActionGradient` (via `GradientBoxBorder` or a gradient-painted `CustomPainter` border), plus persistent soft outer glow (`accentGlowSoft`, `12.r` blur, no animation — steady state) |
| **Disabled** (e.g., preset unavailable at current tier) | 40% opacity overlay over thumbnail, `textDisabled` label, small lock icon top-right corner |
| **AI Processing** (this specific preset is being applied) | Border glow becomes animated/pulsing (`800ms` ease-in-out, opacity `0.4 -> 1.0 -> 0.4` loop) instead of static — same visual grammar as the button loading state, applied contextually to the active card |

```dart
AnimatedScale(
  scale: isHovered ? 1.03 : 1.0,
  duration: const Duration(milliseconds: 150),
  child: Container(
    width: 96.w,
    height: 96.h,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14.r),
      border: isSelected
          ? Border.all(color: AppColors.primaryAction, width: 2.r) // gradient border via painter in production
          : Border.all(color: AppColors.borderSubtle, width: 1.r),
      boxShadow: isSelected || isHovered
          ? [BoxShadow(color: AppColors.accentGlowSoft, blurRadius: isSelected ? 12.r : 16.r)]
          : null,
      image: DecorationImage(image: NetworkImage(presetThumbnailUrl), fit: BoxFit.cover),
    ),
    child: isProcessing
        ? _PulsingGlowOverlay()  // 800ms opacity loop per spec above
        : null,
  ),
);
```

### 5.4 3D Viewer (`o3d`) Loading & Interaction States

| State | Visual Treatment |
|---|---|
| **Mesh Loading** | Canvas shows a slowly rotating low-poly placeholder cube silhouette (outline only, `borderSubtle` stroke) centered in the canvas, with a `caption`-style "Loading mesh…" label beneath |
| **Loaded/Idle** | `o3d` widget active, floating control pill visible (bottom-center, `surfaceElevated` background at 85% opacity, `borderRadius: 24.r`) containing rotate/reset/zoom-hint icons |
| **User Interacting** (dragging to orbit) | Control pill fades to 40% opacity while actively dragging (reduces visual clutter during interaction), returns to full opacity `300ms` after drag ends |
| **Export/Processing** | Same shimmer-gradient treatment as primary button, applied to the "Export .glb/.usdz" action button in Column C |

### 5.5 Global Transition Timing Reference

```
Hover response         : 120ms - 150ms, ease-out
Press/tap feedback     : 100ms, ease-out
Focus ring appearance  : 150ms, ease-in-out
Selection state change : 200ms, ease-in-out
Card lift on hover      : 150ms, ease-out
Shimmer loop (loading)  : 1200ms, linear, infinite
Pulse glow (active AI)  : 800ms, ease-in-out, infinite, opacity 0.4<->1.0
Drawer/sheet slide-in   : 250ms, decelerate curve
```

**Rule:** No state change in this document may render as an instant/hard cut — every transition listed above has a defined duration and easing curve. Any new component added later must define its own entry in this table before merge.