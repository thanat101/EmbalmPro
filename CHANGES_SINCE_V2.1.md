# Anubis SDS — All New Changes Since v2.1.0

Summary of every change made after the v2.1.0 release (SDS database, Fluid management, Case tracking, CH2O calculator, User Guide, subscription management). Listed in chronological order.

---

## v2.1.1
- **Welcome screen:** Fixed Get Started button in both toggle states.
- **State:** Improved state management for welcome screen presentation and subscription state handling.

## v2.1.2
- **Subscription:** Updates to subscription manager.

## v2.1.3
- **Performance:** File-based caching for SDS/Fluid data.
- **FluidDetailView:** Optimized initialization and memory use.
- **Fluid:** Codable support added for Fluid model.
- **Memory:** General memory management improvements.

## v2.1.4
- **Stability:** Tagged as stable working version.

## v2.1.5 (cache fix)
- **Cache:** Force cache refresh after saves in SDS and Fluid views.
- **SDSDetailView:** Correct refresh of data after edits.
- **DatabaseManager:** Fixed boolean comparison; added logging for cache operations.

## v2.1.6-dev
- **WelcomeView:** Consistent full-screen presentation (fullScreenCover on launch and About).
- **FilterButton:** New FilterButton component; improved navigation/presentation.
- **Layout:** Navigation and layout fixes for iPad and iPhone.
- **Tab bar:** Updated tab bar and navigation stack behavior.
- **SDS:** Improved SDS section icons and presentation.
- **UI:** Broader UI consistency across devices; ready for sandbox testing.

## v2.1.7
- **Settings:** New Settings view with database reset.
- **Database:** Improved refresh from bundle; User Guide updated with reset instructions.

## v2.1.8
- **CaseView:** Keyboard dismisses on scroll (aligned with other views).
- **WelcomeView:** Content/messaging updates.
- **Database:** New sort order applied to database files.

## v2.1.9 / v2.1.9.1
- **SDS view:** GHS hazard symbols added; product info moved to header.
- **User Guide:** New Symbols Guide section; other app file updates.
- **Content:** Database, User Guide, and welcome messaging updates.

## v2.2.x
- **Loading:** Loading screen added.
- **Emergency:** Safe emergency dialing (phone calling) implemented.
- **v2.2.2:** Hazard icons and subscription handling updates.
- **v2.2.3 stable:** GHS placards fixed; phone calling fixed; fluid edit INDEX save fixed.

## v2.4.1
- **Version:** Bump to MARKETING_VERSION 2.4.1.

## v2.5.1
- **Stability:** Bug fixes and stable release.

## v2.6.1
- **Filters:** Manufacturer filter persists across sessions.
- **Selection:** Multi-select support.
- **Case Log:** Case Analysis filter added.

## v2.7.1 (App Store v2.6)
- **Search:** Color search added.
- **User Guide:** User Guide update.

## v2.6.2
- **Database reset:** Selective reset so Case Log data is preserved when resetting SDS/fluid data.
- **Welcome:** Key features on Welcome screen now include Case Log.

## Current stable (v2.7.1)
- **GHS09:** GHS09 display support in SDS and Fluid views.
- **Case Log:** Case Log and report UI updates.
- **UI:** AppStyle and WelcomeView updates.
- **Cleanup:** Removed generated DB/PDF assets from repo (e.g. EmbalmingReportForm.pdf, extra DB copies, print layout images).

---

## Quick reference by area

| Area | Changes |
|------|--------|
| **Welcome / Onboarding** | Get Started fix, fullScreenCover, FilterButton, key features include Case Log |
| **Settings** | New Settings view, database reset (later: selective reset, Case Log preserved) |
| **SDS** | Cache refresh, section icons, GHS symbols in view, product info in header, GHS09 display |
| **Fluid** | Caching, Codable, optimized init, INDEX save fix, GHS09 display |
| **Case Log** | Keyboard dismiss on scroll, Case Analysis filter, selective reset preserves data, report/UI updates |
| **Search / Filters** | Manufacturer filter persist, multi-select, color search |
| **Performance** | File-based cache, FluidDetailView optimization, memory improvements |
| **Safety / UX** | Loading screen, safe emergency dialing, GHS placards fix |
| **Subscription** | Manager updates, hazard icons and handling |
| **User Guide** | Reset instructions, Symbols Guide, general updates |
| **Housekeeping** | Version bumps 2.4.1 → 2.7.1, removal of generated assets |
