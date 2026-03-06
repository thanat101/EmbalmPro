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

    static var facility: String {
        get { UserDefaults.standard.string(forKey: facilityKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: facilityKey) }
    }

    static var embalmer: String {
        get { UserDefaults.standard.string(forKey: embalmerKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: embalmerKey) }
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

    private var isNewReport: Bool { report == nil }
    private var reportId: String { report?.id ?? draftReportId }

    var body: some View {
        Form {
            // MARK: Case number (top, editable)
            Section {
                LabeledField(title: "Case number", text: $caseNumber, placeholder: "Auto-assigned for new cases")
                    .keyboardType(.numberPad)
            } header: {
                Text("Case number")
            } footer: {
                Text("Optional. New cases get the next number automatically; you can edit it.")
            }

            // MARK: Section 1 – Decedent & death
            Section {
                LabeledField(title: "Decedent name", text: $decedentName)
                LabeledField(title: "Gender", text: $gender)
                LabeledField(title: "Age", text: $age)
                LabeledField(title: "Race", text: $race)
                LabeledField(title: "Date of death", text: $dateOfDeath)
                LabeledField(title: "Place of death", text: $placeOfDeath)
            } header: {
                Text("Decedent & death")
            } footer: {
                Text("Decedent identification and death information.")
            }

            // MARK: Section 2 – Facility & embalmer
            Section {
                LabeledField(title: "Facility name", text: $facilityName)
                LabeledField(title: "Embalmer name", text: $embalmerName)
                LabeledField(title: "Embalming date", text: $dateOfEmbalming)
                LabeledField(title: "Embalming time / finish", text: $embalmingTimeFinish, placeholder: "e.g. start – finish")
            } header: {
                Text("Facility & embalmer")
            } footer: {
                Text("Where the case was performed and who performed it.")
            }

            // MARK: Section 3 – Body & condition
            Section {
                LabeledField(title: "Body weight", text: $bodyWeight, placeholder: "e.g. 200 lb")
                LabeledField(title: "Body type", text: $bodyType, placeholder: "e.g. Average, High BMI, All Muscle")
                LabeledField(title: "Condition / case type summary", text: $conditionSummary, axis: .vertical, lineLimit: 2...5)
            } header: {
                Text("Body & condition")
            } footer: {
                Text("Body characteristics and condition before embalming.")
            }

            // MARK: Section 4 – Fluids & solution
            Section {
                LabeledField(title: "Arterial fluid used", text: $arterialFluidUsed, axis: .vertical, lineLimit: 2...5)
                LabeledField(title: "Co-injection", text: $coInjection)
                LabeledField(title: "Cavity chemical", text: $cavityChemical)
                LabeledField(title: "Solution / calculation details", text: $solutionDetails, placeholder: "e.g. Fluid Index, strength %, oz per gallon", axis: .vertical, lineLimit: 2...5)
                LabeledField(title: "Disinfectant", text: $disinfectant)
            } header: {
                Text("Fluids & solution")
            } footer: {
                Text("Arterial, co-injection, cavity, and solution details. Solution details are often prefilled from CH₂O Calculator.")
            }

            // MARK: Section 5 – Closure & technique
            Section {
                LabeledField(title: "Mouth closure", text: $mouthClosure, placeholder: "Injector needle or Ligature")
                LabeledField(title: "Eye closure", text: $eyeClosure)
                LabeledField(title: "Arteries injected", text: $arteriesInjected)
                LabeledField(title: "Veins drained", text: $veinsDrained)
                LabeledField(title: "Drainage method", text: $drainageMethod)
                LabeledField(title: "Aspiration", text: $aspiration, placeholder: "Delayed or Immediate")
            } header: {
                Text("Closure & technique")
            } footer: {
                Text("Mouth and eye closure; injection and drainage technique.")
            }

            // MARK: Section 6 – After embalming & notes
            Section {
                LabeledField(title: "Condition after embalming", text: $conditionAfterEmbalming, axis: .vertical, lineLimit: 2...5)
                LabeledField(title: "Embalmer notes", text: $notes, axis: .vertical, lineLimit: 4...10)
            } header: {
                Text("After embalming & notes")
            } footer: {
                Text("Final condition and any additional notes.")
            }

            // MARK: Section – Body outlines (tap to add numbered areas), then condition below
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

            if !isNewReport {
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete report", systemImage: "trash")
                    }
                }
            }
        }
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
        }
    }

    private func t(_ s: String) -> String { s.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Updates stored defaults from current facility/embalmer so next new report is prepopulated.
    private func saveDefaultsFromCurrentForm() {
        let fac = t(facilityName)
        let emb = t(embalmerName)
        if !fac.isEmpty { CaseLogDefaults.facility = fac }
        if !emb.isEmpty { CaseLogDefaults.embalmer = emb }
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
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
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

