# myCloset prototype slice status

**Slice:** 0.1.0 local functional prototype
**Verified:** September 9, 2026
**Runtime:** iPhone 17 simulator, iOS 26.3.1
**Minimum configured OS:** iOS 17.0

## Slice outcome

This slice provides a genuinely usable local wardrobe and outfit-generation loop. It is not a production backend or App Store release candidate.

## Implemented

| Capability | SRS area | Prototype behavior |
|---|---|---|
| Five-tab iPhone shell | 5.1 | Home, Closet, Generate, Following, and Profile are present |
| Local closet | CLO-001–CLO-011 | Starts empty for real users; create, bulk-import, edit, metadata-aware search, specific-type filter, favorite, archive, set availability, and confirmed deletion from the hold menu or editor |
| Clothing metadata | ITEM-001–ITEM-018 | 29 specific garment types, broad categories, matching automatic names, editable type-specific seasons/formalities, colors, and confirmation form; old generic records still load |
| Duplicate-name warning | ITEM-013–ITEM-014 | Case- and whitespace-normalized warning without blocking save |
| Photo import | ITEM-006–ITEM-019 | Up to 50 Photos/Files images per batch with live analysis progress, filename-first and on-device suggestions, a required simple lasso before each new photo's metadata can be confirmed, reviewable outline-guided edge refinement and transparent renditions, foreground-only color sampling, separate editable confidence guidance, kind-aware defaults, skippable guided review, metadata-synchronized names, batch or single-item re-analysis, and a post-import category/readiness summary |
| Capture guidance preview | ITEM-004–ITEM-005 | Trace/lift guidance, shaded lasso preview, and instructions to outline each shoe separately using Add another area; direct camera guidance remains deferred |
| Weather fallback | WEA-001–WEA-011 | Current foreground location, manually entered city, or date-derived season |
| Outfit of the Day | HOME-001–HOME-009 | Isolated garments layered into a body-aligned visual look, compact weather context, explanation, refresh, save, and mark worn |
| Occasion/formality input | GEN-001–GEN-007 | All specified presets and six formality levels in a compact visual outfit brief |
| Generate experience | GEN-001–GEN-013 | Automatic first look, body-aligned layered garment board, different-look search, closet-readiness recovery, visible success/failure feedback after every tap, reroll, lock, save, and worn actions |
| Local recommendation engine | COMP, REC | Available items only; separates use one top or outerwear plus bottom, so jackets replace shirts; retained locks, actionable top/jacket conflicts, upper-body rerolls, soft season/formality fallback, and explanations |
| Locking and rerolling | COMP-005–COMP-016 | Generate without a required starting piece, lock generated items, reroll one piece, or reroll all unlocked pieces |
| Saved and worn history | HIST-001–HIST-009 | Immutable local snapshots, separate profile collections, and deletion |
| Local profile | PROF-001–PROF-006 | Display name, handle, bio, and profile photo editing |
| Following roadmap state | SOC | Minimal Coming Soon screen; no fake profiles, posts, or service behavior |
| Accessibility foundations | A11Y | Dynamic native controls, text color names, accessibility labels on key icon controls, and no color-only status |
| Local persistence | OFF-001 | Codable application-support storage survives relaunches |
| Automated verification | ENG-004–ENG-006 | Shared scheme with automatic Simulator installation preparation, 91 unit tests, 10 UI tests, 8 host-side launch checks, isolated CLI test simulator, and GitHub Actions CI |

## Partial or prototype-only

| Capability | Current limitation |
|---|---|
| Garment isolation | Every new imported or replacement photo requires a valid user-drawn lasso. The saved mask uses the same top-to-bottom orientation as the preview, preserving asymmetric hems, sleeves, and separate regions. The app closes the loop, keeps the enclosed source pixels, makes the exterior transparent, trims transparent bounds, and supports retracing, multiple regions, rotation, and reset. After a valid outline, optional on-device edge refinement uses Vision instances selected by outline overlap, with conservative local color refinement when needed. A same-position Refined/My outline comparison requires explicit application; ambiguous results preserve the original lasso. Changes are limited to nearby edges and each region must survive. Fine details, similar colors, shadows, large tracing errors, point editing, and physical-device qualification remain |
| Camera guidance | The lasso editor handles library/files photos, but direct camera capture is deferred |
| Color extraction | Samples the saved transparent rendition when available, suppresses frame/background colors and untrusted accents, classifies hue and neutrals perceptually, and flags weak full-photo results for review; editable masks and calibrated production confidence remain |
| Clothing-type detection | Filename rules remain deterministic; Apple's visual labels and silhouettes are best-effort, with expanded shoe terms and explicit jacket/hoodie outerwear handling. Generic results are explicitly uncertain, and every imported piece requires user confirmation before persistence |
| Recommendation learning | Save/worn actions persist, but explicit feedback preference training is deferred |
| Weather | Uses keyless Open-Meteo and Apple geocoding without production caching, provider contracts, or severe-weather rules |
| Offline behavior | Closet, history, profile, and generation work locally; cross-device synchronization is excluded by design |
| Outfit completeness | Separates use one top or outerwear plus a bottom; a one-piece may still have outerwear. Footwear uses a larger aspect-fit frame; smaller tops/jackets have limited waistband overlap to keep trousers visible. Production taxonomy versioning and cultural/personal rule configuration remain |

## Excluded from the first App Store release

- Sign in with Apple and Google.
- Backend authorization, sync, hosted media, and account lifecycle.
- Functioning user search, following, public profiles, feed, and outfit posting; the tab is Coming Soon only.
- Cloud AI, reporting, blocking, moderation, and administrator tools.
- Trip planning and packing lists.
- Push notifications.
- Machine-readable local export and more granular local deletion controls.
- Paid analytics/observability, cloud backups, and server incident operations.
- App icon, final brand, App Store metadata, legal documents, and signing team configuration.

CloudKit profiles and following are approved only as the gated post-release Phase 7 defined by ADR-0004. The other excluded capabilities still require their applicable product, cost, privacy, and safety decisions. The first release remains a useful local wardrobe and outfit application without them.

## Verification performed

1. Built `myCloset.xcodeproj` for the generic iOS Simulator SDK with signing disabled.
2. Installed and launched `com.mkodi.myCloset.prototype` on an iPhone 17 Pro simulator.
3. Verified the empty Home experience and sample-closet action.
4. Verified the real-user empty state routes to personal image import; loaded the 12-piece fixture only through debug launch controls.
5. Verified that Home produced a season-aware Outfit of the Day.
6. Relaunched the installed app and verified local persistence.
7. Opened Generate through a debug smoke-test launch argument and verified the automatic editorial outfit board rendered with piece-level lock and reroll controls.
8. Exercised the visual outfit brief through the UI journey and verified a Work brief produced a rendered outfit.
9. Before the refinement experiment, ran all 83 unit tests and all nine end-to-end UI tests successfully, including the mandatory pre-metadata lasso gate, invalid-line rejection, closed-outline interior retention and exterior transparency, guided metadata progression, confidence guidance, skip recovery, import summary/readiness, next-piece top reset, and preservation of a manually edited import name.

10. For the outline-refinement experiment, ran 91 unit tests and two targeted UI journeys successfully, plus local photo trials. The full 10-test UI suite and physical-device Vision qualification were not rerun; see the latest execution report.

Build command:

```sh
xcodebuild -project myCloset.xcodeproj \
  -scheme myCloset \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/myClosetDerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Recommended next slice

The next highest-value vertical slice is **complete garment capture and cleanup**:

1. direct camera capture with category-specific guides;
2. outline-point/edge refinement, undo, and physical-device qualification building on the required closed-outline mask;
3. calibrated photo-quality and color-confidence states with retry guidance;
4. persistence schema versioning for capture failure/recovery;
5. physical-device capture and accessibility qualification.

This improves every recommendation while preserving the approved local-only first-release architecture.
