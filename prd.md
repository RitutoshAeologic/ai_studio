# prd.md — Product Requirement Document

## AI Studio — Phase 1 (Fast Tier)

---

## 1. Product Summary

AI Studio is a cross-platform Flutter application (Android + iOS) that lets users generate AI-powered 3D images and short videos from photos and text prompts. Phase 1 ships the **Fast (SD) Tier only** — Pro tier is explicitly out of scope for this phase.

The app must look and feel like a **premium image-editing app** (Lightroom / Picsart / CapCut tier of polish) — not a generic CRUD app with AI bolted on. Visual quality of the UI is a first-class requirement, equal in priority to functional correctness.

---

## 2. Problem Statement

Users want fast, high-quality AI image/3D/video edits without:
- Understanding prompt engineering
- Waiting minutes for results
- Paying premium-tier prices for casual use

Existing tools are either too slow (cloud LLM-heavy), too expensive (Pro-tier pricing for all requests), or produce inconsistent results (no curated prompt/theme system).

---

## 3. Target Audience

- Social media users wanting quick photo edits (background/theme change)
- Casual creators wanting novelty 3D exports of their photos
- Users wanting short AI video clips from a single image + script
- Price-sensitive users who want a free-credit trial before spending

---

## 4. Core Features — Phase 1 Scope

| # | Feature | Credit Cost | Output |
|---|---|---|---|
| 1 | Image → 3D | 5 credits | `.glb` (Android) / `.usdz` (iOS) |
| 2 | Theme Change | 3 credits | Edited image |
| 3 | Background Change | 3 credits | Edited image |
| 4 | 10-Second Video | 40 credits | `.mp4` |

**Explicitly out of scope for Phase 1:**
- Pro tier (any feature)
- In-app purchase / credit top-up flows (tracked separately, not part of this phase's build)
- AI Avatars, voice, lip sync, multi-character scenes (Phase 3 roadmap items)

---

## 5. User Journeys

### 5.1 New User
1. Signs up (Google / Apple / Anonymous) → auto-provisioned with **100 free credits**
2. Lands on home/gallery screen (empty state, editing-app style)
3. Picks a feature (Image→3D, Theme, Background, Video)
4. Uploads/captures image → submits job → sees real-time status (queued → processing → completed)
5. Views/downloads/shares result

### 5.2 Returning User
1. Opens app → sees credit balance in persistent header
2. Views job history / gallery of past generations
3. Re-runs or starts a new generation
4. If credits insufficient → sees blocked state with clear messaging (no purchase flow yet in this phase — just a "not enough credits" state)

---

## 6. Functional Requirements

- Real-time job status must update via Firestore snapshot listeners — no manual refresh
- Every job must show a clear state: `idle → deducting_credits → queued → processing → completed / error`
- Credit deduction must be atomic and never allow a negative balance or double-deduction
- 3D results must be viewable in an interactive viewer (orbit, pinch-zoom, pan, reset) — not just a static thumbnail
- Video results must support standard playback controls
- All generated assets must be downloadable and shareable via native share sheet
- Errors from backend must surface a clear, actionable message — never a raw exception or blank state

---

## 7. Non-Functional Requirements

- **No UI jank/lag** — all list views, image loads, and transitions must stay at 60fps on mid-range devices
- **No memory leaks** — every controller, stream subscription, and animation controller must be disposed correctly
- **No `setState`** anywhere GetX is applicable — state changes flow through GetX reactive state only
- App must remain lightweight — no bundled AI/LLM models on-device (see `architecture.md`)
- App must handle poor network gracefully — retry logic, offline indicators, no silent failures

---

## 8. Success Metrics (Phase 1)

- Job success rate ≥ 95% (excluding user-caused errors like invalid images)
- Median job completion time within documented performance targets (see original architecture spec)
- Zero credit-accounting bugs (double charge, missed charge, negative balance)
- Crash-free session rate ≥ 99.5%

---

## 9. Out-of-Scope Confirmation (Read Before Building)

If a task references any of the following, **stop and confirm with TL before implementing** — they are not part of Phase 1:
- Pro tier models/pipelines
- In-app purchase / RevenueCat / StoreKit / Play Billing integration
- Any on-device LLM or bundled model weights
- AI Avatars, voice, lip sync, team collaboration, API platform, web studio
