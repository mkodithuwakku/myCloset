# Phase 5 — Trips, Packing, and Offline Synchronization

**Status:** Planned
**Primary SRS groups:** TRIP, WEA, OFF, NOTIF, REL
**Goal:** Help users plan multiple outfits and a reliable packing list across connectivity conditions.

## Entry criteria

- Phase 2 synchronization/conflict foundation is stable.
- Phase 3 generation accepts destination/date/occasion context.
- Product approves trip privacy and weather fallback UX.

## User outcomes

- Create a private trip with name, optional destination, start/end dates.
- Define occasions and formality needs.
- Use forecast, seasonal norms, or manual context with disclosed source.
- Generate/save multiple trip outfits.
- Reuse one physical item across many outfits.
- See each unique item once in the packing list.
- Mark packed/unpacked offline.
- Detect overlapping trip and availability conflicts.
- Optionally receive privacy-safe trip reminders.

## Domain model

- `Trip`: owner, dates, destination/context, lifecycle/version.
- `TripOutfit`: immutable outfit snapshot plus intended day/occasion.
- `PackingItem`: trip + physical closet item + packed state.
- Assignment set derives unique packing records.
- Conflict service checks overlapping trips and global availability.

## Offline/sync behavior

- Cache active/upcoming trips and required closet renditions.
- Queue idempotent packing/outfit mutations.
- Expose sync status and recoverable failures.
- Use version/precondition conflict detection.
- Merge independent packing toggles; require user resolution for destructive structural conflicts.
- Never retain another account's data after sign-out/account switch.

## Weather behavior

- Forecast when date/provider horizon supports it.
- Seasonal norms clearly labelled for distant dates.
- User-entered context when destination is omitted.
- No implication of forecast precision beyond source.

## Test plan

- One item reused by many outfits appears once in packing.
- Outfit removal updates unique list without deleting closet/saved record.
- Overlapping trips and unavailable items produce actionable conflicts.
- Offline create/edit/check/uncheck then reconnect.
- Concurrent changes from two devices.
- Date/time-zone/daylight-saving boundaries.
- Distant-date/weather-provider fallback.
- Private destination/date authorization and telemetry redaction.
- Notification denial and lock-screen privacy.

## Exit criteria

- [ ] Multiple outfits and reuse produce a correct unique packing list.
- [ ] Offline packing changes survive relaunch and sync safely.
- [ ] Conflicts never silently lose user choices.
- [ ] Trip/destination/packing data remains owner-only.
- [ ] Weather source/freshness is visible.
- [ ] Notifications are optional and privacy-safe.
- [ ] Deleting a trip does not delete underlying closet/history data.
