import Foundation

struct Fluid: Identifiable {
    let id: Int
    let name: String
    let manufacturer: String
    let emergencyContact: String?
    let date: String?
    let filename: String?
    
    // SDS Sections
    let identification: String?
    let hazards: String?
    let composition: String?
    let firstAid: String?
    let fire: String?
    let accident: String?
    let handling: String?
    let exposure: String?
    let properties: String?
    let stability: String?
    let toxicology: String?
    let ecology: String?
    let disposal: String?
    let transport: String?
    let regulation: String?
    let other: String?
    
    // Additional fields
    let index: Double?
    let use: String?
    let type: String?
    
    init?(from dictionary: [String: Any]) {
        guard let id = dictionary["UNIQUE_ID"] as? Int64,
              let name = dictionary["FLUID"] as? String,
              let manufacturer = dictionary["MANUFACTURER"] as? String else {
            print("Failed to create Fluid. Dictionary: \(dictionary)")
            return nil
        }
        
        self.id = Int(id)
        self.name = name
        self.manufacturer = manufacturer
        
        // SDS fields
        self.emergencyContact = dictionary["EMERGENCY_CONTACT"] as? String
        self.date = dictionary["DATE"] as? String
        self.filename = dictionary["FILENAME"] as? String
        self.identification = dictionary["IDENTIFICATION"] as? String
        self.hazards = dictionary["HAZARDS"] as? String
        self.composition = dictionary["COMPOSITION"] as? String
        self.firstAid = dictionary["FIRSTAID"] as? String
        self.fire = dictionary["FIRE"] as? String
        self.accident = dictionary["ACCIDENT"] as? String
        self.handling = dictionary["HANDLING"] as? String
        self.exposure = dictionary["EXPOSURE"] as? String
        self.properties = dictionary["PROPERTIES"] as? String
        self.stability = dictionary["STABILITY"] as? String
        self.toxicology = dictionary["TOXICOLOGY"] as? String
        self.ecology = dictionary["ECOLOGY"] as? String
        self.disposal = dictionary["DISPOSAL"] as? String
        self.transport = dictionary["TRANSPORT"] as? String
        self.regulation = dictionary["REGULATION"] as? String
        self.other = dictionary["OTHER"] as? String
        
        // Additional fields
        self.index = dictionary["INDEX"] as? Double
        self.use = dictionary["USE"] as? String
        self.type = dictionary["TYPE"] as? String
    }
    
    var formattedIndex: String {
        if let index = index {
            return index.truncatingRemainder(dividingBy: 1) == 0 ? 
                String(format: "%.0f", index) : 
                String(format: "%.1f", index)
        }
        return ""
    }
} 