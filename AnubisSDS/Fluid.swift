import Foundation

struct Fluid: Identifiable, Codable {
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
    
    // Coding keys for database mapping
    private enum CodingKeys: String, CodingKey {
        case id = "UNIQUE_ID"
        case name = "FLUID"
        case manufacturer = "MANUFACTURER"
        case emergencyContact = "EMERGENCY_CONTACT"
        case date = "DATE"
        case filename = "FILENAME"
        case identification = "IDENTIFICATION"
        case hazards = "HAZARDS"
        case composition = "COMPOSITION"
        case firstAid = "FIRSTAID"
        case fire = "FIRE"
        case accident = "ACCIDENT"
        case handling = "HANDLING"
        case exposure = "EXPOSURE"
        case properties = "PROPERTIES"
        case stability = "STABILITY"
        case toxicology = "TOXICOLOGY"
        case ecology = "ECOLOGY"
        case disposal = "DISPOSAL"
        case transport = "TRANSPORT"
        case regulation = "REGULATION"
        case other = "OTHER"
        case index = "INDEX"
        case use = "USE"
        case type = "TYPE"
    }
    
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
        if let indexValue = dictionary["INDEX"] as? Double {
            self.index = indexValue
        } else if let indexString = dictionary["INDEX"] as? String,
                  let indexValue = Double(indexString) {
            self.index = indexValue
        } else {
            self.index = nil
        }
        self.use = dictionary["USE"] as? String
        self.type = dictionary["TYPE"] as? String
    }
    
    // Custom init from decoder for Codable conformance
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        let idValue = try container.decode(Int64.self, forKey: .id)
        self.id = Int(idValue)
        self.name = try container.decode(String.self, forKey: .name)
        self.manufacturer = try container.decode(String.self, forKey: .manufacturer)
        
        // Optional fields
        self.emergencyContact = try container.decodeIfPresent(String.self, forKey: .emergencyContact)
        self.date = try container.decodeIfPresent(String.self, forKey: .date)
        self.filename = try container.decodeIfPresent(String.self, forKey: .filename)
        self.identification = try container.decodeIfPresent(String.self, forKey: .identification)
        self.hazards = try container.decodeIfPresent(String.self, forKey: .hazards)
        self.composition = try container.decodeIfPresent(String.self, forKey: .composition)
        self.firstAid = try container.decodeIfPresent(String.self, forKey: .firstAid)
        self.fire = try container.decodeIfPresent(String.self, forKey: .fire)
        self.accident = try container.decodeIfPresent(String.self, forKey: .accident)
        self.handling = try container.decodeIfPresent(String.self, forKey: .handling)
        self.exposure = try container.decodeIfPresent(String.self, forKey: .exposure)
        self.properties = try container.decodeIfPresent(String.self, forKey: .properties)
        self.stability = try container.decodeIfPresent(String.self, forKey: .stability)
        self.toxicology = try container.decodeIfPresent(String.self, forKey: .toxicology)
        self.ecology = try container.decodeIfPresent(String.self, forKey: .ecology)
        self.disposal = try container.decodeIfPresent(String.self, forKey: .disposal)
        self.transport = try container.decodeIfPresent(String.self, forKey: .transport)
        self.regulation = try container.decodeIfPresent(String.self, forKey: .regulation)
        self.other = try container.decodeIfPresent(String.self, forKey: .other)
        self.index = try container.decodeIfPresent(Double.self, forKey: .index)
        self.use = try container.decodeIfPresent(String.self, forKey: .use)
        self.type = try container.decodeIfPresent(String.self, forKey: .type)
    }
    
    // Custom encode method for Codable conformance
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        try container.encode(Int64(id), forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(manufacturer, forKey: .manufacturer)
        
        // Optional fields
        try container.encodeIfPresent(emergencyContact, forKey: .emergencyContact)
        try container.encodeIfPresent(date, forKey: .date)
        try container.encodeIfPresent(filename, forKey: .filename)
        try container.encodeIfPresent(identification, forKey: .identification)
        try container.encodeIfPresent(hazards, forKey: .hazards)
        try container.encodeIfPresent(composition, forKey: .composition)
        try container.encodeIfPresent(firstAid, forKey: .firstAid)
        try container.encodeIfPresent(fire, forKey: .fire)
        try container.encodeIfPresent(accident, forKey: .accident)
        try container.encodeIfPresent(handling, forKey: .handling)
        try container.encodeIfPresent(exposure, forKey: .exposure)
        try container.encodeIfPresent(properties, forKey: .properties)
        try container.encodeIfPresent(stability, forKey: .stability)
        try container.encodeIfPresent(toxicology, forKey: .toxicology)
        try container.encodeIfPresent(ecology, forKey: .ecology)
        try container.encodeIfPresent(disposal, forKey: .disposal)
        try container.encodeIfPresent(transport, forKey: .transport)
        try container.encodeIfPresent(regulation, forKey: .regulation)
        try container.encodeIfPresent(other, forKey: .other)
        try container.encodeIfPresent(index, forKey: .index)
        try container.encodeIfPresent(use, forKey: .use)
        try container.encodeIfPresent(type, forKey: .type)
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