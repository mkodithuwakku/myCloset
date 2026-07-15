# Phase 1 — Capture and Wardrobe Quality

**Status:** Next
**Primary SRS groups:** ITEM, CLO, A11Y, PERF
**Goal:** Turn a phone photo into a reliable, editable, private garment record.

## Entry criteria

- Phase 0 core loop and automated suites pass.
- Supported launch garment taxonomy has product/design approval.
- Vision segmentation feasibility is tested on representative devices.
- Test image corpus is licensed/consented and contains no production user data.

## User outcomes

- Choose clothing type before capture.
- See a category-specific accessible camera guide.
- Capture or import a garment.
- Receive foreground isolation and a proposed crop.
- Correct the mask/crop when automation is wrong.
- Confirm dominant/accent colors sampled only from the garment.
- Confirm name, category, seasons, multiple formality levels, and availability.
- Recover manually from every processing failure.

## Workstreams

### Camera and guidance

- AVFoundation/system camera integration.
- Category-specific overlays with text and VoiceOver guidance.
- Lighting, blur, framing, and occlusion feedback.
- Camera/photo permission denial and Settings recovery.

### Foreground isolation

- Evaluate Vision foreground-instance masks for supported iOS versions.
- Preserve original privately; create normalized display rendition.
- Add mask selection, erase/restore brush, crop, rotate, and reset.
- Define confidence and manual-fallback states.

### Color and metadata

- Sample only confirmed mask pixels.
- Use perceptual color space and standardized families.
- Support multiple dominant/accent colors and user corrections.
- Version taxonomy, color source, confidence, and edit provenance.

### Persistence evolution

- Add schema version and tested migrations.
- Move image bytes out of the JSON envelope into protected local files.
- Use stable media identifiers and lifecycle cleanup.
- Recover from missing/corrupt derivative while retaining metadata.

### Closet usability

- Item detail/review screen.
- Better availability transitions and optional until-date.
- Filter combinations and useful empty results.
- Bulk-safe architecture without requiring bulk actions yet.

## Test plan

- Golden segmentation set by category/background/lighting/pattern.
- Mask-edit unit and UI tests.
- Color accuracy thresholds using reference swatches.
- Large, malformed, unsupported, transparent, rotated, and metadata-heavy images.
- EXIF location stripping verification.
- Permission denied/limited/revoked journeys.
- Schema migration from Phase 0 fixture.
- VoiceOver/Dynamic Type capture journey.
- Performance/memory on oldest supported device class.

## Metrics

- successful automatic isolation rate;
- percentage needing manual correction;
- median time to confirmed item;
- processing failure/retry rate;
- color correction rate;
- capture abandonment rate.

Metrics must not upload private images unless Phase 2 consented processing infrastructure exists.

## Exit criteria

- [ ] Direct capture and import work for every supported category.
- [ ] Users can correct any crop/mask/color result.
- [ ] No precise image geolocation remains in stored/distributed derivatives.
- [ ] Accuracy/performance targets are approved and met by the evaluation set.
- [ ] Phase 0 data migrates without loss.
- [ ] Critical capture journey passes accessibility review.
- [ ] Architecture supports later private-media upload without changing public visibility semantics.

## Risks

- Similar garment/background colors reduce mask quality.
- Color appearance varies with light and camera processing.
- Manual mask editing can become too complex.
- Local originals increase storage use.

Mitigate through capture coaching, confidence-driven fallback, simple editing, compression, storage visibility, and evaluation across diverse conditions.
