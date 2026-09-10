# Test Execution Report — 2026-09-09

The latest outline-guided refinement verification is recorded in the final section. Earlier sections retain the evidence for the outline and launch repairs.

## Initial outline verification

| Gate | Result |
|---|---|
| Generic iOS Simulator build | **Passed** |
| Full shared-scheme suite | **Passed** |
| Unit tests | 73 passed, 0 failed |
| UI journey tests | 7 passed, 0 failed |
| Total | **80 passed, 0 failed** |
| Documentation validation | Passed |
| Diff whitespace validation | Passed |

## Environment

- Host toolchain: Xcode 26.3 (build 17C529)
- Destination: iPhone 17 Pro simulator
- Simulator OS: iOS 26.3.1
- App deployment target: iOS 17.0
- Scheme and plan: shared `myCloset` scheme and `myCloset.xctestplan`
- Execution date: September 9, 2026

## Commands

```sh
xcodebuild \
  -project myCloset.xcodeproj \
  -scheme myCloset \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/myClosetMandatoryLassoBuild \
  CODE_SIGNING_ALLOWED=NO \
  build

xcodebuild \
  -project myCloset.xcodeproj \
  -scheme myCloset \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' \
  -derivedDataPath /tmp/myClosetMandatoryLassoFinalTests \
  -parallel-testing-enabled NO \
  test

./scripts/verify_docs.sh
git diff --check
```

## New behavior exercised

- every new Photos/Files import is blocked at a clear **Outline item** step before metadata or confirmation is available;
- replacement photos chosen from a single-item editor use the same required lasso path;
- the category-independent editor starts tracing immediately, automatically closes on lift, previews the enclosed area, and offers clear/retrace, additional-region, rotate, and reset recovery;
- a geometric unit test rejects a line that encloses no meaningful area and accepts a real closed loop;
- a pixel-level image test proves enclosed source pixels remain opaque, exterior pixels become transparent, and only transparent outer bounds are trimmed;
- final color suggestions are sampled from the user-authored transparent rendition;
- category templates, crop boxes, crop sliders, fitted-photo fallbacks, and optional automatic-background-removal import paths are absent;
- the existing guided review, metadata correction, skip, summary, closet, generator, persistence, and truthful Following journeys remain green.

## Execution note

The lasso UI test initially tried to infer polygon validity from an Xcode UI toolbar button's reported enabled state. That state was unreliable for an automated straight drag, so validity was moved into directly tested deterministic geometry while the UI journey remains responsible for proving the required pre-metadata gate and lasso entry. The final shared-scheme run passed all 78 tests.

## Remaining qualification work

The mandatory lasso removes automatic segmentation quality from the saved-image decision, but edge-point editing, undo, and a magnified finger-offset detail view would make precise outlines faster. Apple's Vision results remain advisory for type detection and still require physical-device qualification. Confidence labels are conservative review guidance, not calibrated probabilities. Direct camera capture, schema-versioned file storage, minimum-OS/device coverage, and a full accessibility audit remain Phase 1 or Phase 6 work.

## Lasso alignment regression fix (later run)

The save pipeline drew the UIKit mask as a raw CGImage, vertically reflecting the selection relative to the source photo. This removed correctly outlined lower edges and retained background above asymmetric garments. The mask now uses UIKit drawing in the same top-left coordinate system as the source and preview.

Before the fix, both new regressions failed (six pixel assertions). After the fix, the complete suite passed **73 unit tests and 7 UI tests, 80 total with zero failures**, with `** TEST SUCCEEDED **`. The generic Simulator build also passed. Removing an unused rendering-context binding afterward made no behavioral change; the final source passed the generic build.

- `testOutlinePreservesAsymmetricGarmentHemAndSourceOrientation` checks opaque lower corners, transparent upper corners, and unchanged upper/lower source colors.
- `testOutlineKeepsSeparateOffCenterRegionsAtTheirSourcePositions` checks two separate colored areas near the photo bottom, transparent space between them, and trimmed output dimensions.
- Existing large-image, invalid-image, palette, rotation, importer, persistence, and UI journeys also passed.

```sh
xcodebuild -project myCloset.xcodeproj -scheme myCloset \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' \
  -derivedDataPath /tmp/myClosetOutlineAlignmentTests \
  -parallel-testing-enabled NO test

xcodebuild -project myCloset.xcodeproj -scheme myCloset \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/myClosetDerivedData CODE_SIGNING_ALLOWED=NO build

./scripts/verify_docs.sh
git diff --check
```

Existing damaged renditions require a new outline because lasso points are transient. No physical-device run or manual retracing of the user's exact photograph was performed for this fix; deterministic synthetic images reproduce the reported geometry without storing personal photos in the repository.

## Persistent Xcode Simulator launch failure (later run)

### Reproduced cause

The Xcode Run error at 17:06 MDT was reproduced with `simctl launch` against the interactive iPhone 17 Pro. Both returned `SBMainWorkspace Busy / Application failed preflight checks`. The installed bundle passed signature verification. Simulator installation logs reported a successful delta update, but SpringBoard continued to reject launch because the app was “being updated,” with an orphaned installation placeholder. A synchronous installation of the same signed bundle cleared the state and launched successfully. No app uninstall, simulator erase, bundle-ID change, or signing bypass was used.

### Durable changes

- The shared Run pre-action verifies the signed built app, waits for the exact selected simulator UUID to finish booting, and synchronously refreshes its installation. Physical-device runs are skipped. Successful preparation writes a timestamp in the target temporary build directory.
- Xcode’s cached in-memory scheme initially omitted the new action and reproduced the failure on a cold start. The project was closed, the shared scheme reapplied, and the project reopened. **Edit Scheme → Run → Pre-actions** then showed the action; actual runs produced fresh preparation timestamps.
- `scripts/test_ios.py` runs signed XCTest serially on a newly created disposable simulator, then removes only that UUID. The interactive simulator is not used by automated resets or installs.
- Eight host-side tests cover the guard, and the CI workflow runs them.

### Verified results

| Check | Result |
|---|---|
| Command-R repairs existing stale state with loaded pre-action | Passed; debugger attached, PID 61502 |
| Repeat Command-R after stopping | Passed; debugger attached, PID 61562 |
| Command-R from a fully shut-down interactive simulator | Passed; debugger attached, PID 61829 |
| Shared pre-action execution | Verified timestamp for the selected UUID after each prepared run |
| Existing persistent Documents/Application Support files | SHA-256 manifest unchanged across repeated and cold runs |
| Isolated XCTest runner | 73 unit + 7 UI tests passed; `** TEST SUCCEEDED **` |
| Temporary test simulator cleanup | Its UUID no longer exists; interactive device retained |
| Host-side launch checks | 8 passed |
| Documentation and whitespace gates | Passed |

The test bundle is retained locally at `/var/folders/n0/dpwsbz2j2fzfgzdq641t_l7h0000gn/T/myClosetTests-_8xwxqpr/Tests.xcresult`. Commands:

```sh
./scripts/test_ios.py
python3 -m unittest discover -s scripts/tests -v
./scripts/verify_docs.sh
git diff --check
```

The app was left running under Xcode. These checks cover the observed stale-update failure on Xcode 26.3 / iOS Simulator 26.3.1, including a cold start; they are not a guarantee against every future CoreSimulator or Xcode defect. No physical-device launch was performed.


## Specific garment types, deletion, and outfit composition

The final app changes were verified on September 9 with Xcode 26.3 and iPhone 17 Pro / iOS 26.3.1 Simulator. All 92 distinct app tests have passing results across the full suite and targeted UI reruns; the final source was also built and launched through Xcode. A single clean full-plan run of all 92 tests was not repeated after the UI fixes.

| Gate | Result |
|---|---|
| Unit/domain/store/image tests | **83 passed**, including 100 warm/cold generation iterations, retained/conflicting upper-body locks, single/full top-jacket replacements, specific metadata defaults, old-record decoding, persistence/history, and larger footwear bounds |
| UI journeys | **All 9 passed** across full and targeted reruns; long-press cancellation/deletion/relaunch, selected-item editor state, specific-type import/name/seasons/save/reopen, and shoe outline guidance included |
| Host launch-workflow checks | **8 passed** |
| Generic simulator compilation | `** BUILD SUCCEEDED **`; `/tmp/myCloset-category-build.log` |
| Final signed Xcode build and Command-R | Passed; debugger attached with PID 65325 and fresh shared pre-action preparation log |
| Visual check with existing garment photos | Larger portrait shoe pair fits within the board; jacket + trousers + footwear has three pieces and no shirt behind the jacket |
| Existing-item type menu | Jacket selectable; automatic “Black Outerwear” name changes to “Black Jacket”; check cancelled without saving |
| Documentation and diff whitespace | Passed |

Execution artifacts (local, excluded from Git):

- Full run: `myClosetTests-o30rrrd3/Tests.xcresult` under the host temporary directory; all 83 unit tests passed. UI failures exposed a stale selected-item sheet binding, an ambiguous native alert lookup, and an offscreen test tap.
- UI suite after the sheet/alert fixes: `myClosetTests-w0vkgcp2/Tests.xcresult`; eight of nine passed, with the remaining test overscrolling its target.
- Bounded-gesture import rerun: `myClosetTests-wg_gf582/Tests.xcresult`; the custom-name import journey passed, and the specific-type journey reached the saved editor. Its final picker assertion was corrected to read the native label.
- Final specific-type journey: `myClosetTests-p7fra897/Tests.xcresult`; **1 passed, 0 failed**, `** TEST SUCCEEDED **`. The saved Shorts type, Black Shorts name, spring/summer defaults, and editor values all passed.

All simulator test devices were created by `scripts/test_ios.py`; no reset, deletion, or automated test installation targeted the interactive simulator. Domain code was unchanged after the 83-unit-test pass; subsequent app edits corrected the editor presentation and UI reroll acceptance. The latter uses the already-tested shared upper-body slot. Saved/worn snapshots and private storage remain local. Physical-device, VoiceOver, and the broader device matrix were not exercised in this slice.

Commands used:

```sh
./scripts/test_ios.py
./scripts/test_ios.py -only-testing:myClosetUITests
./scripts/test_ios.py -only-testing:myClosetUITests/MyClosetUITests/testSpecificImportTypeUpdatesAutomaticNameSeasonsAndSavedDetails -only-testing:myClosetUITests/MyClosetUITests/testImportedPieceMustBeConfirmedAndCanBeCorrectedBeforeSaving
./scripts/test_ios.py -only-testing:myClosetUITests/MyClosetUITests/testSpecificImportTypeUpdatesAutomaticNameSeasonsAndSavedDetails
python3 -m unittest discover -s scripts/tests -v
./scripts/verify_docs.sh
git diff --check
```


## Follow-up: smaller tops and jackets

The shared Home/Generate canvas now uses smaller upper-body frames and places their hems closer to the waistband. Top width/height changed from 0.58/0.34 to 0.46/0.28 of the board; outerwear changed from 0.66/0.42 to 0.50/0.30. Both are centered at vertical position 0.28. Pants and footwear retain their previous placement and size, and aspect-fit keeps source image proportions intact.

- Extended the existing layout regression to cap upper-body width relative to pants, height relative to pants, and waistband overlap, and retain horizontal alignment.
- `./scripts/test_ios.py -only-testing:myClosetTests/ModelsAndImageTests`: **26 passed, 0 failed**, `** TEST SUCCEEDED **`.
- Result bundle: `/var/folders/n0/dpwsbz2j2fzfgzdq641t_l7h0000gn/T/myClosetTests-5x0ij2tp/Tests.xcresult` (local only).
- Signed build and Command-R launch succeeded; visually checked Home with the existing denim jacket, dark trousers, and white shoe pair. The jacket is smaller and substantially more of the pants is visible.
- Documentation and diff-whitespace checks passed. Test inventory remains 83 unit + 9 UI + 8 host checks; this layout-only follow-up reran the 26-test model/image suite. Full UI suite and physical-device testing were not rerun. Generate uses the same shared canvas; an additional interactive tab check was unavailable when the computer-use service lost its window handle during disposable-simulator cleanup.


## Experiment: outline-guided edge refinement

Branch: `codex/outline-guided-refinement`, based on `e54b75be950d49d639c536fc174da2cbc9882fdf`.

The outline editor now tries an on-device refinement after a valid trace. A user can compare Refined/My outline and explicitly apply either version, or keep the manual outline while processing. Vision instances are selected using every outlined region. Coverage guards reject missing regions, lost interiors, and distant background; the local color fallback changes only a narrow boundary band and removes unsupported disconnected specks. Small additional areas are included in validation even below the main-lasso area minimum. Cancellation/request IDs prevent old suggestions from replacing a retraced or rotated image.

Verification on Xcode 26.3 / iPhone 17 Pro Simulator, iOS 26.3.1:

- Generic unsigned Simulator compilation passed; runnable tests used local signing on disposable simulators.
- Final regression command ran **91 unit tests and 2 targeted UI tests**, all passing with `** TEST SUCCEEDED **`. Result bundle: `myClosetTests-6z5uf3bu/Tests.xcresult` in the host temporary directory; command log `/tmp/myCloset-refinement-final-tests.log`.
- The eight new deterministic image tests cover inward/outward correction, source orientation and asymmetric hems, two separate shoes and a distractor, ambiguous-color manual recovery, lost-region/background rejection (including tiny extra areas), instance selection by outline, malformed/large input and 1,200-pixel output bounds, and cancellation.
- The targeted UI journeys cover the existing mandatory-lasso gate and the new comparison/apply/retrace/rotation flow. Successful screenshots were retained for visual inspection. A subsequent layout correction uses identical guidance in comparison modes so the preview stays in place; its targeted UI rerun is recorded below.
- An initial test compile failed on an ambiguous Swift `.nan` literal; spelling `CGFloat.nan` fixed the test. The first complete run then found a real corner case: a few floor pixels inside a concave lasso contaminated the foreground color palette, preventing refinement. Ignoring insignificant sample buckets fixed it; all eight refinement tests passed on rerun and in the final regression run.
- A temporary local-only trial ran two existing Git-ignored clothing photos (dark shirt on a plain floor and sweatshirt on a patterned rug). Both produced cutouts. Visual inspection found substantially cleaner plain-floor edges and better rug removal after the palette fix; the patterned rug still affected some fine trim. The temporary trial test was removed, and photos/output were not added to the repository. Outputs remain under `/tmp/myCloset-refinement-trial` for local review.
- The full 10-test UI suite, physical-device Vision quality, VoiceOver, large Dynamic Type, minimum-iOS coverage, and oldest-device performance were **not** run for this experiment. Simulator results do not qualify Apple's model on physical devices. Similar colors, textured backgrounds, shadows, fine trim, and large tracing errors can still need manual correction.

Inventory is now **91 unit + 10 UI + 8 host checks**. This is an experimental Phase 1 slice, not a claim of universal segmentation accuracy.

Preview-layout rerun: **1 targeted UI test passed**, `** TEST SUCCEEDED **`, result bundle `myClosetTests-1lniyn6e/Tests.xcresult`, log `/tmp/myCloset-refinement-layout-tests.log`. Exported comparison screenshots confirmed matching preview geometry. A hidden-text sizing aid was then replaced with identical visible guidance in both modes to keep all guidance visible; the final rerun is recorded below. Documentation link/status and `git diff --check` gates passed.

Final comparison rerun: **1 targeted UI test passed**, `** TEST SUCCEEDED **`, result bundle `myClosetTests-0nmwtlb4/Tests.xcresult`, log `/tmp/myCloset-refinement-comparison-tests.log`. Both exported screenshots show the same garment position/scale, all shoe guidance, both version choices, and the corresponding apply action.
