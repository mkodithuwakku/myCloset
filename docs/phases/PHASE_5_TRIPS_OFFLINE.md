# Phase 5 — Trips, Packing, and Local Offline Use

**Status:** Planned
**Primary SRS groups:** TRIP, WEA, OFF, NOTIF, REL
**Goal:** Help users plan multiple outfits and a reliable packing list entirely on-device.

## Entry criteria

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

## Local persistence behavior

- Persist active/upcoming trips and required closet references locally.
- Save packing toggles and outfit changes atomically.
- Preserve trip state across ordinary app termination and device restart.
- Provide schema migration and recoverable corruption behavior.
- Explain that there is no cross-device sync or cloud recovery.

## Weather behavior

- Forecast when date/provider horizon supports it.
- Seasonal norms clearly labelled for distant dates.
- User-entered context when destination is omitted.
- No implication of forecast precision beyond source.

## Test plan

- One item reused by many outfits appears once in packing.
- Outfit removal updates unique list without deleting closet/saved record.
- Overlapping trips and unavailable items produce actionable conflicts.
- Offline create/edit/check/uncheck and app relaunch.
- Persistence migration and interrupted-write recovery.
- Date/time-zone/daylight-saving boundaries.
- Distant-date/weather-provider fallback.
- Private destination/date local-storage and diagnostic-redaction review.
- Notification denial and lock-screen privacy.

## Exit criteria

- [ ] Multiple outfits and reuse produce a correct unique packing list.
- [ ] Offline packing changes survive relaunch safely.
- [ ] Conflicts never silently lose user choices.
- [ ] Trip/destination/packing data remains in the app container.
- [ ] Weather source/freshness is visible.
- [ ] Notifications are optional and privacy-safe.
- [ ] Deleting a trip does not delete underlying closet/history data.
