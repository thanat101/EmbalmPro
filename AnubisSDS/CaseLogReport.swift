import Foundation

/// A single mark on a body outline (front/back); number and normalized position for "condition when received".
struct BodyMark: Identifiable, Codable, Hashable {
    var id: String { "\(side)-\(number)" }
    let number: Int
    let x: Double
    let y: Double
    let side: String
}

/// A single Case Log / Embalmer's Report entry.
struct CaseLogReport: Identifiable, Codable, Hashable {
    let id: String
    var createdAt: Date
    var updatedAt: Date
    /// User-visible case number (editable). 0 = not set (e.g. pre-migration reports).
    var caseNumber: Int
    // Decedent
    var decedentName: String
    var gender: String
    var age: String
    var race: String
    // Death
    var dateOfDeath: String
    var placeOfDeath: String
    // Facility & embalmer
    var facilityName: String
    var embalmerName: String
    var dateOfEmbalming: String
    var embalmingTimeFinish: String
    // Body / pre-embalming
    var bodyWeight: String
    var bodyType: String
    var conditionSummary: String
    // Closure & technique
    var mouthClosure: String
    var eyeClosure: String
    var arteriesInjected: String
    var veinsDrained: String
    var drainageMethod: String
    var aspiration: String
    var disinfectant: String
    // Fluids & chemicals (product names and amounts)
    var arterialFluidUsed: String
    var coInjection: String
    var cavityChemical: String
    var solutionDetails: String
    // After embalming
    var conditionAfterEmbalming: String
    var notes: String
    // Condition when received
    var conditionOfRemainsWhenReceived: String
    /// JSON array of BodyMark for body outlines (tap-to-number areas).
    var bodyMarks: String

    init(
        id: String = UUID().uuidString,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        caseNumber: Int = 0,
        decedentName: String = "",
        gender: String = "",
        age: String = "",
        race: String = "",
        dateOfDeath: String = "",
        placeOfDeath: String = "",
        facilityName: String = "",
        embalmerName: String = "",
        dateOfEmbalming: String = "",
        embalmingTimeFinish: String = "",
        bodyWeight: String = "",
        bodyType: String = "",
        conditionSummary: String = "",
        mouthClosure: String = "",
        eyeClosure: String = "",
        arteriesInjected: String = "",
        veinsDrained: String = "",
        drainageMethod: String = "",
        aspiration: String = "",
        disinfectant: String = "",
        arterialFluidUsed: String = "",
        coInjection: String = "",
        cavityChemical: String = "",
        solutionDetails: String = "",
        conditionAfterEmbalming: String = "",
        notes: String = "",
        conditionOfRemainsWhenReceived: String = "",
        bodyMarks: String = "[]"
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.caseNumber = caseNumber
        self.decedentName = decedentName
        self.gender = gender
        self.age = age
        self.race = race
        self.dateOfDeath = dateOfDeath
        self.placeOfDeath = placeOfDeath
        self.facilityName = facilityName
        self.embalmerName = embalmerName
        self.dateOfEmbalming = dateOfEmbalming
        self.embalmingTimeFinish = embalmingTimeFinish
        self.bodyWeight = bodyWeight
        self.bodyType = bodyType
        self.conditionSummary = conditionSummary
        self.mouthClosure = mouthClosure
        self.eyeClosure = eyeClosure
        self.arteriesInjected = arteriesInjected
        self.veinsDrained = veinsDrained
        self.drainageMethod = drainageMethod
        self.aspiration = aspiration
        self.disinfectant = disinfectant
        self.arterialFluidUsed = arterialFluidUsed
        self.coInjection = coInjection
        self.cavityChemical = cavityChemical
        self.solutionDetails = solutionDetails
        self.conditionAfterEmbalming = conditionAfterEmbalming
        self.notes = notes
        self.conditionOfRemainsWhenReceived = conditionOfRemainsWhenReceived
        self.bodyMarks = bodyMarks
    }

    /// Decode body marks from stored JSON.
    static func decodeBodyMarks(_ json: String) -> [BodyMark] {
        guard let data = json.data(using: .utf8),
              let arr = try? JSONDecoder().decode([BodyMark].self, from: data) else { return [] }
        return arr
    }

    /// Encode body marks to JSON for storage.
    static func encodeBodyMarks(_ marks: [BodyMark]) -> String {
        guard let data = try? JSONEncoder().encode(marks),
              let s = String(data: data, encoding: .utf8) else { return "[]" }
        return s
    }

    /// Display title for list: decedent name or "Untitled" with date.
    var listTitle: String {
        if !decedentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return decedentName
        }
        return "Untitled"
    }

    /// Short subtitle for list (e.g. date of embalming or created date).
    var listSubtitle: String {
        if !dateOfEmbalming.isEmpty { return dateOfEmbalming }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: createdAt)
    }
}

/// Optional prefill when creating a new Case Log from Case Analysis → CH₂O (Suggested Fluids).
struct CaseLogPrefill {
    var conditionSummary: String = ""
    var arterialFluidUsed: String = ""
    /// Fluid index, strength, oz/gal, method, volume (prefilled under Condition & fluids).
    var solutionDetails: String = ""
    var notes: String = ""
    var bodyWeight: String = ""
    var bodyType: String = ""
}
