# Rollback: Manufacturer filter (persist + multi-select + Case Analysis)

If the app misbehaves after the manufacturer filter changes, you can revert to the previous behavior.

**What was changed (v2.6.1):**
- **FluidsView.swift**: Persisted manufacturer filter (UserDefaults), multi-select manufacturer (ManufacturerFilterButton), `selectedManufacturers` instead of `selectedManufacturer`.
- **CaseDetailView.swift**: Suggested fluids in Case Analysis respect the persisted manufacturer filter (only fluids from selected manufacturer(s) are considered).

**To rollback:**
1. Revert the commit that added these changes, or
2. Restore from git: `git checkout v2.5.1 -- AnubisSDS/FluidsView.swift AnubisSDS/CaseDetailView.swift` (then rebuild).

**Stored data:** UserDefaults key `FluidsView.selectedManufacturers` (array of manufacturer names). If you rollback, that key is simply ignored by the old code; no need to delete it.
