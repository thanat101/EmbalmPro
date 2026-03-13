import SwiftUI

// MARK: - Persistent label above field (title stays visible when field has content)
private struct LabeledField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var axis: Axis = .horizontal
    var lineLimit: ClosedRange<Int>? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let lineLimit = lineLimit {
                if placeholder.isEmpty {
                    TextField(title, text: $text, axis: axis)
                        .lineLimit(lineLimit)
                } else {
                    TextField(title, text: $text, prompt: Text(placeholder), axis: axis)
                        .lineLimit(lineLimit)
                }
            } else {
                if placeholder.isEmpty {
                    TextField(title, text: $text)
                } else {
                    TextField(title, text: $text, prompt: Text(placeholder))
                }
            }
        }
    }
}

/// UserDefaults keys for prepopulating facility and embalmer on new reports.
private enum CaseLogDefaults {
    static let facilityKey = "CaseLogDefaultFacilityName"
    static let embalmerKey = "CaseLogDefaultEmbalmerName"
    static let placesKey = "CaseLogDefaultPlacesOfDeath"
    static let placesUsageKey = "CaseLogPlacesOfDeathUsage"

    static var facility: String {
        get { UserDefaults.standard.string(forKey: facilityKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: facilityKey) }
    }

    static var embalmer: String {
        get { UserDefaults.standard.string(forKey: embalmerKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: embalmerKey) }
    }

    static var placesOfDeath: [String] {
        get { UserDefaults.standard.stringArray(forKey: placesKey) ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: placesKey) }
    }

    /// Tracks how many times each place of death has been used (for sorting by most-used).
    static var placeUsage: [String: Int] {
        get {
            (UserDefaults.standard.dictionary(forKey: placesUsageKey) as? [String: Int]) ?? [:]
        }
        set {
            UserDefaults.standard.set(newValue, forKey: placesUsageKey)
        }
    }
}

/// Add or edit a single Case Log / Embalmer's Report.
struct CaseLogDetailView: View {
    /// Existing report to edit, or nil for a new report.
    let report: CaseLogReport?
    /// When starting from Case Analysis → CH₂O, prefill condition & fluids from that context.
    var prefill: CaseLogPrefill? = nil
    /// Called after save or delete so the list can refresh.
    var onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var caseNumber: String = ""
    @State private var decedentName: String = ""
    @State private var gender: String = ""
    @State private var age: String = ""
    @State private var race: String = ""
    @State private var dateOfDeath: String = ""
    @State private var placeOfDeath: String = ""
    @State private var facilityName: String = ""
    @State private var embalmerName: String = ""
    @State private var dateOfEmbalming: String = ""
    @State private var embalmingTimeFinish: String = ""
    @State private var bodyWeight: String = ""
    @State private var bodyType: String = ""
    @State private var conditionSummary: String = ""
    @State private var mouthClosure: String = ""
    @State private var eyeClosure: String = ""
    @State private var arteriesInjected: String = ""
    @State private var veinsDrained: String = ""
    @State private var drainageMethod: String = ""
    @State private var aspiration: String = ""
    @State private var disinfectant: String = ""
    @State private var arterialFluidUsed: String = ""
    @State private var coInjection: String = ""
    @State private var cavityChemical: String = ""
    @State private var solutionDetails: String = ""
    @State private var conditionAfterEmbalming: String = ""
    @State private var notes: String = ""
    @State private var conditionOfRemainsWhenReceived: String = ""
    @State private var bodyMarks: [BodyMark] = []
    @State private var draftReportId: String = ""
    @State private var showDeleteConfirm = false
    @State private var recentPlacesOfDeath: [String] = []

    private var isNewReport: Bool { report == nil }
    private var reportId: String { report?.id ?? draftReportId }

    // Internal Date state for picker/quick buttons (string fields remain the source of truth for DB/printing)
    @State private var dateOfDeathDate: Date = Date()
    @State private var dateOfEmbalmingDate: Date = Date()

    private static let caseLogDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "M/d/yyyy" // matches examples like 2/28/2025
        return f
    }()

    // Cached list of co-injection fluid names for the dropdown.
    @State private var coInjectionOptions: [String] = []
    // Cached list of cavity chemical fluid names for the dropdown.
    @State private var cavityChemicalOptions: [String] = []
    // Cached list of disinfectant fluid names for the dropdown.
    @State private var disinfectantOptions: [String] = []

    private func setDateOfDeath(from date: Date) {
        dateOfDeathDate = date
        dateOfDeath = Self.caseLogDateFormatter.string(from: date)
        // Prefill embalming date if it's currently empty
        if dateOfEmbalming.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            setDateOfEmbalming(from: date)
        }
    }

    private func setDateOfEmbalming(from date: Date) {
        dateOfEmbalmingDate = date
        dateOfEmbalming = Self.caseLogDateFormatter.string(from: date)
    }

    private func parseCaseLogDate(_ s: String) -> Date? {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Self.caseLogDateFormatter.date(from: trimmed)
    }

    private func loadCoInjectionOptionsIfNeeded() {
        if !coInjectionOptions.isEmpty { return }
        func buildOptions(from fluids: [Fluid]) -> [String] {
            var list = fluids
            // Respect manufacturer filter from Fluids view, if any.
            if let allowed = ManufacturerFilterStorage.allowedManufacturersForCaseAnalysis(), !allowed.isEmpty {
                list = list.filter { allowed.contains($0.manufacturer.trimmingCharacters(in: .whitespacesAndNewlines)) }
            }
            return list
                .filter { ($0.type ?? "").lowercased().contains("co-injection fluid") }
                .map { $0.name }
                .sorted()
        }
        // Prefer cached fluids if available to avoid extra DB hits.
        if let cached = DatabaseManager.shared.getCachedFluids() {
            coInjectionOptions = buildOptions(from: cached.fluids)
            return
        }
        // Fallback: refresh cache once, then try again.
        DatabaseManager.shared.updateFluidsCache()
        if let cached = DatabaseManager.shared.getCachedFluids() {
            coInjectionOptions = buildOptions(from: cached.fluids)
        }
    }

    private func loadCavityChemicalOptionsIfNeeded() {
        if !cavityChemicalOptions.isEmpty { return }
        func buildOptions(from fluids: [Fluid]) -> [String] {
            var list = fluids
            // Respect manufacturer filter from Fluids view, if any.
            if let allowed = ManufacturerFilterStorage.allowedManufacturersForCaseAnalysis(), !allowed.isEmpty {
                list = list.filter { allowed.contains($0.manufacturer.trimmingCharacters(in: .whitespacesAndNewlines)) }
            }
            return list
                .filter { ($0.type ?? "").lowercased().contains("cavity embalming fluid") }
                .map { $0.name }
                .sorted()
        }
        if let cached = DatabaseManager.shared.getCachedFluids() {
            cavityChemicalOptions = buildOptions(from: cached.fluids)
            return
        }
        DatabaseManager.shared.updateFluidsCache()
        if let cached = DatabaseManager.shared.getCachedFluids() {
            cavityChemicalOptions = buildOptions(from: cached.fluids)
        }
    }

    private func loadDisinfectantOptionsIfNeeded() {
        if !disinfectantOptions.isEmpty { return }
        func buildOptions(from fluids: [Fluid]) -> [String] {
            var list = fluids
            // Respect manufacturer filter from Fluids view, if any.
            if let allowed = ManufacturerFilterStorage.allowedManufacturersForCaseAnalysis(), !allowed.isEmpty {
                list = list.filter { allowed.contains($0.manufacturer.trimmingCharacters(in: .whitespacesAndNewlines)) }
            }
            return list
                .filter { ($0.use ?? "").lowercased().contains("disinfectant") }
                .map { $0.name }
                .sorted()
        }
        if let cached = DatabaseManager.shared.getCachedFluids() {
            disinfectantOptions = buildOptions(from: cached.fluids)
            return
        }
        DatabaseManager.shared.updateFluidsCache()
        if let cached = DatabaseManager.shared.getCachedFluids() {
            disinfectantOptions = buildOptions(from: cached.fluids)
        }
    }

    private func addCurrentPlaceOfDeathToRecents() {
        let place = t(placeOfDeath)
        guard !place.isEmpty else { return }

        // Update usage counts
        var usage = CaseLogDefaults.placeUsage
        usage[place, default: 0] += 1
        CaseLogDefaults.placeUsage = usage

        // Build a unique list of places sorted by most-used (then alphabetically)
        let sorted = usage.keys.sorted { lhs, rhs in
            let cl = usage[lhs] ?? 0
            let cr = usage[rhs] ?? 0
            if cl != cr { return cl > cr }
            return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
        }

        // Cap to a reasonable maximum
        let limited = Array(sorted.prefix(20))
        CaseLogDefaults.placesOfDeath = limited
        recentPlacesOfDeath = limited
    }

    // MARK: - Section builders (helps Canvas type-check smaller expressions)

    private var caseNumberSection: some View {
        Section {
            LabeledField(title: "Case number", text: $caseNumber, placeholder: "Auto-assigned for new cases")
                .keyboardType(.numberPad)
        } header: {
            Text("Case number")
        } footer: {
            Text("Optional. New cases get the next number automatically; you can edit it.")
        }
    }

    private var decedentSection: some View {
        Section {
            LabeledField(title: "Decedent name", text: $decedentName)
            // Gender: text field plus fixed choices
            VStack(alignment: .leading, spacing: 4) {
                Text("Gender")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    TextField("Gender", text: $gender)
                    Menu {
                        ForEach([
                            "Male",
                            "Female",
                            "Unknown",
                            "Other"
                        ], id: \.self) { option in
                            Button(option) {
                                gender = option
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .foregroundColor(AppStyle.accentColor)
                    }
                }
            }
            LabeledField(title: "Age", text: $age)
            // Race: text field plus fixed choices
            VStack(alignment: .leading, spacing: 4) {
                Text("Race")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    TextField("Race", text: $race)
                    Menu {
                        ForEach([
                            "White",
                            "Black or African American",
                            "American Indian or Alaska Native",
                            "Asian",
                            "Native Hawaiian or Other Pacific Islander",
                            "Other"
                        ], id: \.self) { option in
                            Button(option) {
                                race = option
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .foregroundColor(AppStyle.accentColor)
                    }
                }
            }
            // Date of death: text field and compact date picker on the same row
            VStack(alignment: .leading, spacing: 4) {
                Text("Date of death")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    TextField("Date of death", text: $dateOfDeath)
                    Spacer()
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { dateOfDeathDate },
                            set: { setDateOfDeath(from: $0) }
                        ),
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .frame(maxWidth: 140)
                }
            }
            // Place of death: text field plus recent places dropdown (per-user, from UserDefaults)
            VStack(alignment: .leading, spacing: 4) {
                Text("Place of death")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    TextField("Place of death", text: $placeOfDeath)
                    if !recentPlacesOfDeath.isEmpty {
                        Menu {
                            ForEach(recentPlacesOfDeath, id: \.self) { option in
                                Button(option) {
                                    placeOfDeath = option
                                }
                            }
                        } label: {
                            Image(systemName: "chevron.down")
                                .foregroundColor(AppStyle.accentColor)
                        }
                    }
                }
            }
        } header: {
            Text("Decedent & death")
        } footer: {
            Text("Decedent identification and death information.")
        }
    }

    private var facilitySection: some View {
        Section {
            LabeledField(title: "Facility name", text: $facilityName)
            LabeledField(title: "Embalmer name", text: $embalmerName)
            // Embalming date: text field and compact date picker on the same row
            VStack(alignment: .leading, spacing: 4) {
                Text("Embalming date")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    TextField("Embalming date", text: $dateOfEmbalming)
                    Spacer()
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { dateOfEmbalmingDate },
                            set: { setDateOfEmbalming(from: $0) }
                        ),
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .frame(maxWidth: 140)
                }
            }
            LabeledField(title: "Embalming time / finish", text: $embalmingTimeFinish, placeholder: "e.g. start – finish")
        } header: {
            Text("Facility & embalmer")
        } footer: {
            Text("Where the case was performed and who performed it.")
        }
    }

    private var bodySectionView: some View {
        Section {
            LabeledField(title: "Body weight", text: $bodyWeight, placeholder: "e.g. 200 lb")
            LabeledField(title: "Body type", text: $bodyType, placeholder: "e.g. Average, High BMI, All Muscle")
            LabeledField(title: "Condition / case type summary", text: $conditionSummary, axis: .vertical, lineLimit: 2...5)
        } header: {
            Text("Body & condition")
        } footer: {
            Text("Body characteristics and condition before embalming.")
        }
    }

    private var fluidsSection: some View {
        Section {
            LabeledField(title: "Arterial fluid used", text: $arterialFluidUsed, axis: .vertical, lineLimit: 2...5)
            // Co-injection: free text plus dropdown of matching fluids (from Fluids view data)
            VStack(alignment: .leading, spacing: 4) {
                Text("Co-injection")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    TextField("Co-injection", text: $coInjection)
                    if !coInjectionOptions.isEmpty {
                        Menu {
                            ForEach(coInjectionOptions, id: \.self) { option in
                                Button(option) {
                                    // Allow selecting multiple co-injection fluids; append if not already present.
                                    let trimmed = coInjection.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if trimmed.isEmpty {
                                        coInjection = option
                                    } else if !trimmed.contains(option) {
                                        coInjection = trimmed + ", " + option
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "chevron.down")
                                .foregroundColor(AppStyle.accentColor)
                        }
                    }
                }
            }
            // Cavity chemical: free text plus dropdown of matching cavity fluids
            VStack(alignment: .leading, spacing: 4) {
                Text("Cavity chemical")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    TextField("Cavity chemical", text: $cavityChemical)
                    if !cavityChemicalOptions.isEmpty {
                        Menu {
                            ForEach(cavityChemicalOptions, id: \.self) { option in
                                Button(option) {
                                    // Allow selecting multiple cavity chemicals; append if not already present.
                                    let trimmed = cavityChemical.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if trimmed.isEmpty {
                                        cavityChemical = option
                                    } else if !trimmed.contains(option) {
                                        cavityChemical = trimmed + ", " + option
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "chevron.down")
                                .foregroundColor(AppStyle.accentColor)
                        }
                    }
                }
            }
            LabeledField(title: "Solution / calculation details", text: $solutionDetails, placeholder: "e.g. Fluid Index, strength %, oz per gallon", axis: .vertical, lineLimit: 2...5)
            // Disinfectant: free text plus dropdown of matching disinfectant fluids (USE contains "DISINFECTANT")
            VStack(alignment: .leading, spacing: 4) {
                Text("Disinfectant")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    TextField("Disinfectant", text: $disinfectant)
                    if !disinfectantOptions.isEmpty {
                        Menu {
                            ForEach(disinfectantOptions, id: \.self) { option in
                                Button(option) {
                                    // Allow selecting multiple disinfectants; append if not already present.
                                    let trimmed = disinfectant.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if trimmed.isEmpty {
                                        disinfectant = option
                                    } else if !trimmed.contains(option) {
                                        disinfectant = trimmed + ", " + option
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "chevron.down")
                                .foregroundColor(AppStyle.accentColor)
                        }
                    }
                }
            }
        } header: {
            Text("Fluids & solution")
        } footer: {
            Text("Arterial, co-injection, cavity, and solution details. Solution details are often prefilled from CH₂O Calculator.")
        }
    }

    private var closureSection: some View {
        Section {
            // Mouth closure: text field plus fixed choices (multi-select via comma-separated list)
            VStack(alignment: .leading, spacing: 4) {
                Text("Mouth closure")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    TextField("Injector needle or Ligature", text: $mouthClosure)
                    Menu {
                        ForEach(["Injector Needle", "Ligature", "Glue", "Mouth Former"], id: \.self) { option in
                            Button(option) {
                                let trimmed = mouthClosure.trimmingCharacters(in: .whitespacesAndNewlines)
                                if trimmed.isEmpty {
                                    mouthClosure = option
                                } else if !trimmed.contains(option) {
                                    mouthClosure = trimmed + ", " + option
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .foregroundColor(AppStyle.accentColor)
                    }
                }
            }
            // Eye closure: text field plus fixed choices (multi-select)
            VStack(alignment: .leading, spacing: 4) {
                Text("Eye closure")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    TextField("Eye closure", text: $eyeClosure)
                    Menu {
                        ForEach([
                            "Cotton",
                            "EyeCaps",
                            "Glue",
                            "Stay Cream",
                            "Other"
                        ], id: \.self) { option in
                            Button(option) {
                                let trimmed = eyeClosure.trimmingCharacters(in: .whitespacesAndNewlines)
                                if trimmed.isEmpty {
                                    eyeClosure = option
                                } else if !trimmed.contains(option) {
                                    eyeClosure = trimmed + ", " + option
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .foregroundColor(AppStyle.accentColor)
                    }
                }
            }
            // Arteries injected: text field plus fixed choices (multi-select)
            VStack(alignment: .leading, spacing: 4) {
                Text("Arteries injected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    TextField("Arteries injected", text: $arteriesInjected)
                    Menu {
                        ForEach([
                            "Right Carotid",
                            "Left Carotid",
                            "Left Femoral",
                            "Right Femoral",
                            "Left Axillary",
                            "Right Axillary",
                            "6-Point",
                            "Other"
                        ], id: \.self) { option in
                            Button(option) {
                                let trimmed = arteriesInjected.trimmingCharacters(in: .whitespacesAndNewlines)
                                if trimmed.isEmpty {
                                    arteriesInjected = option
                                } else if !trimmed.contains(option) {
                                    arteriesInjected = trimmed + ", " + option
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .foregroundColor(AppStyle.accentColor)
                    }
                }
            }
            // Veins drained: text field plus fixed choices
            VStack(alignment: .leading, spacing: 4) {
                Text("Veins drained")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    TextField("Veins drained", text: $veinsDrained)
                    Menu {
                        ForEach([
                            "Right Jugular",
                            "Left Jugular",
                            "Left Femoral",
                            "Right Femoral",
                            "Left Axillary",
                            "Right Axillary",
                            "Other"
                        ], id: \.self) { option in
                            Button(option) {
                                let trimmed = veinsDrained.trimmingCharacters(in: .whitespacesAndNewlines)
                                if trimmed.isEmpty {
                                    veinsDrained = option
                                } else if !trimmed.contains(option) {
                                    veinsDrained = trimmed + ", " + option
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .foregroundColor(AppStyle.accentColor)
                    }
                }
            }
            // Drainage method: text field plus fixed choices
            VStack(alignment: .leading, spacing: 4) {
                Text("Drainage method")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    TextField("Drainage method", text: $drainageMethod)
                    Menu {
                        ForEach([
                            "Drain Tube",
                            "Forceps",
                            "Birdcage",
                            "Intermittent",
                            "Continuous",
                            "Closed"
                        ], id: \.self) { option in
                            Button(option) {
                                let trimmed = drainageMethod.trimmingCharacters(in: .whitespacesAndNewlines)
                                if trimmed.isEmpty {
                                    drainageMethod = option
                                } else if !trimmed.contains(option) {
                                    drainageMethod = trimmed + ", " + option
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .foregroundColor(AppStyle.accentColor)
                    }
                }
            }
            // Aspiration: text field plus fixed choices
            VStack(alignment: .leading, spacing: 4) {
                Text("Aspiration")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    TextField("Delayed or Immediate", text: $aspiration)
                    Menu {
                        ForEach([
                            "Delayed",
                            "Immediate",
                            "Re-Aspirate (when)"
                        ], id: \.self) { option in
                            Button(option) {
                                let trimmed = aspiration.trimmingCharacters(in: .whitespacesAndNewlines)
                                if trimmed.isEmpty {
                                    aspiration = option
                                } else if !trimmed.contains(option) {
                                    aspiration = trimmed + ", " + option
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .foregroundColor(AppStyle.accentColor)
                    }
                }
            }
        } header: {
            Text("Closure & technique")
        } footer: {
            Text("Mouth and eye closure; injection and drainage technique.")
        }
    }

    private var afterSection: some View {
        Section {
            LabeledField(title: "Condition after embalming", text: $conditionAfterEmbalming, axis: .vertical, lineLimit: 2...5)
            LabeledField(title: "Embalmer notes", text: $notes, axis: .vertical, lineLimit: 4...10)
        } header: {
            Text("After embalming & notes")
        } footer: {
            Text("Final condition and any additional notes.")
        }
    }

    private var conditionWhenReceivedSection: some View {
        Section {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
                Text("Body – front")
                    .font(AppStyle.Typography.headline)
                    .foregroundColor(AppStyle.secondaryTextColor)
                TappableBodyView(
                    imageName: "BodyFront",
                    side: "front",
                    marks: $bodyMarks
                )
                Text("Body – back")
                    .font(AppStyle.Typography.headline)
                    .foregroundColor(AppStyle.secondaryTextColor)
                TappableBodyView(
                    imageName: "BodyBack",
                    side: "back",
                    marks: $bodyMarks
                )
            }
            .padding(.vertical, AppStyle.Spacing.small)
            LabeledField(title: "Condition of remains when received", text: $conditionOfRemainsWhenReceived, axis: .vertical, lineLimit: 3...8)
        } header: {
            Text("Condition when received")
        } footer: {
            Text("Tap to add a numbered area; tap the same spot again to remove it. Numbers continue from front to back (1, 2, 3…). Describe each area below.")
        }
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Delete report", systemImage: "trash")
            }
        }
    }

    var body: some View {
        Form {
            caseNumberSection
            decedentSection
            facilitySection
            bodySectionView
            fluidsSection
            closureSection
            afterSection
            conditionWhenReceivedSection
            if !isNewReport {
                deleteSection
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle(isNewReport ? "New report" : "Embalmer's report")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isNewReport {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss.callAsFunction()
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .disabled(decedentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    CaseLogPrintPDF.print(reports: [currentReportForPrint()])
                } label: {
                    Label("Print", systemImage: "printer")
                }
            }
        }
        .alert("Delete report?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteAndDismiss()
            }
        } message: {
            Text("This cannot be undone.")
        }
        .onAppear {
            if let r = report {
                caseNumber = r.caseNumber > 0 ? "\(r.caseNumber)" : ""
                decedentName = r.decedentName
                gender = r.gender
                age = r.age
                race = r.race
                dateOfDeath = r.dateOfDeath
                placeOfDeath = r.placeOfDeath
                facilityName = r.facilityName
                embalmerName = r.embalmerName
                dateOfEmbalming = r.dateOfEmbalming
                embalmingTimeFinish = r.embalmingTimeFinish
                bodyWeight = r.bodyWeight
                bodyType = r.bodyType
                conditionSummary = r.conditionSummary
                mouthClosure = r.mouthClosure
                eyeClosure = r.eyeClosure
                arteriesInjected = r.arteriesInjected
                veinsDrained = r.veinsDrained
                drainageMethod = r.drainageMethod
                aspiration = r.aspiration
                disinfectant = r.disinfectant
                arterialFluidUsed = r.arterialFluidUsed
                coInjection = r.coInjection
                cavityChemical = r.cavityChemical
                solutionDetails = r.solutionDetails
                conditionAfterEmbalming = r.conditionAfterEmbalming
                notes = r.notes
                conditionOfRemainsWhenReceived = r.conditionOfRemainsWhenReceived
                bodyMarks = CaseLogReport.decodeBodyMarks(r.bodyMarks)
                draftReportId = r.id
            } else if let p = prefill {
                draftReportId = UUID().uuidString
                conditionSummary = p.conditionSummary
                arterialFluidUsed = p.arterialFluidUsed
                solutionDetails = p.solutionDetails
                bodyWeight = p.bodyWeight
                bodyType = p.bodyType
            }
            if draftReportId.isEmpty {
                draftReportId = report?.id ?? UUID().uuidString
            }
            // New report: prepopulate case number (next), facility and embalmer from last-used defaults.
            if report == nil {
                caseNumber = "\(DatabaseManager.shared.getNextCaseNumber())"
                if facilityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !CaseLogDefaults.facility.isEmpty {
                    facilityName = CaseLogDefaults.facility
                }
                if embalmerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !CaseLogDefaults.embalmer.isEmpty {
                    embalmerName = CaseLogDefaults.embalmer
                }
            }
            // Initialize Date pickers from existing string values (or default to today)
            if let d = parseCaseLogDate(dateOfDeath) {
                dateOfDeathDate = d
            } else {
                setDateOfDeath(from: Date())
            }
            if let d = parseCaseLogDate(dateOfEmbalming) {
                dateOfEmbalmingDate = d
            } else if let dod = parseCaseLogDate(dateOfDeath) {
                // Prefill embalming date from date of death if not set
                setDateOfEmbalming(from: dod)
            } else {
                setDateOfEmbalming(from: Date())
            }
            loadCoInjectionOptionsIfNeeded()
            loadCavityChemicalOptionsIfNeeded()
            loadDisinfectantOptionsIfNeeded()
            recentPlacesOfDeath = CaseLogDefaults.placesOfDeath
        }
    }

    private func t(_ s: String) -> String { s.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Updates stored defaults from current facility/embalmer so next new report is prepopulated.
    private func saveDefaultsFromCurrentForm() {
        let fac = t(facilityName)
        let emb = t(embalmerName)
        if !fac.isEmpty { CaseLogDefaults.facility = fac }
        if !emb.isEmpty { CaseLogDefaults.embalmer = emb }
        addCurrentPlaceOfDeathToRecents()
    }

    /// Builds the current report from form state (for printing, including unsaved edits).
    private func currentReportForPrint() -> CaseLogReport {
        let now = Date()
        return CaseLogReport(
            id: reportId,
            createdAt: report?.createdAt ?? now,
            updatedAt: report?.updatedAt ?? now,
            caseNumber: Int(caseNumber.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0,
            decedentName: t(decedentName),
            gender: t(gender),
            age: t(age),
            race: t(race),
            dateOfDeath: t(dateOfDeath),
            placeOfDeath: t(placeOfDeath),
            facilityName: t(facilityName),
            embalmerName: t(embalmerName),
            dateOfEmbalming: t(dateOfEmbalming),
            embalmingTimeFinish: t(embalmingTimeFinish),
            bodyWeight: t(bodyWeight),
            bodyType: t(bodyType),
            conditionSummary: t(conditionSummary),
            mouthClosure: t(mouthClosure),
            eyeClosure: t(eyeClosure),
            arteriesInjected: t(arteriesInjected),
            veinsDrained: t(veinsDrained),
            drainageMethod: t(drainageMethod),
            aspiration: t(aspiration),
            disinfectant: t(disinfectant),
            arterialFluidUsed: t(arterialFluidUsed),
            coInjection: t(coInjection),
            cavityChemical: t(cavityChemical),
            solutionDetails: t(solutionDetails),
            conditionAfterEmbalming: t(conditionAfterEmbalming),
            notes: t(notes),
            conditionOfRemainsWhenReceived: t(conditionOfRemainsWhenReceived),
            bodyMarks: CaseLogReport.encodeBodyMarks(bodyMarks)
        )
    }

    private func save() {
        let now = Date()
        if let existing = report {
            var updated = existing
            updated.updatedAt = now
            updated.caseNumber = Int(caseNumber.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            updated.decedentName = t(decedentName)
            updated.gender = t(gender)
            updated.age = t(age)
            updated.race = t(race)
            updated.dateOfDeath = t(dateOfDeath)
            updated.placeOfDeath = t(placeOfDeath)
            updated.facilityName = t(facilityName)
            updated.embalmerName = t(embalmerName)
            updated.dateOfEmbalming = t(dateOfEmbalming)
            updated.embalmingTimeFinish = t(embalmingTimeFinish)
            updated.bodyWeight = t(bodyWeight)
            updated.bodyType = t(bodyType)
            updated.conditionSummary = t(conditionSummary)
            updated.mouthClosure = t(mouthClosure)
            updated.eyeClosure = t(eyeClosure)
            updated.arteriesInjected = t(arteriesInjected)
            updated.veinsDrained = t(veinsDrained)
            updated.drainageMethod = t(drainageMethod)
            updated.aspiration = t(aspiration)
            updated.disinfectant = t(disinfectant)
            updated.arterialFluidUsed = t(arterialFluidUsed)
            updated.coInjection = t(coInjection)
            updated.cavityChemical = t(cavityChemical)
            updated.solutionDetails = t(solutionDetails)
            updated.conditionAfterEmbalming = t(conditionAfterEmbalming)
            updated.notes = t(notes)
            updated.conditionOfRemainsWhenReceived = t(conditionOfRemainsWhenReceived)
            updated.bodyMarks = CaseLogReport.encodeBodyMarks(bodyMarks)
            _ = DatabaseManager.shared.updateCaseLogReport(updated)
            saveDefaultsFromCurrentForm()
        } else {
            let newReport = CaseLogReport(
                id: draftReportId,
                createdAt: now,
                updatedAt: now,
                caseNumber: Int(caseNumber.trimmingCharacters(in: .whitespacesAndNewlines)) ?? DatabaseManager.shared.getNextCaseNumber(),
                decedentName: t(decedentName),
                gender: t(gender),
                age: t(age),
                race: t(race),
                dateOfDeath: t(dateOfDeath),
                placeOfDeath: t(placeOfDeath),
                facilityName: t(facilityName),
                embalmerName: t(embalmerName),
                dateOfEmbalming: t(dateOfEmbalming),
                embalmingTimeFinish: t(embalmingTimeFinish),
                bodyWeight: t(bodyWeight),
                bodyType: t(bodyType),
                conditionSummary: t(conditionSummary),
                mouthClosure: t(mouthClosure),
                eyeClosure: t(eyeClosure),
                arteriesInjected: t(arteriesInjected),
                veinsDrained: t(veinsDrained),
                drainageMethod: t(drainageMethod),
                aspiration: t(aspiration),
                disinfectant: t(disinfectant),
                arterialFluidUsed: t(arterialFluidUsed),
                coInjection: t(coInjection),
                cavityChemical: t(cavityChemical),
                solutionDetails: t(solutionDetails),
                conditionAfterEmbalming: t(conditionAfterEmbalming),
                notes: t(notes),
                conditionOfRemainsWhenReceived: t(conditionOfRemainsWhenReceived),
                bodyMarks: CaseLogReport.encodeBodyMarks(bodyMarks)
            )
            _ = DatabaseManager.shared.insertCaseLogReport(newReport)
            saveDefaultsFromCurrentForm()
        }
        onDismiss()
        dismiss()
    }

    private func deleteAndDismiss() {
        _ = DatabaseManager.shared.deleteCaseLogReport(id: reportId)
        onDismiss()
        dismiss()
    }
}

// MARK: - Tappable body outline (tap to add numbered shaded areas; tap only on image so scroll works)
private struct TappableBodyView: View {
    let imageName: String
    let side: String
    @Binding var marks: [BodyMark]

    private var bodyHeight: CGFloat {
        min(UIScreen.main.bounds.height * 0.48, 480)
    }

    private var marksOnThisSide: [BodyMark] {
        marks.filter { $0.side == side }
    }

    /// Normalized (0-1) hit threshold: tap within this distance of a mark removes it.
    private let removeHitThreshold: Double = 0.08

    /// Fitted rect of the image within (width, height) when scaled to fit.
    private static func imageRect(containerWidth w: CGFloat, containerHeight h: CGFloat, imageName: String) -> CGRect {
        guard let img = UIImage(named: imageName), img.size.height > 0 else {
            return CGRect(x: 0, y: 0, width: w, height: h)
        }
        let aspect = img.size.width / img.size.height
        let viewAspect = w / h
        let fitW: CGFloat
        let fitH: CGFloat
        if aspect > viewAspect {
            fitW = w
            fitH = w / aspect
        } else {
            fitH = h
            fitW = h * aspect
        }
        return CGRect(x: (w - fitW) / 2, y: (h - fitH) / 2, width: fitW, height: fitH)
    }

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            let imageRect = Self.imageRect(containerWidth: w, containerHeight: h, imageName: imageName)
            ZStack(alignment: .topLeading) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(AppStyle.CornerRadius.small)
                    .clipped()
                ForEach(marksOnThisSide) { mark in
                    let x = imageRect.minX + CGFloat(mark.x) * imageRect.width
                    let y = imageRect.minY + CGFloat(mark.y) * imageRect.height
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.5))
                            .frame(width: 26, height: 26)
                        Text("\(mark.number)")
                            .font(.system(.body, design: .rounded).weight(.bold))
                            .foregroundColor(.primary)
                    }
                    .position(x: x, y: y)
                }
                Color.clear
                    .contentShape(Rectangle())
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                // Ignore scrolls: only add/remove on taps (minimal movement)
                                let distance = hypot(value.translation.width, value.translation.height)
                                if distance > 12 { return }
                                let loc = value.startLocation
                                guard imageRect.contains(loc) else { return }
                                let nx = Double((loc.x - imageRect.minX) / imageRect.width).clamped(to: 0.0...1.0)
                                let ny = Double((loc.y - imageRect.minY) / imageRect.height).clamped(to: 0.0...1.0)
                                let onSide = marksOnThisSide
                                if let hit = onSide.first(where: { mark in
                                    let dx = mark.x - nx
                                    let dy = mark.y - ny
                                    return (dx * dx + dy * dy) <= (removeHitThreshold * removeHitThreshold)
                                }) {
                                    marks.removeAll { $0.id == hit.id }
                                } else {
                                    let nextNum = (marks.map(\.number).max() ?? 0) + 1
                                    marks.append(BodyMark(number: nextNum, x: nx, y: ny, side: side))
                                }
                            }
                    )
            }
        }
        .frame(height: bodyHeight)
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

#Preview("New report") {
    NavigationStack {
        CaseLogDetailView(report: nil) {}
    }
}

#Preview("Edit report") {
    NavigationStack {
        CaseLogDetailView(report: CaseLogReport(
            decedentName: "Sample",
            dateOfEmbalming: "2/28/2025",
            conditionSummary: "Routine",
            arterialFluidUsed: "Product A, 1 gallon",
            notes: "Notes here"
        )) {}
    }
}

