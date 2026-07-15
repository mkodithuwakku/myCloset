# myCloset prototype slice status

**Slice:** 0.1.0 local functional prototype
**Verified:** July 14, 2026
**Runtime:** iPhone 17 Pro simulator, iOS 26.3
**Minimum configured OS:** iOS 17.0

## Slice outcome

This slice provides a genuinely usable local wardrobe and outfit-generation loop. It is not a production backend or App Store release candidate.

## Implemented

| Capability | SRS area | Prototype behavior |
|---|---|---|
| Five-tab iPhone shell | 5.1 | Home, Closet, Generate, Following, and Profile are present |
| Local closet | CLO-001–CLO-011 | Create, edit, search, filter, favorite, archive, set availability, and delete |
| Clothing metadata | ITEM-001–ITEM-018 | Name, category, dominant/accent colors, multiple seasons, multiple formalities, and confirmation form |
| Duplicate-name warning | ITEM-013–ITEM-014 | Case- and whitespace-normalized warning without blocking save |
| Photo import | ITEM-006, ITEM-009–ITEM-011 | PhotosPicker import, image resizing, and editable dominant/accent color suggestions |
| Capture guidance preview | ITEM-004–ITEM-005 | Category-aware framing outline and guidance text in the editor |
| Weather fallback | WEA-001–WEA-011 | Current foreground location, manually entered city, or date-derived season |
| Outfit of the Day | HOME-001–HOME-009 | Garment images composed as one visual look, compact weather context, explanation, refresh, save, and mark worn |
| Occasion/formality input | GEN-001–GEN-007 | All specified presets and a six-level formality control |
| Local recommendation engine | COMP, REC | Available items only, valid base structure, season/formality filtering, color scoring, favorites, variety, and explanations |
| Locking and rerolling | COMP-005–COMP-016 | Pre-lock pieces, lock generated items, reroll one piece, or reroll all unlocked pieces |
| Saved and worn history | HIST-001–HIST-009 | Immutable local snapshots, separate profile collections, and deletion |
| Local profile | PROF-001–PROF-006 | Display name, handle, bio, and profile photo editing |
| Accessibility foundations | A11Y | Dynamic native controls, text color names, accessibility labels on key icon controls, and no color-only status |
| Local persistence | OFF-001 | Codable application-support storage survives relaunches |
| Automated verification | ENG-004–ENG-006 | Shared scheme, 30 unit tests, 3 UI tests, and GitHub Actions CI |

## Partial or prototype-only

| Capability | Current limitation |
|---|---|
| Garment isolation | Image background removal and adjustable segmentation masks are not implemented yet |
| Camera guidance | The outline appears in the import editor, but direct camera capture is deferred |
| Color extraction | Uses local sampled palette quantization; production confidence, masking, and richer color science remain |
| Recommendation learning | Save/worn actions persist, but explicit feedback preference training is deferred |
| Weather | Uses keyless Open-Meteo and Apple geocoding without production caching, provider contracts, or severe-weather rules |
| Offline behavior | Local data works offline; queued synchronization does not exist without a backend |
| Outfit completeness | Core tops/bottoms/one-piece/footwear/outerwear/accessory rules exist; production taxonomy and cultural/personal rule configuration remain |

## Deliberately deferred

- Sign in with Apple and Google.
- Backend authorization, sync, media storage, and account lifecycle.
- Real user search, following, profiles, feed, and outfit posting.
- Reporting, blocking, moderation, and administrator tools.
- Trip planning and packing lists.
- Push notifications.
- Data export and in-app account deletion.
- Production security, analytics, observability, backups, and incident operations.
- App icon, final brand, App Store metadata, legal documents, and signing team configuration.

The Following tab intentionally explains this boundary instead of presenting fake social data. Social publishing must not ship until its privacy and moderation dependencies exist.

## Verification performed

1. Built `myCloset.xcodeproj` for the generic iOS Simulator SDK with signing disabled.
2. Installed and launched `com.mkodi.myCloset.prototype` on an iPhone 17 Pro simulator.
3. Verified the empty Home experience and sample-closet action.
4. Loaded the persisted 12-piece sample closet.
5. Verified that Home produced a season-aware Outfit of the Day.
6. Relaunched the installed app and verified local persistence.
7. Opened Generate through a debug smoke-test launch argument and verified a generated outfit rendered with piece-level lock and reroll controls.
8. Ran all 30 unit tests and all 3 end-to-end UI tests successfully.

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

The next highest-value vertical slice is **real garment capture and cleanup**:

1. direct camera capture with category-specific guides;
2. Vision foreground-instance masking and user-adjustable crop;
3. color extraction from the isolated garment only;
4. photo-quality checks and retry guidance;
5. automated tests for duplicate naming, persistence, and locked-piece generation.

This improves the quality of every later recommendation while keeping the product useful before introducing backend and social complexity.
