# ui_ux.md — Design System & Guidelines

## AI Studio — Visual Identity & Interaction Standards

---

## 1. Design Direction

The app must feel like a **premium AI image/video editing tool** — think Lightroom, Picsart, CapCut, or Meitu — not a generic form-based utility app. Every screen should communicate "creative tool," not "admin dashboard."

**Core aesthetic:** Dark-first, content-forward, minimal chrome. Let the generated media be the visual focus — UI elements should recede, not compete.

---

## 2. Color Palette

| Token | Hex | Usage |
|---|---|---|
| `bgPrimary` | `#0A0A0F` | App background (near-black, not pure black) |
| `bgSurface` | `#16161D` | Cards, sheets, elevated surfaces |
| `bgSurfaceElevated` | `#1E1E28` | Modals, dialogs |
| `accentPrimary` | `#6C5CE7` | Primary CTA, active states, selected theme chips |
| `accentGradientStart` | `#6C5CE7` | Gradient buttons/highlights start |
| `accentGradientEnd` | `#A64CE7` | Gradient buttons/highlights end |
| `textPrimary` | `#F5F5F7` | Primary text on dark surfaces |
| `textSecondary` | `#9A9AA5` | Secondary/meta text |
| `textDisabled` | `#5A5A66` | Disabled states |
| `success` | `#2ECC71` | Job completed, success toasts |
| `warning` | `#F5A623` | Processing/queued states |
| `error` | `#E74C3C` | Failed jobs, error states |
| `creditGold` | `#F5C542` | Credit balance badge accent |

**Rule:** No pure white (`#FFFFFF`) or pure black (`#000000`) anywhere — always use the tokens above for a softer, editorial-app feel.

---

## 3. Typography

- **Font family:** `Inter` or `Manrope` (fallback: system default) — clean, modern, geometric sans
- **Scale:**

| Style | Size | Weight | Usage |
|---|---|---|---|
| `displayLarge` | 28sp | 700 | Screen titles ("Create", "Gallery") |
| `headingMedium` | 20sp | 600 | Section headers, card titles |
| `bodyLarge` | 16sp | 400 | Primary body text |
| `bodyMedium` | 14sp | 400 | Secondary body text |
| `caption` | 12sp | 500 | Meta info, timestamps, credit costs |
| `buttonLabel` | 15sp | 600 | Button text, all-caps not required |

---

## 4. Spacing System

8pt grid — all margins/padding are multiples of 4, standard step is 8:

```
xs  = 4
sm  = 8
md  = 16
lg  = 24
xl  = 32
xxl = 48
```

Screen edge padding: `16` (mobile). Card internal padding: `16`. Section vertical gap: `24`.

---

## 5. Component Behavior Standards

### Buttons
- Primary CTA: gradient fill (`accentGradientStart` → `accentGradientEnd`), fully rounded corners (radius `28` for pill-shaped generate buttons)
- Pressed state: scale down to `0.97` with `100ms` ease-out — every tappable element needs tactile feedback
- Disabled state: `textDisabled` background, no gradient, no shadow
- Loading state: replace label with inline spinner, keep button width fixed (no layout shift)

### Cards (Job History / Gallery Grid)
- Corner radius: `16`
- Subtle elevation via soft shadow (`opacity 0.15`, blur `12`), not hard drop-shadows
- Image thumbnails: `BoxFit.cover`, rounded to match card radius
- Status badge overlay (top-right corner) for processing/failed states — small pill with icon + color from status palette

### Theme/Preset Picker (Chips)
- Horizontal scrollable chip row, rounded-full shape
- Selected state: gradient border + `accentPrimary` glow, not just a color fill — should feel premium, not like a generic filter toggle

### Credit Balance Badge (Persistent Header)
- Pill-shaped, `creditGold` icon + count, always visible in the top app bar across all main screens
- Animates (subtle scale bounce) when balance changes — gives clear feedback on deduction

### Job Progress States
- **Queued:** pulsing dot animation, muted color
- **Processing:** circular progress indicator with percentage if available, or indeterminate shimmer over the thumbnail placeholder
- **Completed:** thumbnail fades in with a subtle scale-up + fade transition (`250ms`) — never just "pop in" abruptly
- **Failed:** red accent border on card + retry icon button

### 3D Viewer
- Full-bleed viewport, dark background matching `bgPrimary`
- Floating pill-shaped control bar at bottom (rotate/reset/zoom hint) — semi-transparent surface over the 3D content
- Loading state: skeleton/shimmer in the shape of a rotating placeholder cube, not a plain spinner

### Video Player
- Custom-skinned controls matching the palette (not default Flutter/Android player chrome)
- Scrubber uses `accentPrimary`, not default platform color

---

## 6. Motion & Transitions

- Page transitions: shared-axis or fade-through (`Get.to()` with custom `transition: Transition.fadeIn` or `cupertino` depending on platform feel) — no default abrupt platform transitions
- List item entrance: staggered fade + slight upward slide when a grid first loads (`~40ms` stagger per item, capped at first 8–10 visible items to avoid jank)
- No animation should block user input — all transitions are visual only, never gate interaction

---

## 7. Empty & Error States

Every screen needs a designed empty state — never a blank white/dark screen with no explanation:

- **No jobs yet:** Illustration + "Start your first creation" + CTA button
- **No credits:** Illustration + clear balance display + "Come back later" or relevant messaging (no purchase flow in Phase 1 — see `prd.md`)
- **Network error:** Icon + short message + retry button — never a raw error string
- **Job failed:** Specific, human-readable reason if backend provides one, otherwise generic "Something went wrong — try again"

---

## 8. Accessibility Baseline

- Minimum tap target: `48x48`
- Text contrast against `bgPrimary`/`bgSurface` must meet WCAG AA at minimum
- All icon-only buttons need a `Semantics` label
- Respect system font scaling up to at least 130% without layout breakage

---

## 9. What to Avoid

- No default Material `ElevatedButton`/`TextButton` styling left unstyled — every interactive element goes through the design tokens above
- No default `SnackBar` — use a custom-styled toast/snackbar matching the palette
- No jarring instant state changes — every state transition (loading → success, idle → error) needs a transition, even if brief
- No layout shift when async content loads — reserve space with skeletons/placeholders
