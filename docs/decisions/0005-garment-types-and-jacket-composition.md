# ADR-0005 — Persist specific garment types and use one upper-body piece

**Status:** Accepted by product-owner request
**Date:** 2026-09-09
**Requirements:** ITEM-002–ITEM-003, ITEM-013–ITEM-018, CLO-004–CLO-005, CLO-010, COMP-001–COMP-002, COMP-005–COMP-013

## Context

The user requested selectable types such as shorts, long sleeve, and jacket with matching names and seasons. Detection already knew specific garment kinds, but saved records exposed only broad categories. A generated jacket also obscured a separately selected shirt, leaving shirt edges visible around the jacket. The user explicitly requested that a jacket replace that shirt in the generated outfit.

## Decision

Keep the six existing category values and persist an optional `GarmentKind` on closet items and immutable snapshots. Legacy records with no kind continue to decode with their original category. The local, bundled taxonomy supplies specific names and editable season/formality defaults, and the editor, import review, search, and filters expose it. Explicit type changes refresh defaults; a manually entered name remains unchanged. There is no remote taxonomy service.

For separates, select exactly one upper-body item: a top or outerwear, plus a bottom. In cold weather prefer available outerwear, subject to locks; otherwise prefer a top and allow outerwear as a fallback. All outerwear, including old generic jacket records, shares this slot. A locked top prevents an additional jacket. Simultaneous top and outerwear locks return a conflict. A one-piece may still have outerwear. Single-piece and full rerolls can exchange a top and jacket while preserving other locked pieces.

The canvas renders the actual selected pieces. It gives shoe pairs a larger aspect-fit frame and keeps their bounds inside the board. The lasso editor instructs users to outline each shoe separately using **Add another area**. Deleting a closet item from its hold menu requires the existing destructive confirmation and never rewrites past outfit snapshots.

## Consequences and validation

- Existing closet files load without a destructive migration; saved/worn history retains copied kind, name, and images after edits or deletion.
- This is a composition rule for the current product. Advanced underlayers and configurable layering remain future work.
- Test repeated randomized generation, conflicting/retained locks, replacements, jacket-only upper-body availability, old-record decoding, persistence/history, and import/delete UI journeys.
- No changes to network access, media visibility, services, or recurring cost.
