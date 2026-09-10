# Phase 1 — Capture and Wardrobe Quality

**Status:** In progress
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
- Outline every imported item with one simple lasso before metadata confirmation.
- Compare refined fabric edges against the hand-drawn outline, approve the preferred cutout, and retrace when needed.
- Confirm dominant/accent colors sampled only from the garment.
- Confirm name, category, seasons, multiple formality levels, and availability.
- Recover manually from every processing failure.

## Workstreams

### Delivered in the current slice

- Experimental outline-guided edge refinement using Vision instance overlap and a conservative color fallback in a narrow boundary band; per-region retention guards protect separate shoes and garment interiors. Refined/My outline comparison, checkerboard transparency, explicit acceptance, asynchronous processing, cancellation, and stale-result rejection preserve manual recovery. Physical-device accuracy and performance remain unqualified.

- Persisted selectable garment types, including shorts, long sleeve, jacket, and 26 other specific choices, with synchronized default names, editable season/formality defaults, specific-type search/filtering, and legacy-record compatibility.
- Delete from the closet card's long-press menu with cancellation/confirmation and preserved saved/worn snapshots.
- Shoe-pair guidance to outline each shoe with a separate area, plus larger proportional footwear on the shared outfit canvas.
- Automatic Vision foreground-instance isolation with garment-coverage rejection, a conservative border-palette fallback where the OS model is unavailable, and higher-resolution private transparent outfit renditions while preserving the original.
- Color analysis prefers isolated opaque pixels and omits untrusted accent suggestions when no dependable foreground is available.
- One category-independent lasso is the only image-import isolation UI. Metadata and confirmation remain gated until the user traces a meaningful enclosed area; the app closes it on lift, shades the kept area, removes the exterior, and supports retrace, multiple regions, rotation, and reset.
- Guided sequential metadata review with automatic next-section movement and a top reset for every next item.
- Expanded footwear and long-sleeve labels plus kind-aware and category-aware season defaults that remain user-editable after outlining or changing type.
- Body-aligned outfit composition using the isolated rendition in live and immutable historical looks.
- Visible per-image analysis progress, per-photo skip recovery, and a post-import category/readiness summary.
- Separate type, colour, and cutout confidence guidance that calls non-strong suggestions out for manual review and offers one-tap explicit confirmation only when every signal is strong.
- Left/right rotation and reset in the lasso flow, plus single-item re-analysis that preserves curated metadata until save.
- Body-aligned outfit geometry with standardized footwear scale and smaller tops/jackets whose limited waistband overlap keeps trousers visible.

### Camera and guidance

- AVFoundation/system camera integration.
- Category-specific overlays with text and VoiceOver guidance.
- Lighting, blur, framing, and occlusion feedback.
- Camera/photo permission denial and Settings recovery.

### Foreground isolation

- Qualify the prototype Vision foreground-instance mask across supported iOS versions and representative physical devices.
- Preserve original privately; create normalized display rendition.
- Add outline-point adjustment and undo refinement on top of the delivered required closed-outline mask and rotate/reset recovery.
- Calibrate the delivered review-confidence states and add photo-quality retry guidance.

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
- [ ] Users can refine any outline/mask/color result.
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
