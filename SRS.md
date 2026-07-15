# myCloset Software Requirements Specification

> **Working title:** myCloset (provisional; trademark and App Store name availability have not been confirmed)
> **Document type:** Software Requirements Specification (SRS)
> **Document version:** 1.2
> **Status:** Product baseline
> **Target release:** Public iPhone App Store release
> **Prepared:** July 14, 2026
> **Primary platform:** iPhone, iOS 17 and later
> **Business model:** Free application; no subscriptions, advertising, or in-app purchases in the defined release

---

## 1. Document Control

### 1.1 Revision History

| Version | Date | Status | Description |
|---|---:|---|---|
| 1.0 | 2026-07-14 | Product baseline | Initial enterprise-level requirements based on confirmed product decisions |
| 1.1 | 2026-07-14 | Approved release amendment | First App Store release changed to local-only operation with no recurring service cost beyond the Apple Developer Program |
| 1.2 | 2026-07-14 | Approved roadmap amendment | CloudKit profiles and following approved as a gated post-release addition; launch navigation restores a truthful Coming Soon tab |

### 1.2 Approval Roles

The following roles should approve this specification before implementation begins:

| Role | Approval responsibility |
|---|---|
| Product Owner | Product scope, business rules, and release priorities |
| Engineering Lead | Architecture, feasibility, security, and delivery estimates |
| Design Lead | User experience, accessibility, and visual system |
| Privacy/Security Reviewer | Privacy, data handling, abuse controls, and legal readiness |
| Quality Assurance Lead | Testability, acceptance criteria, and release gates |

### 1.3 Requirement Language

The words **shall**, **should**, and **may** have specific meanings in this document:

- **Shall:** mandatory for the applicable release.
- **Should:** expected unless a documented product or technical decision defers it.
- **May:** optional or implementation-dependent.

### 1.4 Priority Definitions

| Priority | Meaning |
|---|---|
| P0 | Required for the first public App Store release, subject to the authoritative release-applicability matrix in Section 3.5 |
| P1 | Approved post-launch enhancement that must preserve the Apple-membership-only cash-cost target |
| P2 | Optional future opportunity requiring a new product, privacy, safety, or recurring-cost decision |

---

## 2. Purpose and Product Vision

### 2.1 Purpose

This SRS defines the functional, data, interface, security, privacy, operational, and quality requirements for myCloset, a native Swift iPhone application that digitizes a user's wardrobe and produces practical outfit recommendations.

The specification is intended to serve as a shared implementation contract for product management, design, iOS engineering, quality assurance, privacy, security, and App Store release work. CloudKit social requirements are an approved post-release roadmap item, not a dependency of the first public release.

### 2.2 Product Vision

myCloset helps users decide what to wear using clothing they already own. The application combines wardrobe metadata, detected clothing colors, local weather, season, occasion, desired formality, user-selected pieces, availability, and prior user feedback to recommend coherent outfits.

The intended experience is sleek, modern, comfortable, and charming. It should take inspiration from Airbnb's clarity, approachable spacing, photography-forward presentation, and friendly interaction patterns without copying Airbnb's protected visual assets, layouts, or trade dress.

### 2.3 Product Goals

The product shall:

1. Reduce the effort required to choose an outfit.
2. Recommend only combinations made from clothing the user has uploaded.
3. Adapt recommendations to weather, season, occasion, and formality.
4. Allow users to anchor an outfit around one or more locked pieces.
5. Learn from explicit local feedback without making opaque or unsafe decisions.
6. Keep each user's closet and photos on that device in the first release.
7. Allow users to document outfits they wore in private local history.
8. Help users save outfit ideas and plan clothing for trips locally.
9. Meet the quality, privacy, accessibility, and operational expectations of a public App Store application without a production backend.

### 2.4 Success Measures

The product team shall define numeric release targets before beta. The first release shall not add a paid analytics service or a third-party analytics SDK. Evaluation shall use automated tests, structured beta feedback, App Store Connect metrics available through the Apple Developer Program, and locally observable behavior sufficient to assess:

- onboarding completion rate;
- percentage of users who add at least five closet items;
- time from first launch to first generated outfit;
- recommendation acceptance, save, wear, reroll, and rejection rates;
- daily outfit engagement;
- seven-day and thirty-day retention;
- successful clothing-image processing rate;
- weather retrieval success and fallback frequency;
- crash-free sessions;
- outfit generation latency;
- trip-plan completion rate;

No measurement shall upload private closet contents or photos, and no measurement shall introduce advertising or a recurring paid service.

---

## 3. Scope

### 3.1 First Public Release Scope (P0)

The first public App Store release shall include:

- native iPhone application built with Swift and SwiftUI;
- account-free onboarding and local profile editing, including a profile picture;
- private on-device digital closet management;
- guided clothing photography with category-specific framing overlays;
- automatic garment cropping or background removal;
- automatic dominant and accent color detection;
- user confirmation and correction of detected metadata;
- weather-aware Outfit of the Day on the Home tab;
- occasion- and formality-aware outfit generation;
- piece locking, manual replacement, rerolling, and session exclusions;
- local recommendation feedback and preference learning;
- local saved outfits and a history of outfits the user confirmed as worn;
- local trip outfit planning and packing checklist support;
- local reset/deletion controls, help, privacy information, and support links;
- on-device outfit generation, image analysis, and persistence;
- a five-tab navigation model: Home, Closet, Generate, Following, and Profile;
- a non-interactive Following screen clearly labelled Coming Soon, with no fake profiles, posts, or network behavior;
- release testing, accessibility review, App Store metadata, and support readiness that do not require a paid runtime service.

### 3.2 Approved Post-Launch Scope (P1)

The following capabilities are approved roadmap additions but are not required for the first public release:

- CloudKit-backed public profiles using an app-specific handle and iCloud-scoped identity;
- follow and unfollow relationships plus a reverse-chronological Following feed;
- explicit publishing of detached generated-outfit compositions that reveal no live closet records;
- content filtering, reporting, blocking, public support/contact information, deletion, and manual moderation controls before social activation;
- continued exclusion of likes, reactions, comments, direct messages, and engagement ranking;
- preservation of the private local closet and on-device recommendation engine;
- an initial controlled-content model using generated outfit compositions and preset avatars; arbitrary public photographs require a later moderation/privacy approval;
- CloudKit usage within the storage and service allowance included with Apple Developer Program membership, with usage monitoring and a kill switch if terms or cost change;
- iPad-optimized interface;
- Apple Watch companion experience;
- optional calendar integration for planned outfits;
- wardrobe wear analytics and cost-per-wear;
- advanced wardrobe-gap insights;
- shared or collaborative trip packing;
- advanced travel weather alerts;
- multilingual localization beyond the launch language;
- on-device recommendation personalization models;
- import from supported retailer receipts or product catalogs.

The CloudKit social addition shall begin only after the first App Store release demonstrates interest and an accountable person accepts report-response and moderation duties. A conventional backend, Google authentication, private-closet synchronization, cloud AI, or paid hosted-media service remains unapproved.

### 3.3 Explicitly Out of Scope for the First Public Release

The following are not included in the first public release:

- Android, web, macOS, or visionOS clients;
- a production backend, hosted database, hosted media storage, or cross-device synchronization;
- Sign in with Apple, Google authentication, or any required user account;
- functioning following, public profiles, feeds, outfit posting, or other user-generated-content distribution beyond the Coming Soon screen;
- active reporting, blocking, or moderation operations while social publishing remains disabled;
- cloud-hosted AI or per-image/per-generation model APIs;
- any runtime service that creates a mandatory recurring charge beyond the Apple Developer Program;
- likes, reactions, comments, direct messages, or public popularity scores;
- public visibility of a user's closet or individual closet inventory;
- advertising, subscriptions, paid tiers, or in-app purchases;
- purchasing, resale, or marketplace functionality;
- virtual try-on or body-shape simulation;
- automatic duplicate-image detection as a launch requirement;
- guarantees that two differently named records represent different physical items;
- autonomous posting without explicit user confirmation;
- training face-recognition or identity models from user-uploaded photos.

### 3.4 Product Assumptions

This SRS uses the following confirmed or necessary assumptions:

1. The first release has no account, public profile, social graph, feed, or public post.
2. Closet, profile, history, trip, preference, and image data are stored only in the app's local container.
3. Uninstalling the app may remove local data; the product shall communicate that no cloud backup or cross-device recovery is provided.
4. Deterministic constraints and scoring form the recommendation core; optional intelligence shall run on-device and remain subordinate to validation.
5. When exact weather is unavailable, the system degrades to city weather, then date-derived season, then neutral recommendations.
6. Weather shall use an allowance included with the Apple Developer Program, a provider whose terms permit the free no-advertising app, or season-only behavior; it shall never require a paid runtime subscription.
7. The launch language is English, while the implementation remains localization-ready.
8. The product name remains provisional until legal and store-name checks are completed.
9. The Coming Soon tab is a roadmap preview only and shall not display fabricated social activity.
10. Post-release social identity shall use CloudKit/iCloud rather than a separately operated authentication backend unless a later decision supersedes ADR-0004.

### 3.5 Authoritative Release Applicability

This matrix overrides conflicting row-level priorities in the original full-product requirement catalogue. Requirements outside the first-release profile remain useful design material but are not App Store release gates.

| Requirement group | First public release | Approved later path |
|---|---|---|
| ITEM, CLO, WEA, HOME, GEN, COMP, REC, FB, HIST, A11Y, COMPAT, STORE | Included where behavior is local/on-device | Continue locally |
| ONB, PROF, TRIP, SET, PRIV, SEC, PERF, REL, OFF, ENG | Included for the local, account-free architecture | Extend only where the selected phase requires it |
| SOC, POST, SAFE and social portions of PROF/PRIV/SEC/STORE | Coming Soon presentation only; no functioning service | P1 CloudKit social after release, interest validation, and safety gates |
| AUTH, ADM and backend portions of ARCH/OBS/SCALE | Excluded | P2 unless a later decision proves CloudKit cannot meet an approved need |
| Cloud AI, paid hosted media, remote configuration, private-closet sync | Excluded | P2 and unfunded |

CloudKit social within the Apple Developer Program allowance is approved by ADR-0004. Any change that adds a separate recurring provider charge, conventional backend, cloud AI, or private-closet upload still requires an SRS revision and explicit product-owner approval before implementation.

---

## 4. Stakeholders and User Classes

### 4.1 Stakeholders

| Stakeholder | Primary interest |
|---|---|
| End users | Useful recommendations, privacy, simple wardrobe entry, attractive experience |
| Product Owner | Product-market fit, scope, adoption, and retention |
| Design team | Consistent, accessible, photography-forward experience |
| Engineering team | Feasible, secure, maintainable architecture |
| Quality and privacy reviewers | Release evidence, accessibility, local-data handling, and truthful disclosures |
| Support owner | User-facing help, issue response, and release communication without access to private app data |
| App Store review | Guideline compliance, privacy disclosures, local-data deletion, and accurate store metadata |

### 4.2 User Classes

#### Local User

A person using the app without an account who can maintain a private closet, generate outfits, save or record worn outfits, plan trips, edit a local profile, and clear their local data.

#### New or Low-Inventory User

A local user who has not uploaded enough compatible pieces to form a complete outfit. The app must provide helpful next steps rather than a broken or misleading recommendation.

#### User Without Location Permission

A local user who has denied or disabled location access. The app must support city entry and season-only fallback behavior.

#### Support Contact

A person responsible for answering product questions and receiving issue reports. Because no backend exists, support cannot inspect, retrieve, or repair a user's private closet or local history.

---

## 5. User Experience and Navigation

### 5.1 Primary Navigation

The application shall use a persistent, accessible tab-based navigation model with these primary destinations:

1. **Home** — Outfit of the Day, weather context, and quick actions.
2. **Closet** — private inventory, filters, item creation, and item editing.
3. **Generate** — occasion-based outfit generation, locking, rerolling, and saving.
4. **Following** — a launch-state Coming Soon screen; after the separately gated CloudKit social release, followed outfit inspiration and public-profile discovery.
5. **Profile** — local profile editing, worn outfits, saved outfits, trips, settings, privacy information, and local data controls.

Trips and outfit history may be presented as secondary destinations within Profile, provided they remain reachable within two deliberate navigation actions.

### 5.2 Design Principles

The interface shall:

- be visually calm, modern, warm, and photography-forward;
- use generous spacing, clear hierarchy, rounded surfaces, and restrained motion;
- avoid dense enterprise-dashboard styling in consumer-facing flows;
- use original branding and components rather than copying another company's design;
- support light and dark appearance unless a documented design decision explicitly defers dark mode;
- communicate why an outfit was recommended in plain language;
- place destructive actions behind clear confirmation;
- make empty, loading, offline, permission-denied, and error states useful and actionable;
- avoid using color as the only indicator of status or selection;
- meet the accessibility requirements in Section 13.

### 5.3 Core User Journeys

The application shall support these end-to-end journeys:

1. Create an optional local profile, configure weather preference, and add the first clothing item without signing in.
2. Photograph a garment, confirm extracted colors and metadata, and save it.
3. Open Home and receive a weather-aware Outfit of the Day.
4. Generate an outfit for a selected occasion and formality level.
5. Lock a desired shirt and generate a compatible remaining outfit.
6. Replace or reroll one unavailable piece without discarding the remaining outfit.
7. Save a generated outfit for later or confirm it as worn.
8. Create a trip, generate multiple trip outfits, and manage a packing checklist locally.
9. Clear local app data after explicit confirmation.
10. Open Following and receive an honest Coming Soon state without fabricated profiles or posts.

---

## 6. Functional Requirements

The Section 3.5 release-applicability matrix is normative. AUTH, ADM, conventional-backend, cloud-sync, and cloud-AI rows below remain P2 reference requirements. SOC, POST, SAFE, and public-profile rows are P1 requirements for the separately gated post-release CloudKit social addition even where their original row priority reads P0; none are gates for the first local-only App Store release.

### 6.1 Authentication and Account Lifecycle

| ID | Priority | Requirement |
|---|---|---|
| AUTH-001 | P0 | The system shall allow a user to authenticate using Sign in with Apple. |
| AUTH-002 | P0 | The system shall allow a user to authenticate using Google. |
| AUTH-003 | P0 | The system shall create one internal account per person and shall support secure identity linking when the same verified person uses both providers. |
| AUTH-004 | P0 | The system shall not expose a provider email, Apple private relay address, or internal identifier on the public profile. |
| AUTH-005 | P0 | Authentication tokens and secrets stored on the iPhone shall be protected using Keychain or an equivalent platform-secure mechanism. |
| AUTH-006 | P0 | The user shall remain signed in across normal application restarts until the session expires, is revoked, or the user signs out. |
| AUTH-007 | P0 | The user shall be able to sign out from the current device. |
| AUTH-008 | P0 | The user shall be able to view active sessions and revoke other sessions where supported by the backend architecture. |
| AUTH-009 | P0 | The user shall be able to initiate permanent account deletion from within the app. |
| AUTH-010 | P0 | Account deletion shall remove or irreversibly anonymize active-system personal data within 30 days, except data retained for legal, fraud-prevention, or security obligations described in the privacy policy. |
| AUTH-011 | P0 | Deleting an account shall remove its profile and posts from user-visible surfaces promptly after confirmation. |
| AUTH-012 | P0 | The system shall support a machine-readable export of the user's profile, closet metadata, outfit history, trips, posts, and stored images. |
| AUTH-013 | P0 | Failed, cancelled, and revoked authentication flows shall present recoverable error states without creating partial duplicate accounts. |
| AUTH-014 | P0 | Account deletion shall revoke applicable Sign in with Apple tokens and provider sessions in addition to deleting the internal account. |

### 6.2 Onboarding and Permissions

| ID | Priority | Requirement |
|---|---|---|
| ONB-001 | P0 | First-time users shall receive a concise explanation of the app's value and the data needed to provide recommendations. |
| ONB-002 | P0 | The app shall request each operating-system permission only when the related capability is first needed or when context has been clearly provided. |
| ONB-003 | P0 | Location, camera, and photo-library denials shall not prevent access to unrelated features. |
| ONB-004 | P0 | Onboarding shall allow the user to provide a unique handle, display name, optional profile photo, and optional short biography. |
| ONB-005 | P0 | The system shall validate handle format, prohibited terms, uniqueness, and moderation rules. |
| ONB-006 | P0 | The user shall be able to skip the profile photo, biography, location, and city steps. |
| ONB-007 | P0 | The app shall explain that a useful complete outfit requires a minimum set of compatible clothing categories and shall show progress toward that state. |
| ONB-008 | P0 | Onboarding state shall be resumable after an application restart or network interruption. |

### 6.3 Profile Management

| ID | Priority | Requirement |
|---|---|---|
| PROF-001 | P0 | A user shall be able to view and edit their display name, unique handle, biography, and profile picture. |
| PROF-002 | P0 | The system shall crop and resize profile pictures for consistent display while retaining an appropriate source rendition for future reprocessing. |
| PROF-003 | P0 | The public profile shall display the user's profile information, follower and following counts, and outfit posts. |
| PROF-004 | P0 | The public profile shall never display the user's private closet inventory, closet count, private saved outfits, private worn history, private feedback, or trip plans. |
| PROF-005 | P0 | Profile edits shall be validated and reflected consistently across the app. |
| PROF-006 | P0 | The user shall be able to remove or replace their profile picture. |
| PROF-007 | P0 | The system shall apply content-policy checks to profile pictures, handles, display names, and biographies. |
| PROF-008 | P1 | The user should be able to make the entire profile and post history follower-only, with follow-request approval. |

### 6.4 Social Following and Feed

| ID | Priority | Requirement |
|---|---|---|
| SOC-001 | P0 | An authenticated user shall be able to search for other users by handle or display name. |
| SOC-002 | P0 | An authenticated user shall be able to follow and unfollow another user. |
| SOC-003 | P0 | The system shall prevent a user from following themselves. |
| SOC-004 | P0 | The Following tab shall display outfit posts from accounts the user follows. |
| SOC-005 | P0 | Feed ordering shall be understandable and shall default to reverse chronological order for the first release. |
| SOC-006 | P0 | The feed shall support pagination and shall not expose deleted, moderated, or blocked content. |
| SOC-007 | P0 | A user shall be able to view follower and following lists, except relationships hidden due to blocking or enforcement. |
| SOC-008 | P0 | The system shall not provide likes, reactions, comments, direct messaging, or public engagement counts. |
| SOC-009 | P0 | Blocking a user shall remove the follow relationship in both directions and hide each account's profile and posts from the other. |
| SOC-010 | P0 | The system shall prevent blocked users from re-following or discovering one another through ordinary product surfaces. |
| SOC-011 | P0 | The system shall rate-limit user search and follow actions to reduce scraping and abuse. |

### 6.5 Closet Item Capture and Creation

| ID | Priority | Requirement |
|---|---|---|
| ITEM-001 | P0 | The user shall select a clothing category before taking or importing an item photo. |
| ITEM-002 | P0 | Supported top-level categories shall include tops, bottoms, dresses/one-piece outfits, outerwear, footwear, and accessories. |
| ITEM-003 | P0 | The category taxonomy shall support administratively managed subcategories without requiring an iOS release for every taxonomy update. |
| ITEM-004 | P0 | The camera shall present a category-appropriate framing outline or guidance overlay to help isolate the garment. |
| ITEM-005 | P0 | Capture guidance shall instruct the user to use a plain contrasting background, adequate lighting, and a fully visible garment. |
| ITEM-006 | P0 | The user shall be able to take a new photo or import an existing photo from the photo library. |
| ITEM-007 | P0 | The system shall attempt to segment the selected garment and remove or crop the background. |
| ITEM-008 | P0 | The user shall be able to adjust or approve the crop when automatic segmentation is uncertain or incorrect. |
| ITEM-009 | P0 | The system shall detect at least one dominant color and may detect one or more accent colors from the isolated garment. |
| ITEM-010 | P0 | Detected colors shall be mapped to a standardized human-readable color family and retain a machine-usable color representation. |
| ITEM-011 | P0 | The user shall be able to add, remove, or correct dominant and accent colors before saving. |
| ITEM-012 | P0 | The user shall enter an item name before saving. |
| ITEM-013 | P0 | If the normalized item name matches another active item name in the same closet, the app shall warn the user and identify the existing record. |
| ITEM-014 | P0 | A duplicate-name warning shall allow the user to revise the name or deliberately continue; it shall not silently merge records. |
| ITEM-015 | P0 | The user shall select one or more intended seasons: spring, summer, autumn/fall, winter, or all-season. |
| ITEM-016 | P0 | The user shall select one or more applicable formality contexts for the item. |
| ITEM-017 | P0 | Formality contexts shall include at minimum active/sport, very casual, casual, smart casual, business, and formal. |
| ITEM-018 | P0 | The user shall review and explicitly confirm the image, name, category, colors, seasons, and formality before the item is added to the closet. |
| ITEM-019 | P0 | If automated image processing fails, the user shall still be able to crop the image and enter colors manually. |
| ITEM-020 | P0 | Unsaved capture data shall be recoverable during an ordinary interruption where technically feasible and discarded after a documented expiry period. |
| ITEM-021 | P0 | The system shall display upload and processing progress and prevent accidental duplicate submissions caused by repeated taps. |
| ITEM-022 | P0 | The system shall strip unnecessary image metadata, including precise photo location, before storing a closet image. |

### 6.6 Closet Management

| ID | Priority | Requirement |
|---|---|---|
| CLO-001 | P0 | The Closet tab shall display only the authenticated user's items. |
| CLO-002 | P0 | The user shall be able to browse closet items in a photo-forward grid or list. |
| CLO-003 | P0 | The user shall be able to search closet items by name. |
| CLO-004 | P0 | The user shall be able to filter by category, subcategory, color, season, formality, favorite state, and availability. |
| CLO-005 | P0 | The user shall be able to edit all confirmed item metadata and replace the item image. |
| CLO-006 | P0 | The user shall be able to mark an item available, temporarily unavailable, in laundry, packed, or archived. |
| CLO-007 | P0 | The user shall be able to provide an optional availability-until date for a temporarily unavailable item. |
| CLO-008 | P0 | Items not currently available shall be excluded from new recommendations by default. |
| CLO-009 | P0 | The user shall be able to archive or permanently delete an item after confirmation. |
| CLO-010 | P0 | Deleting or editing an item shall not alter immutable snapshots attached to past worn outfits or posts. |
| CLO-011 | P0 | The user shall be able to favorite an item for preference weighting without requiring it in every outfit. |
| CLO-012 | P0 | Closet data and original item images shall not be visible through public profile, feed, search, or unauthenticated endpoints. |

### 6.7 Location, Weather, and Season Context

| ID | Priority | Requirement |
|---|---|---|
| WEA-001 | P0 | The app shall request current location only after explaining its use for weather-based recommendations. |
| WEA-002 | P0 | Approximate location shall be sufficient for weather lookup; the app shall not require continuous or background location. |
| WEA-003 | P0 | When location is granted, the system shall retrieve current and near-term weather applicable to the user's approximate location. |
| WEA-004 | P0 | Weather context shall include, where provided, temperature, apparent temperature, precipitation probability/type, wind, humidity, and severe-condition indicators. |
| WEA-005 | P0 | When location is unavailable or denied, the app shall offer manual city search and selection. |
| WEA-006 | P0 | The user shall be able to edit or remove the saved fallback city. |
| WEA-007 | P0 | If both location and city are unavailable, the system shall infer the local meteorological season from the device date and the device's hemisphere where reliably known. |
| WEA-008 | P0 | If hemisphere cannot be determined, the app shall ask the user to select a region or shall produce a season-neutral result and disclose the limitation. |
| WEA-009 | P0 | If weather data is stale or retrieval fails, the app shall show the last update time and use the documented fallback hierarchy. |
| WEA-010 | P0 | The fallback hierarchy shall be current-location weather, saved-city weather, date-derived season, then weather-neutral generation. |
| WEA-011 | P0 | The user shall be able to generate an outfit without enabling location or entering a city. |
| WEA-012 | P0 | Weather data shall be cached for a limited provider-compliant period to improve performance and resilience. |

### 6.8 Home and Outfit of the Day

| ID | Priority | Requirement |
|---|---|---|
| HOME-001 | P0 | The Home tab shall present a recommended Outfit of the Day when the closet contains a valid combination. |
| HOME-002 | P0 | The Outfit of the Day shall use current weather when available and shall otherwise follow the weather fallback hierarchy. |
| HOME-003 | P0 | The Home tab shall display the weather or season context used for the recommendation. |
| HOME-004 | P0 | The Home tab shall display the recommended pieces and a concise explanation of the principal matching factors. |
| HOME-005 | P0 | A daily recommendation shall be stable during the day unless inputs change or the user explicitly requests a new result. |
| HOME-006 | P0 | The user shall be able to lock a piece from the daily recommendation and reroll one or more other pieces. |
| HOME-007 | P0 | The user shall be able to save, confirm as worn, provide feedback on, or dismiss the daily recommendation. |
| HOME-008 | P0 | If no valid outfit exists, Home shall explain which clothing category or compatibility constraint is missing and provide a direct action to add or edit items. |
| HOME-009 | P0 | The app shall not claim that an outfit is weather-optimized when only season or neutral context was used. |
| HOME-010 | P0 | A weather change significant enough to affect safety or comfort shall allow the recommendation to refresh and shall notify the user within the active app experience. |

### 6.9 Outfit Generation Inputs

| ID | Priority | Requirement |
|---|---|---|
| GEN-001 | P0 | The Generate tab shall allow the user to generate an outfit independently from the daily recommendation. |
| GEN-002 | P0 | The user shall select an occasion preset or enter optional free-text context. |
| GEN-003 | P0 | Occasion presets shall include at minimum bar/night out, walk, sport/workout, work, school, date, dinner, party, wedding/formal event, travel, errands, and stay-at-home. |
| GEN-004 | P0 | Product administrators shall be able to update preset labels and rule mappings without invalidating saved historical outfits. |
| GEN-005 | P0 | The user shall select a desired casual-to-formal level through an accessible control. |
| GEN-006 | P0 | The formality control shall map to the internal formality contexts while allowing adjacent compatible levels when an exact match is unavailable. |
| GEN-007 | P0 | The user shall be able to specify whether current weather, selected destination weather, season only, or no weather context should apply. |
| GEN-008 | P0 | The user may provide free-text context such as “outdoor summer wedding,” subject to length, safety, and abuse controls. |
| GEN-009 | P0 | The system shall translate free text into structured recommendation constraints and show the interpreted occasion/formality when the interpretation materially affects the result. |
| GEN-010 | P0 | The system shall not use free-text context to generate public content or expose it to other users without explicit action. |

### 6.10 Outfit Composition, Locking, Replacement, and Rerolling

| ID | Priority | Requirement |
|---|---|---|
| COMP-001 | P0 | An outfit shall contain a structurally valid base: top plus bottom, or a one-piece garment, with footwear when appropriate. |
| COMP-002 | P0 | Outerwear and accessories shall be included when relevant to weather, occasion, or user preference but shall not be required for every outfit. |
| COMP-003 | P0 | The generator shall use only active items belonging to the authenticated user's closet. |
| COMP-004 | P0 | The generator shall exclude archived, deleted, in-laundry, packed-for-conflicting-trip, or unavailable items unless the user explicitly overrides the applicable state. |
| COMP-005 | P0 | The generator shall enforce the user's locked pieces as hard constraints. |
| COMP-006 | P0 | The user shall be able to lock multiple pieces if a valid outfit can be formed around them. |
| COMP-007 | P0 | When locked pieces conflict by structure, season, formality, weather safety, or explicit rule, the app shall identify the conflict and offer a corrective action rather than silently unlocking an item. |
| COMP-008 | P0 | The user shall be able to select an individual outfit slot and manually replace its item from compatible closet candidates. |
| COMP-009 | P0 | The user shall be able to reroll an individual unlocked piece while keeping the remaining outfit unchanged. |
| COMP-010 | P0 | The user shall be able to reroll all unlocked pieces while preserving locked pieces. |
| COMP-011 | P0 | The user shall be able to mark a suggested piece “not available now,” causing it to be excluded from the current generation session. |
| COMP-012 | P0 | The app shall offer to persist “not available now” as an item availability status, but shall not do so without user confirmation. |
| COMP-013 | P0 | A reroll shall avoid immediately repeating the rejected item when another valid candidate exists. |
| COMP-014 | P0 | If no alternative exists, the app shall explain the limiting constraints and allow the user to relax an editable constraint. |
| COMP-015 | P0 | Manually replacing a piece shall revalidate the complete outfit and visibly identify any resulting conflict. |
| COMP-016 | P0 | The user shall be able to return to the prior outfit state at least once after a reroll within the active session. |
| COMP-017 | P0 | The generated result shall state which context was applied: weather, season, occasion, formality, locked pieces, and notable color relationship. |

### 6.11 Recommendation Engine

| ID | Priority | Requirement |
|---|---|---|
| REC-001 | P0 | Recommendation generation shall separate hard constraints from soft preference scoring. |
| REC-002 | P0 | Hard constraints shall include closet ownership, item availability, valid outfit structure, locked pieces, and explicit trip restrictions. |
| REC-003 | P0 | Weather safety rules shall be hard constraints when conditions pose a foreseeable comfort or safety concern; ordinary temperature preferences may be soft constraints. |
| REC-004 | P0 | Soft scoring shall consider color compatibility, season, formality, occasion, current weather, user favorites, wear recency, prior feedback, and outfit variety. |
| REC-005 | P0 | Color scoring shall use the confirmed dominant and accent color metadata, not uncontrolled inference from the original background. |
| REC-006 | P0 | The engine shall support complementary, analogous, monochromatic, neutral, and contrast-based color relationships without treating any one scheme as universally superior. |
| REC-007 | P0 | The engine shall not make sensitive personal inferences about body type, ethnicity, religion, gender identity, health, or socioeconomic status. |
| REC-008 | P0 | The engine shall produce a machine-readable reason set sufficient to explain the main recommendation factors. |
| REC-009 | P0 | Cloud model output shall not be allowed to bypass deterministic privacy, ownership, availability, or outfit-structure validation. |
| REC-010 | P0 | Cloud model failure shall degrade to deterministic generation when a valid rules-based outfit is possible. |
| REC-011 | P0 | The engine shall never fabricate a closet item that the user does not own. |
| REC-012 | P0 | Recommendation results shall be reproducible for debugging from versioned inputs, rule version, model version, and a non-sensitive request identifier. |
| REC-013 | P0 | Rule and model releases shall be versioned, tested, monitored, and capable of rollback. |
| REC-014 | P0 | Personalization shall use the authenticated user's own feedback and behavior and shall not reveal another user's private data. |
| REC-015 | P0 | The system shall support a non-personalized baseline for new users. |
| REC-016 | P0 | The engine shall prioritize a complete honest failure explanation over a low-confidence invalid outfit. |

### 6.12 Outfit Feedback and Personalization

| ID | Priority | Requirement |
|---|---|---|
| FB-001 | P0 | The user shall be able to accept, reject, save, or confirm a generated outfit as worn. |
| FB-002 | P0 | The user shall be able to provide quick feedback such as “love it,” “not my style,” “too warm,” “too cold,” “too casual,” “too formal,” or “colors do not work for me.” |
| FB-003 | P0 | Feedback shall be private and associated with the recommendation context and engine version. |
| FB-004 | P0 | The engine shall use feedback as preference evidence without overriding future explicit constraints. |
| FB-005 | P0 | A single feedback event shall not permanently eliminate an item or color combination unless the user explicitly creates such a preference. |
| FB-006 | P0 | The user shall be able to correct or remove saved preference signals through settings or relevant item/outfit history. |
| FB-007 | P0 | The system shall distinguish outfit rejection from an unavailable-item reroll. |

### 6.13 Saved Outfits and Worn-Outfit History

| ID | Priority | Requirement |
|---|---|---|
| HIST-001 | P0 | The user shall be able to save a generated outfit for later without marking it as worn. |
| HIST-002 | P0 | The user shall be able to confirm an outfit as worn and select or edit the wear date. |
| HIST-003 | P0 | Saved and worn outfits shall store immutable snapshots of piece names, categories, colors, and images at the time of saving. |
| HIST-004 | P0 | The user shall be able to view separate Saved Outfits and Worn Outfits collections. |
| HIST-005 | P0 | The user shall be able to search or filter worn outfits by date, occasion, formality, season, and included item. |
| HIST-006 | P0 | The user shall be able to remove an outfit from Saved without deleting a corresponding worn record or public post. |
| HIST-007 | P0 | The user shall be able to edit the private note, occasion, and wear date of a worn record. |
| HIST-008 | P0 | Worn history and saved outfits shall remain private unless the user explicitly creates an outfit post. |
| HIST-009 | P0 | The system shall prevent accidental duplicate worn confirmations caused by repeated submission. |

### 6.14 Outfit Posts

| ID | Priority | Requirement |
|---|---|---|
| POST-001 | P0 | A user shall be able to create a post from an outfit they have confirmed as worn. |
| POST-002 | P0 | A post shall include a user-selected photo and an outfit snapshot showing the associated pieces. |
| POST-003 | P0 | The user shall be able to take the post photo in the app or select it from the photo library. |
| POST-004 | P0 | The user may add an optional caption, subject to length and content-policy limits. |
| POST-005 | P0 | Before publishing, the app shall show a preview of exactly what other users will see. |
| POST-006 | P0 | Publishing shall require an explicit confirmation and shall never occur automatically after marking an outfit worn. |
| POST-007 | P0 | A published outfit snapshot shall expose only the selected historical piece images and presentation metadata, not closet endpoints, availability, private notes, or the complete closet. |
| POST-008 | P0 | The author shall be able to edit a caption and delete the post. |
| POST-009 | P0 | Deleting a post shall not delete the author's private worn-outfit record unless separately requested. |
| POST-010 | P0 | Posts shall be visible on the author's profile and eligible for the feeds of followers, subject to blocking and moderation. |
| POST-011 | P0 | The system shall remove unnecessary EXIF data, including precise photo location, from post images before distribution. |
| POST-012 | P0 | The system shall provide reporting and moderation controls on every post and public profile. |
| POST-013 | P0 | The system shall not display likes, reactions, comments, or engagement rankings. |

### 6.15 Trip Planning and Packing

| ID | Priority | Requirement |
|---|---|---|
| TRIP-001 | P0 | The user shall be able to create a trip with a name, destination or region, start date, and end date. |
| TRIP-002 | P0 | Destination may be omitted; when omitted, the user shall be able to use season-only or manually supplied weather context. |
| TRIP-003 | P0 | When destination and dates are available, the system shall attempt to use destination forecast or seasonal norms and shall disclose which source was used. |
| TRIP-004 | P0 | The user shall be able to define trip occasions and desired formality needs. |
| TRIP-005 | P0 | The user shall be able to generate and save multiple outfits within a trip. |
| TRIP-006 | P0 | Trip generation shall allow intentional reuse of clothing across multiple outfits. |
| TRIP-007 | P0 | The trip planner shall show the unique closet items needed across all selected outfits. |
| TRIP-008 | P0 | The user shall be able to add an existing saved outfit or build an outfit manually within a trip. |
| TRIP-009 | P0 | The user shall be able to mark each unique item packed or unpacked. |
| TRIP-010 | P0 | The planner shall identify a conflict when the same physical item is assigned to overlapping trips or is otherwise unavailable. |
| TRIP-011 | P0 | Removing an outfit from a trip shall not delete the underlying closet items or unrelated saved/worn records. |
| TRIP-012 | P0 | Trip plans, destinations, dates, outfits, and packing state shall remain private. |
| TRIP-013 | P0 | The system shall allow trip use when a weather provider has no forecast for distant dates by falling back to season and user-entered context. |
| TRIP-014 | P0 | The user shall be able to delete a trip and its trip-specific assignments after confirmation. |

### 6.16 Notifications

| ID | Priority | Requirement |
|---|---|---|
| NOTIF-001 | P0 | Push notification permission shall be optional and requested only after the app explains a relevant benefit. |
| NOTIF-002 | P0 | The user shall be able to control notification categories independently. |
| NOTIF-003 | P0 | Supported categories may include daily outfit readiness, significant weather-driven outfit changes, new followers, and upcoming trip packing reminders. |
| NOTIF-004 | P0 | Notification content shall not reveal private closet, trip, or location details on the lock screen beyond the user's chosen privacy setting. |
| NOTIF-005 | P0 | The core app shall remain usable when notifications are denied. |

### 6.17 Reporting, Blocking, and Moderation

| ID | Priority | Requirement |
|---|---|---|
| SAFE-001 | P0 | Users shall be able to report a profile or post using a defined reason and optional explanatory text. |
| SAFE-002 | P0 | Report reasons shall include nudity/sexual content, harassment, hate, violence, self-harm concern, impersonation, spam, intellectual-property concern, and other. |
| SAFE-003 | P0 | Users shall be able to block another user from profile, post, follower list, and settings surfaces. |
| SAFE-004 | P0 | The system shall acknowledge reports without revealing enforcement details or the reporter's identity to the reported user. |
| SAFE-005 | P0 | Automated screening may hold apparently severe content for review, but enforcement rules and appeals shall remain documented and auditable. |
| SAFE-006 | P0 | Authorized moderators shall be able to review reports, view the reported content and necessary context, record decisions, and apply proportionate actions. |
| SAFE-007 | P0 | Moderator actions shall include no action, content removal, warning, temporary restriction, suspension, and permanent account removal. |
| SAFE-008 | P0 | All moderator access and enforcement actions shall be written to a tamper-evident audit log. |
| SAFE-009 | P0 | The product shall publish community guidelines, reporting instructions, and a support contact. |
| SAFE-010 | P0 | The system shall provide an appeal or support path for significant enforcement actions. |
| SAFE-011 | P0 | Moderation tooling shall apply least-privilege access and shall not expose unrelated private closet or trip data. |

### 6.18 Settings, Help, and Legal

| ID | Priority | Requirement |
|---|---|---|
| SET-001 | P0 | Settings shall provide profile, location/city, notification, privacy, blocked-user, data export, sign-out, and account-deletion controls. |
| SET-002 | P0 | The app shall provide accessible links to the current Privacy Policy, Terms of Use, Community Guidelines, support contact, and acknowledgements. |
| SET-003 | P0 | The app shall display an application version and build number for support. |
| SET-004 | P0 | The app shall provide contextual help for garment capture, color correction, recommendation explanations, and trip planning. |
| SET-005 | P0 | Legal acceptance records shall store the applicable document version and timestamp. |

### 6.19 Administrative and Operational Capabilities

| ID | Priority | Requirement |
|---|---|---|
| ADM-001 | P0 | Authorized operators shall be able to manage clothing taxonomy, occasion presets, formality mappings, compatibility rules, and feature flags through authenticated administrative controls. |
| ADM-002 | P0 | Administrative changes shall be validated, versioned, audited, and reversible. |
| ADM-003 | P0 | Operators shall be able to view service health, integration status, processing queues, error rates, and model/rule versions without unrestricted access to user content. |
| ADM-004 | P0 | Sensitive support access shall require a documented reason, elevated authorization, time-limited access where feasible, and audit logging. |
| ADM-005 | P0 | The system shall support safe feature rollout by environment, app version, and percentage cohort without using sensitive attributes. |
| ADM-006 | P0 | Production and non-production data and credentials shall be isolated. |

---

## 7. Business Rules

### 7.1 Closet Privacy Rules

1. A closet is private regardless of whether the user's profile or posts are visible.
2. A follow relationship does not grant closet access.
3. A public outfit post contains a detached snapshot, not a public link to the live closet record.
4. Past snapshots remain historically consistent after a closet item is edited.
5. Deleting an account removes both public snapshots and private records according to the retention policy.

### 7.2 Outfit Structure Rules

A structurally complete outfit normally consists of:

- either one top and one bottom, or one dress/one-piece item;
- footwear when the occasion conventionally requires it;
- zero or more outerwear items;
- zero or more accessories.

The rule system may vary by occasion, culture-neutral user preference, and product configuration. It shall not assume that clothing categories imply a user's gender.

### 7.3 Constraint Precedence

When constraints conflict, the engine shall apply them in this order:

1. ownership, authorization, deletion, and privacy;
2. item availability and structural validity;
3. locked-item requirements;
4. severe weather safety and explicit user exclusions;
5. trip assignment constraints;
6. occasion and selected formality;
7. season and ordinary weather comfort;
8. color compatibility;
9. learned preferences, favorites, recency, and variety.

The app shall ask the user before relaxing a hard constraint. It may relax soft constraints if it clearly explains the compromise.

### 7.4 Color Representation

Each closet item shall support:

- one or more dominant colors;
- zero or more accent colors;
- standardized color-family identifiers;
- a machine-readable color value such as CIELAB and/or sRGB;
- confidence for system-detected colors;
- source state: detected, user-corrected, or user-entered.

User-corrected values shall take precedence over detected values.

### 7.5 Name Collision Rule

Normalized comparison shall at minimum ignore leading/trailing whitespace, repeated internal whitespace, and letter case. A matching normalized name produces a warning, not a hard rejection. Image-based or semantic duplicate detection is outside the launch commitment.

### 7.6 Weather Fallback Rule

The system shall apply weather context in this order:

1. fresh weather for approximate current location;
2. fresh weather for a saved or session-selected city;
3. recently cached provider-compliant weather with a visible age;
4. date- and hemisphere-derived season;
5. weather-neutral generation.

The interface and recommendation explanation shall identify which level was used.

### 7.7 Free-App Rule

All functionality defined as P0 shall be available without payment. No dark patterns, artificial feature locks, advertising profiles, subscription prompts, or paid ranking shall be introduced without a new approved product and privacy specification.

### 7.8 Zero-Backend Cost Rule

| ID | Priority | Requirement |
|---|---|---|
| COST-001 | P0 | The first public release shall operate without a production backend or paid runtime service. |
| COST-002 | P0 | Mandatory recurring cash cost shall be limited to the Apple Developer Program membership. |
| COST-003 | P0 | Outfit generation, clothing-type detection, color analysis, feedback processing, and persistence shall execute on-device. |
| COST-004 | P0 | The app shall remain useful using date-derived season when weather quota, permission, or connectivity is unavailable. |
| COST-005 | P0 | Private user photos and wardrobe data shall not be uploaded to a developer-operated service. |
| COST-006 | P0 | A feature that introduces authentication, hosted storage, cloud AI, public content, or another recurring charge shall require a new approved SRS revision before implementation. |

---

## 8. Data Requirements

### 8.1 Core Entities

For the first release, only local `UserProfile`, `UserPreference`, `ClosetItem`, garment image, outfit, snapshot, feedback, worn history, trip, trip outfit, and packing entities apply. Social profile, follow, post, block, report, and social-deletion entities are P1 Phase 7 designs. Conventional account, consent-service, and centralized audit entities remain P2 references.

| Entity | Purpose | Representative fields |
|---|---|---|
| UserAccount | Authentication and lifecycle | internal ID, status, provider links, created time, deletion state |
| UserProfile | Public identity | handle, display name, bio, profile image, moderation status |
| UserPreference | Private recommendation settings | location mode, city, notification settings, preference signals |
| FollowRelationship | Social graph | follower ID, followed ID, created time |
| BlockRelationship | Safety boundary | blocker ID, blocked ID, created time |
| ClosetItem | Private wardrobe record | owner, name, category, image, colors, seasons, formalities, availability |
| ClosetItemImage | Private processed media | renditions, segmentation mask, processing state, metadata |
| Outfit | Saved recommendation or manual combination | owner, context, pieces, engine version, created time |
| OutfitItemSnapshot | Historical piece representation | source item ID if retained, name, category, colors, image rendition |
| RecommendationEvent | Recommendation trace | input context, constraints, score summary, rule/model version |
| OutfitFeedback | Private user response | outfit/recommendation reference, feedback types, timestamp |
| WornOutfit | Private history | outfit snapshot, wear date, occasion, private note |
| OutfitPost | Public user-generated content | author, worn-outfit snapshot reference, photo, caption, status |
| Trip | Private travel plan | owner, name, destination, dates, context, state |
| TripOutfit | Outfit assigned to a trip | trip, outfit snapshot, intended date/occasion |
| PackingItem | Unique trip item state | trip, closet item, packed flag, conflict state |
| Report | Safety report | reporter, target, reason, status, timestamps |
| ModerationAction | Enforcement record | actor, target, action, rationale, timestamps |
| ConsentRecord | Legal evidence | user, policy/permission type, version, timestamp |
| AuditEvent | Security/administration trace | actor, action, target type, result, timestamp |

### 8.2 Data Ownership and Isolation

For the first release, all applicable data classes are owner-local in the iOS app container and are not served to another user or developer-operated backend. The service visibility rows below apply only to a future approved cloud/social architecture.

| Data class | Default visibility |
|---|---|
| Account identifiers | Service-only |
| Closet items and images | Owner-only plus narrowly authorized processing services |
| Saved and worn outfit history | Owner-only |
| Feedback and learned preferences | Owner-only plus recommendation processing |
| Trips, destinations, dates, packing state | Owner-only |
| Profile fields | Authenticated users, subject to block/moderation |
| Outfit posts and selected post images | Authenticated users, subject to block/moderation |
| Reports and moderation notes | Authorized trust-and-safety personnel only |
| Security and audit logs | Authorized operational/security personnel only |

Backend authorization shall enforce these boundaries independently of the iOS interface.

### 8.3 Data Validation

The system shall:

- validate all client-supplied identifiers against the authenticated user;
- enforce server-side length, format, enum, and relationship constraints;
- use idempotency for item upload, worn confirmation, post publishing, follows, and account deletion;
- reject unsupported or malicious file formats;
- scan uploaded media for malware or malformed payloads;
- validate image dimensions and file size before processing;
- preserve referential integrity or use documented soft-deletion semantics;
- record data schema and recommendation rule versions where required for historical interpretation.

### 8.4 Retention and Deletion

1. Active closet, profile, outfit, post, and trip data shall remain until the user deletes the applicable record or account.
2. Deleted user-visible content shall be removed from ordinary serving paths promptly.
3. Soft-deleted operational records shall be purged or anonymized according to an approved retention schedule.
4. Account deletion shall complete within 30 days for active systems.
5. Encrypted backup copies may persist for up to 35 additional days and shall not be restored into active use except for disaster recovery.
6. Security, fraud, moderation, and legal records may use a separately documented retention period with data minimization.
7. Media derivatives and CDN copies shall be invalidated when their source record is deleted.

### 8.5 Data Portability

Exports shall use commonly readable formats such as JSON and original or standard image formats. The export shall explain that public post snapshots and private closet records are separate data objects.

---

## 9. External Interfaces and Integrations

### 9.1 iOS Platform Interfaces

The application may integrate with:

- SwiftUI for interface construction;
- Core Location for approximate foreground location;
- AVFoundation or system camera interfaces for guided capture;
- PhotosUI for privacy-preserving photo selection;
- Vision/Core ML and related Apple frameworks for on-device segmentation or analysis;
- WeatherKit when live weather is enabled within the Apple Developer Program allowance.

### 9.2 Google Authentication

Google authentication is P2 and is not included in the approved release. If reconsidered, it shall require a backend/security design and a new recurring-cost decision before implementation.

### 9.3 Weather Provider

The release should use WeatherKit within the allowance included with Apple Developer Program membership. A no-charge provider may be used only while its licence explicitly permits this free, no-advertising application. Date-derived season and neutral generation shall remain available so a quota or provider failure never creates a mandatory paid subscription.

### 9.4 Image Processing and Cloud Intelligence

Garment analysis, color extraction, segmentation, ranking, and explanations shall run on-device for the first release. Cloud AI is P2, shall not be a hidden dependency or fallback, and requires a new approved SRS revision before any user content is transmitted.

### 9.5 Media Storage and Delivery

Closet and profile media shall remain inside the iOS app container in the first release. No developer-operated object storage, CDN, or public media URL is required. Future hosted-media requirements are P2.

### 9.6 Backend API

The first release shall not communicate with a myCloset backend API. All core product operations shall be implemented in the native client. Any future API is P2 and requires explicit recurring-cost, privacy, security, migration, and operations approval.

---

## 10. Reference System Architecture

The first-release architecture is a self-contained native iPhone application. The earlier distributed architecture remains optional P2 reference material and is not a release dependency.

### 10.1 Logical Components

1. **Native iOS client** — SwiftUI presentation, local profile/closet/history/trip state, capture guidance, and on-device analysis.
2. **Local persistence** — versioned Codable or equivalent local storage in the app container, with migration and corruption handling.
3. **Outfit engine** — deterministic constraint evaluation, candidate construction, scoring, explanations, feedback, and versioning.
4. **Image pipeline** — local decoding, validation, resizing, segmentation, color extraction, and editable results.
5. **Weather adapter** — optional Apple-included/no-charge current conditions with date-derived season and neutral fallback.

Identity, API, hosted storage, social, moderation, centralized analytics, and remote-administration components are deliberately absent from the first release. Phase 7 may add only the CloudKit social repository and safety boundaries approved by ADR-0004; conventional service components remain P2.

### 10.2 Architectural Requirements

| ID | Priority | Requirement |
|---|---|---|
| ARCH-001 | P0 | Authorization shall be enforced server-side for every protected resource. |
| ARCH-002 | P0 | Media processing shall be asynchronous where processing time could block a responsive client request. |
| ARCH-003 | P0 | The system shall use idempotent job and API designs for retryable operations. |
| ARCH-004 | P0 | Public post media and private closet media shall use separate access policies. |
| ARCH-005 | P0 | Recommendation rules, taxonomy, and model versions shall be independently deployable or configurable. |
| ARCH-006 | P0 | External providers shall be accessed through internal adapters to limit vendor lock-in and support fallback. |
| ARCH-007 | P0 | Client compatibility shall be maintained for at least the current and immediately prior supported App Store version, unless a critical security issue requires a forced upgrade. |
| ARCH-008 | P0 | Schema changes shall support backward-compatible, staged deployment and rollback. |
| ARCH-009 | P0 | Production services shall use infrastructure-as-code and repeatable environment configuration. |
| ARCH-010 | P0 | Feature flags shall fail to a safe documented state and shall not bypass privacy or authorization requirements. |

---

## 11. Security Requirements

| ID | Priority | Requirement |
|---|---|---|
| SEC-001 | P0 | All network traffic shall use HTTPS with TLS 1.2 or later; modern TLS 1.3 shall be preferred. |
| SEC-002 | P0 | Sensitive data shall be encrypted at rest using managed keys with documented rotation and access controls. |
| SEC-003 | P0 | Authentication tokens shall be short-lived where practical, revocable, scoped, and never written to analytics or ordinary logs. |
| SEC-004 | P0 | The backend shall validate Apple and Google tokens directly against trusted issuer keys and claims. |
| SEC-005 | P0 | API authorization shall prevent insecure direct-object references, including guessed closet item, outfit, trip, post-draft, and export identifiers. |
| SEC-006 | P0 | Upload endpoints shall validate content type from file contents, impose size limits, scan files, and isolate processing. |
| SEC-007 | P0 | Administrative and moderation access shall require multi-factor authentication and role-based access control. |
| SEC-008 | P0 | Secrets shall be stored in an approved secrets manager and shall not be committed to source control or shipped in the client. |
| SEC-009 | P0 | The system shall implement rate limits and abuse detection for authentication, search, follows, uploads, generation, reports, and exports. |
| SEC-010 | P0 | Security-relevant actions shall generate centralized, access-controlled audit events. |
| SEC-011 | P0 | Logs shall redact tokens, provider credentials, precise location, raw free text where unnecessary, and private media URLs. |
| SEC-012 | P0 | Production dependencies shall undergo automated vulnerability and license scanning. |
| SEC-013 | P0 | The iOS and backend implementations shall be assessed against applicable OWASP MASVS and ASVS controls before release. |
| SEC-014 | P0 | Critical and high-severity vulnerabilities shall block release unless a documented risk owner approves a time-bounded exception. |
| SEC-015 | P0 | The organization shall maintain an incident-response plan covering account compromise, media exposure, provider compromise, moderation emergency, and data loss. |
| SEC-016 | P0 | A security contact and vulnerability-reporting process shall be publicly available. |
| SEC-017 | P0 | Production backups shall be encrypted, access-controlled, periodically restored in a test environment, and covered by deletion procedures. |
| SEC-018 | P0 | Sensitive local cache data shall use iOS data protection and shall be removed on sign-out when no longer needed. |
| SEC-019 | P0 | Clipboard, screenshots, and system logs shall not be used to transfer or persist authentication secrets. |
| SEC-020 | P0 | The threat model shall be reviewed before beta and after material changes to authentication, media, social, AI, or administrative capabilities. |

---

## 12. Privacy and Responsible AI Requirements

| ID | Priority | Requirement |
|---|---|---|
| PRIV-001 | P0 | The product shall collect only data required for declared functionality, safety, security, support, or consented analytics. |
| PRIV-002 | P0 | The Privacy Policy and App Store privacy disclosures shall accurately describe account, profile, image, closet, location, social, trip, diagnostics, and analytics data handling. |
| PRIV-003 | P0 | The app shall not require precise or background location. |
| PRIV-004 | P0 | Location shall be used for requested weather context and shall not be publicly displayed or used for advertising. |
| PRIV-005 | P0 | Private closet and trip images/data shall not be used to train internal or third-party generalized models without separate, explicit, revocable consent. |
| PRIV-006 | P0 | Post photos containing people shall not be used for face recognition, identity verification, or biometric profiling. |
| PRIV-007 | P0 | The system shall remove precise photo geolocation metadata before storage or distribution unless there is a documented private feature requiring it; no such feature is in P0 scope. |
| PRIV-008 | P0 | The user shall be able to understand whether a result used location weather, city weather, season, or neutral context. |
| PRIV-009 | P0 | Recommendation explanations shall be concise and shall not imply certainty beyond available inputs. |
| PRIV-010 | P0 | Automated decisions shall not infer or optimize on protected or sensitive traits. |
| PRIV-011 | P0 | Analytics identifiers shall be pseudonymous, access-controlled, and separated from public profile identifiers where practical. |
| PRIV-012 | P0 | Non-essential analytics shall follow applicable consent and opt-out requirements in launch jurisdictions. |
| PRIV-013 | P0 | Third-party SDKs shall undergo privacy review and shall be limited to the minimum required set. |
| PRIV-014 | P0 | The app shall provide clear controls to export and delete personal data. |
| PRIV-015 | P0 | Privacy-impact and AI-risk assessments shall be completed before public release and revisited after material changes. |
| PRIV-016 | P0 | Before sending personal data to a third-party AI service, the app shall clearly identify the data and recipient, explain the purpose, and obtain explicit user permission where required by Apple policy or applicable law. |

---

## 13. Accessibility and Inclusive Design

| ID | Priority | Requirement |
|---|---|---|
| A11Y-001 | P0 | The application shall target WCAG 2.2 Level AA principles as applicable to native mobile interfaces. |
| A11Y-002 | P0 | All interactive elements shall have meaningful accessibility labels, traits, values, and logical focus order. |
| A11Y-003 | P0 | The app shall support Dynamic Type without clipping, overlap, or loss of essential actions at accessibility text sizes. |
| A11Y-004 | P0 | The app shall support VoiceOver for onboarding, closet capture, outfit composition, locking, rerolling, packing, feed, and settings. |
| A11Y-005 | P0 | Color names and patterns shall be available as text; color shall not be the only way to understand compatibility or status. |
| A11Y-006 | P0 | Controls shall meet Apple's recommended target sizes and support alternatives to complex gestures. |
| A11Y-007 | P0 | Text and essential graphical elements shall meet applicable contrast targets in light and dark appearance. |
| A11Y-008 | P0 | Motion shall respect Reduce Motion, and flashing or rapid animation shall not be used. |
| A11Y-009 | P0 | Guided camera outlines shall include spoken and text guidance; successful capture shall not depend solely on seeing the outline. |
| A11Y-010 | P0 | User-posted images shall support optional author-provided alternative text; the app may suggest editable alt text. |
| A11Y-011 | P0 | Accessibility shall be covered by automated checks and manual testing with assistive technologies before release. |
| A11Y-012 | P0 | Product language shall avoid gendered clothing assumptions unless a user explicitly supplies a preference. |

---

## 14. Performance, Reliability, and Scalability

### 14.1 Performance Targets

Targets apply under documented representative network and device conditions.

| ID | Priority | Requirement |
|---|---|---|
| PERF-001 | P0 | The app shall reach usable Home content within 3 seconds at the 95th percentile on supported devices after a normal authenticated cold launch, excluding first-time migration. |
| PERF-002 | P0 | Cached closet browsing and saved/worn history shall respond to ordinary interactions within 300 ms at the 95th percentile. |
| PERF-003 | P0 | An outfit generation request shall return a valid result or actionable failure within 3 seconds at the 95th percentile when deterministic generation is sufficient and within 6 seconds when cloud assistance is required. |
| PERF-004 | P0 | The UI shall acknowledge taps and state changes within 100 ms where no remote response is required. |
| PERF-005 | P0 | A supported garment image shall normally upload and enter processing within 10 seconds at the 95th percentile on a stable 10 Mbps upstream connection. |
| PERF-006 | P0 | Feed and closet pagination shall avoid loading an unbounded data set into memory. |
| PERF-007 | P0 | Image renditions shall be sized appropriately for the display surface to control memory, latency, and bandwidth. |

### 14.2 Reliability Targets

| ID | Priority | Requirement |
|---|---|---|
| REL-001 | P0 | Production backend availability shall target 99.9% per calendar month, excluding announced maintenance. |
| REL-002 | P0 | Crash-free user sessions shall be at least 99.8% for the public release cohort. |
| REL-003 | P0 | The service shall define recovery point and recovery time objectives no worse than 24 hours and 4 hours respectively for a launch-stage production system, with tighter targets considered as usage grows. |
| REL-004 | P0 | Retryable operations shall use bounded retries with jitter and idempotency. |
| REL-005 | P0 | A weather, image-intelligence, notification, or cloud-ranking outage shall not prevent access to already stored closet and outfit data. |
| REL-006 | P0 | Failed asynchronous processing shall enter a visible retryable state and shall not remain indefinitely “processing.” |
| REL-007 | P0 | The application shall preserve completed local edits across temporary network loss and synchronize safely when connectivity returns. |
| REL-008 | P0 | The system shall monitor storage, database, queue, external-provider, API, authentication, and recommendation health. |

### 14.3 Scalability

| ID | Priority | Requirement |
|---|---|---|
| SCALE-001 | P0 | The architecture shall support horizontal scaling of stateless API and processing workloads. |
| SCALE-002 | P0 | The initial production design shall be load-tested for at least 100,000 monthly active users and 10,000 concurrently active sessions, or a revised approved launch forecast with a minimum 3x headroom. |
| SCALE-003 | P0 | Feed, follower, outfit-history, closet, and report queries shall use bounded pagination and indexed access patterns. |
| SCALE-004 | P0 | Media storage and delivery shall not require routing all image bytes through application servers. |
| SCALE-005 | P0 | Provider quotas and cloud costs shall have alerts, budgets, and graceful-degradation controls. |

---

## 15. Offline and Degraded Operation

| ID | Priority | Requirement |
|---|---|---|
| OFF-001 | P0 | The user shall be able to view recently cached closet items, saved outfits, worn outfits, and active trip packing lists while offline. |
| OFF-002 | P0 | The app shall clearly distinguish cached data from current server state. |
| OFF-003 | P0 | Safe local actions such as packing checkmarks may be queued for synchronization with conflict handling. |
| OFF-004 | P0 | Publishing posts, following users, account deletion, and cloud-required image processing shall require connectivity and shall fail with a recoverable message. |
| OFF-005 | P0 | Deterministic outfit generation may operate from a complete local cache; otherwise the app shall explain why generation requires connectivity. |
| OFF-006 | P0 | Offline queues shall not persist operations after sign-out or account deletion. |

---

## 16. Observability, Analytics, and Supportability

| ID | Priority | Requirement |
|---|---|---|
| OBS-001 | P0 | Production services shall emit structured logs, metrics, and traces with shared request identifiers. |
| OBS-002 | P0 | Telemetry shall avoid raw authentication credentials, private images, precise locations, and unnecessary user-entered text. |
| OBS-003 | P0 | Alerts shall exist for authentication failures, elevated API errors, processing backlog, recommendation failure, provider outage, report backlog, data-store health, and budget anomalies. |
| OBS-004 | P0 | Dashboards shall report the performance and reliability targets in Section 14. |
| OBS-005 | P0 | Analytics events shall have a versioned taxonomy, owner, purpose, retention period, and validation tests. |
| OBS-006 | P0 | Recommendation telemetry shall distinguish no-valid-outfit, provider failure, rule failure, model failure, timeout, and user cancellation. |
| OBS-007 | P0 | The app shall provide a privacy-safe support identifier that users can share when reporting a problem. |
| OBS-008 | P0 | Feature releases shall support health comparison between staged cohorts and the baseline. |
| OBS-009 | P0 | Operational runbooks shall exist for major alerts and external-provider failures. |

---

## 17. Maintainability and Engineering Quality

| ID | Priority | Requirement |
|---|---|---|
| ENG-001 | P0 | The codebase shall use documented modular boundaries for authentication, closet, recommendation, social, trip, media, and shared design components. |
| ENG-002 | P0 | Business rules shall not exist only in view code or unversioned model prompts. |
| ENG-003 | P0 | Public API contracts, database migrations, configuration, and recommendation-rule changes shall be version-controlled and reviewed. |
| ENG-004 | P0 | The build pipeline shall perform formatting/linting, unit tests, contract tests, static analysis, secret scanning, dependency scanning, and release artifact signing. |
| ENG-005 | P0 | Critical outfit constraints, authorization rules, privacy boundaries, account deletion, and moderation actions shall have automated tests. |
| ENG-006 | P0 | The iOS application shall support dependency injection or equivalent test seams for authentication, weather, media, and recommendation clients. |
| ENG-007 | P0 | Remote configuration shall be schema-validated and shall have safe defaults. |
| ENG-008 | P0 | Environments shall include at minimum local/development, test, staging, and production with separate credentials and data. |
| ENG-009 | P0 | Release builds shall be reproducible from a tagged source revision and associated configuration version. |
| ENG-010 | P0 | Architectural decisions with material security, privacy, cost, or vendor consequences shall be recorded in decision records. |

---

## 18. Compatibility and Localization

| ID | Priority | Requirement |
|---|---|---|
| COMPAT-001 | P0 | The first release shall support iPhone devices capable of running iOS 17 or later. |
| COMPAT-002 | P0 | The application shall be tested on the smallest and largest supported iPhone display classes and representative older supported hardware. |
| COMPAT-003 | P0 | The application shall handle camera, memory, and performance differences across supported devices without losing core data. |
| COMPAT-004 | P0 | User-facing text, date/time, measurement units, season labels, and accessibility strings shall be externalized for localization. |
| COMPAT-005 | P0 | Temperature shall respect user locale or explicit preference for Celsius/Fahrenheit. |
| COMPAT-006 | P0 | Date, time, and trip-day calculations shall use the relevant local time zone and remain correct across daylight-saving changes. |
| COMPAT-007 | P1 | Post-launch localization should prioritize markets using measured demand and operational readiness, including moderation capacity. |

---

## 19. App Store and Legal Release Requirements

| ID | Priority | Requirement |
|---|---|---|
| STORE-001 | P0 | The final product name, subtitle, icon, screenshots, description, and keywords shall be reviewed for trademark, ownership, and App Store availability before submission. |
| STORE-002 | P0 | The app shall comply with current Apple App Review Guidelines applicable at submission time. |
| STORE-003 | P2 | If third-party sign-in is ever offered, Sign in with Apple shall remain available where required by Apple's current rules. |
| STORE-004 | P0 | The application shall provide an in-app control to clear local user data and shall explain that no server account exists. |
| STORE-005 | P0 | Camera, photo-library, notification, and location usage descriptions shall be specific, truthful, and aligned with actual behavior. |
| STORE-006 | P0 | App Store privacy nutrition labels shall match production data collection and third-party SDK behavior. |
| STORE-007 | P0 | The product shall provide a public Privacy Policy URL, support URL, and Terms of Use using no-charge hosting where practical. |
| STORE-008 | P1 | User-generated-content controls are required before the post-release CloudKit social capability is enabled. |
| STORE-009 | P0 | The team shall possess rights or licenses for all fonts, icons, photography, datasets, SDKs, and other shipped content. |
| STORE-010 | P0 | The app shall not imply affiliation with Airbnb or reproduce Airbnb's proprietary branding or trade dress. |
| STORE-011 | P0 | Export-compliance, age-rating, content-rights, and regional availability declarations shall be completed accurately. |
| STORE-012 | P0 | App Review shall be able to exercise important functionality without a reviewer account because the release has no authentication. |
| STORE-013 | P0 | The app shall provide a support contact capable of responding after launch; moderation operations are not required while the app distributes no user-generated content. |
| STORE-014 | P0 | The release owner shall recheck the live App Review Guidelines and App Store Connect privacy requirements immediately before every submission because platform requirements may change after this SRS is approved. |

---

## 20. Testing Strategy and Release Gates

### 20.1 Required Test Levels

The delivery process shall include:

- unit testing for rules, scoring, validation, transformations, and state management;
- property or combinatorial testing for outfit completeness and lock constraints;
- integration testing for local persistence, media processing, and optional weather behavior;
- UI testing for critical iPhone journeys;
- image-processing evaluation across garment types, backgrounds, lighting, patterns, and skin tones when people appear incidentally;
- accessibility testing with VoiceOver, Dynamic Type, contrast tools, Reduce Motion, and non-color cues;
- security testing, dependency review, and penetration testing proportional to risk;
- local data migration/corruption recovery and provider-failure testing;
- TestFlight internal and external beta testing;
- App Store submission rehearsal and legal/privacy review.

### 20.2 P0 End-to-End Acceptance Scenarios

#### AC-001: First Useful Outfit

Given a first-time local user with location permission, when the user adds enough seasonally appropriate items to form a complete outfit, then Home shall display a weather-aware Outfit of the Day made exclusively from those items without requiring sign-in.

#### AC-002: Location Fallback

Given a user who denies location, when the user supplies a valid city, then weather recommendations shall use that city. If the user also declines a city, generation shall still work using season or neutral context and shall disclose that weather was not used.

#### AC-003: Guided Item Capture

Given a selected clothing category, when the user photographs a garment using the guide, then the app shall produce an adjustable isolated crop, detected dominant/accent colors, and a confirmation form. No closet item shall be created until the user confirms all required metadata.

#### AC-004: Duplicate Name Warning

Given an existing item named “Blue Shirt,” when the user attempts to save “ blue   shirt ” as a separate item, then the app shall warn about the name match and allow deliberate continuation or revision.

#### AC-005: Locked Shirt

Given an available shirt locked by the user, when the user chooses “bar/night out” and an appropriate formality, then every returned outfit shall retain that shirt or clearly report that no valid outfit can be formed. The system shall not silently replace it.

#### AC-006: Unavailable Piece

Given a generated outfit, when the user marks the footwear unavailable and rerolls that slot, then the remaining outfit shall stay unchanged, the unavailable footwear shall not be immediately repeated, and the replacement shall be validated against the complete outfit.

#### AC-007: Historical Snapshot

Given a user has a saved or worn outfit containing an item, when the live closet item is renamed or archived, then the historical record shall retain the item snapshot.

#### AC-008: Trip Packing

Given a trip with multiple saved outfits that reuse one pair of shoes, then the packing list shall show the shoes once, preserve both outfit assignments, and support one packed/unpacked state for that physical item.

#### AC-009: Offline and Weather Degradation

Given the device is offline or live weather is unavailable, when the closet and structured inputs permit a rules-based outfit, then the app shall return an on-device deterministic recommendation and identify the season or neutral context used.

#### AC-010: Local Data Deletion

Given a user confirms clearing local data, then closet, profile, saved/worn history, preferences, and trips shall be removed from the app container without contacting a backend.

#### AC-011: Accessibility

Given a VoiceOver user at an accessibility Dynamic Type size, the user shall be able to add an item, inspect detected colors as text, lock a piece, generate an outfit, and save it without inaccessible unlabeled controls or blocked content.

### 20.3 Release Gates

The public release shall not proceed until:

1. all P0 requirements are implemented or a formal approved deviation exists;
2. all P0 acceptance scenarios pass in the release candidate environment;
3. no open critical or high-severity security/privacy defect lacks approved mitigation;
4. tests confirm closet, profile, history, trip, and image data remain local to the app container;
5. the clear-local-data flow passes end-to-end;
6. crash-free, launch, generation, image-processing, and weather-fallback targets are met during beta or accepted with a corrective plan;
7. accessibility review has no unresolved issue that blocks a core journey;
8. persistence migration/corruption handling and provider-failure behavior have been exercised;
9. legal documents, privacy disclosures, usage strings, support operations, and store metadata are approved;
10. support ownership, release rollback instructions, and the zero-recurring-service-cost review are complete.

---

## 21. Requirements Traceability Summary

| Product objective | Principal requirement groups |
|---|---|
| Digitize a private wardrobe | ITEM, CLO, DATA, PRIV, SEC |
| Weather-aware daily recommendation | WEA, HOME, REC |
| Occasion/formality generator | GEN, COMP, REC |
| Lock and reroll specific pieces | COMP, REC, FB |
| Learn from feedback | FB, REC, PRIV |
| Save and document worn outfits | HIST, POST |
| Follow people and view outfits | SOC, POST, SAFE |
| Plan and pack for trips | TRIP, WEA, OFF |
| Deliver a free App Store product | STORE, SEC, PRIV, REL, ENG |
| Provide an accessible, charming experience | UX, A11Y, PERF |

A detailed bidirectional traceability matrix should be maintained in the delivery system linking each requirement ID to design artifacts, implementation work, tests, defects, and release evidence.

---

## 22. Risks and Mitigations

| Risk | Impact | Required mitigation |
|---|---|---|
| Small closets cannot produce complete outfits | Poor first-run value | Inventory progress guidance, useful empty states, constraint relaxation, no fabricated items |
| Garment segmentation fails on busy backgrounds | Incorrect images/colors | Capture outline, lighting guidance, confidence thresholds, manual crop and color correction |
| Weather provider is unavailable or inaccurate | Inappropriate recommendations | Provider adapter, caching, visible freshness, city/season/neutral fallback |
| Recommendation feels arbitrary | Loss of trust | Deterministic core, reason codes, feedback, locked-piece guarantees, versioned rules |
| User photos create safety and privacy obligations | App Store or user harm | EXIF removal, reporting, blocking, moderation, policy, access controls, deletion |
| Free cloud AI/media costs become unsustainable | Service degradation | On-device processing, caching, quotas, budgets, async pipelines, deterministic fallback |
| Private closet data is exposed through social features | Severe privacy incident | Separate access policies and snapshots, server-side authorization, multi-account isolation tests |
| Product name conflicts with an existing mark/app | Rebranding cost | Name, domain, trademark, and store-availability review before brand investment |
| Overly broad v1 reduces delivery quality | Delayed or unstable launch | Vertical milestones, staged TestFlight rollout, feature flags, release gates, formal scope control |
| Outfit rules encode cultural or gender assumptions | Exclusion and bad recommendations | Neutral taxonomy, user-controlled preferences, explainability, diverse testing, feedback review |

---

## 23. Recommended Additions Included in This SRS

The following additions were not all part of the original short concept but are included because they are necessary or strongly beneficial for a production App Store product:

1. **Reporting, blocking, moderation, community guidelines, and an appeals path.** These are required to operate a social app with user-uploaded photos safely.
2. **Private/public snapshot separation.** A post contains a safe historical outfit snapshot so publishing never exposes the live closet.
3. **Account export and in-app deletion.** These support user trust, privacy compliance, and App Store readiness.
4. **Persistent availability states.** In addition to one-session rerolling, users may mark items in laundry, temporarily unavailable, packed, or archived so future suggestions remain practical.
5. **Recommendation explanations and versioning.** Users can see why an outfit fits, while engineers can reproduce and safely roll back problematic results.
6. **Manual correction and degraded processing.** Clothing capture remains usable when automatic crop or color detection fails.
7. **Undo after reroll.** Users can recover the previous outfit instead of losing a good combination accidentally.
8. **Trip packing deduplication and conflict checks.** Reused items appear once in a packing list, and overlapping availability conflicts are visible.
9. **Optional notifications with privacy controls.** Daily outfits, weather changes, followers, and trip reminders can be useful without becoming mandatory.
10. **Offline cached access.** Recent closet, outfit, and trip information remains useful during travel or temporary connectivity loss.
11. **Formal security, privacy, accessibility, observability, moderation, and operational release gates.** These turn the concept into an operable enterprise-grade product rather than only a feature list.
12. **Name verification as a release dependency.** “myCloset” remains provisional until trademark, domain, social-handle, and App Store availability checks are complete.

These additions do not introduce likes, comments, monetization, public closets, or duplicate-image policing.

---

## 24. Deferred Product Decisions

These decisions do not block the SRS baseline but shall be resolved before their affected implementation milestone:

| Decision | Required by | Default if unresolved |
|---|---|---|
| Final product name and brand identity | Store metadata and production signing | Continue using myCloset only as an internal working title |
| Launch countries/regions | Weather provider, privacy, moderation, legal, and store configuration | Launch in one approved English-speaking market |
| Minimum user age and age-assurance approach | Legal, moderation, store age rating | Do not launch until counsel/product owner approves an age policy |
| Exact clothing taxonomy | Capture and recommendation implementation | Use the minimum taxonomy in ITEM-002 with configurable subcategories |
| Exact weather provider | Backend integration | Select through privacy, coverage, cost, reliability, and license review |
| Cloud AI/image provider | Media and recommendation implementation | Prefer on-device processing; use a reviewed provider only where needed |
| Public profile visibility for non-followers | Social design and privacy review | Visible to authenticated, non-blocked users as assumed in this SRS |
| Whether dark mode ships in v1 | Design-system milestone | Include it unless formally deferred with accessibility review |
| Post caption character limit | API contract | Use a conservative configurable limit |
| Media size and format limits | API/media performance testing | Use server-configured limits and client preflight validation |

---

## 25. Definition of Done

A requirement is complete only when:

1. product and design behavior is documented;
2. implementation is code-reviewed and merged;
3. server-side authorization and validation are present where applicable;
4. automated tests cover normal, boundary, error, permission, offline, and abuse cases proportional to risk;
5. analytics and observability are added without violating privacy requirements;
6. accessibility behavior is verified;
7. security and privacy implications are reviewed;
8. user-facing help and legal disclosures are updated where necessary;
9. the requirement is demonstrated in a production-like staging environment;
10. traceability links connect the requirement, implementation, tests, and release evidence.

---

## Appendix A: Glossary

| Term | Definition |
|---|---|
| Closet item | A private digital record representing one physical garment, shoe, or accessory owned by the user |
| Outfit | A valid combination of closet-item snapshots assembled manually or by the recommendation engine |
| Outfit of the Day | The stable daily recommendation shown on Home, preferably using current weather |
| Locked piece | A user-selected item that the generator must retain while choosing remaining pieces |
| Reroll | Replace one or more unlocked pieces while retaining applicable constraints |
| Outfit snapshot | An immutable historical representation of the pieces used at a point in time |
| Worn outfit | A private outfit record that the user confirms they wore on a date |
| Outfit post | Explicit public-facing content containing a generated composition or separately approved photo plus a safe detached outfit snapshot |
| Dominant color | A principal confirmed color of an isolated garment |
| Accent color | A secondary confirmed color that materially contributes to garment matching |
| Hard constraint | A rule the engine may not violate without explicit user action |
| Soft constraint | A preference or scoring factor that may be traded off with explanation |
| Weather context | Current conditions, city conditions, seasonal fallback, or neutral state used in generation |
| P0/P1/P2 | First-release, planned post-launch, and future priorities respectively |

## Appendix B: Suggested Formality Mapping

| Level | Label | Example contexts |
|---:|---|---|
| 1 | Active / Sport | Gym, run, recreational sport |
| 2 | Very Casual | Home, errands, relaxed walk |
| 3 | Casual | School, casual meal, daytime social activity |
| 4 | Smart Casual | Date, bar, elevated dinner, informal office |
| 5 | Business | Office, professional meeting, conference |
| 6 | Formal | Wedding, gala, formal ceremony |

An item may belong to multiple levels. Occasion presets define a target level or range rather than permanently changing item metadata.

## Appendix C: Example Recommendation Explanation

> “Built around your locked navy shirt. The beige trousers provide a balanced neutral contrast, and the water-resistant jacket fits the cool, rainy forecast. This combination matches the smart-casual setting you selected.”

Explanations shall describe known inputs and rules. They shall not claim personal expertise, guaranteed comfort, or fashion authority.

## Appendix D: Normative and Informative References

The following official Apple sources were checked on July 14, 2026. The live versions shall be reviewed again before submission:

1. [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) — user-generated content, third-party login, privacy, data sharing, and general review obligations.
2. [Offering account deletion in your app](https://developer.apple.com/support/offering-account-deletion-in-your-app/) — in-app initiation, full-account deletion, and deletion of associated user-generated content.
3. [TN3194: Handling account deletions and revoking tokens for Sign in with Apple](https://developer.apple.com/documentation/technotes/tn3194-handling-account-deletions-and-revoking-tokens-for-sign-in-with-apple) — Sign in with Apple token revocation during account deletion.
4. [App privacy details on the App Store](https://developer.apple.com/app-store/app-privacy-details/) — declaration of data collected by the app and integrated third parties.
5. [Configuring Sign in with Apple support](https://developer.apple.com/documentation/xcode/configuring-sign-in-with-apple) — application capability and identity integration guidance.
6. [Apple Developer Program membership details](https://developer.apple.com/programs/whats-included/) — CloudKit and WeatherKit allowances included with membership.
7. [CloudKit public database](https://developer.apple.com/documentation/cloudkit/ckcontainer/publicclouddatabase) — public-record availability, visibility, ownership, and storage-quota behavior.

These references inform platform-release requirements but do not replace legal advice, jurisdiction-specific privacy review, or a current pre-submission compliance review.
