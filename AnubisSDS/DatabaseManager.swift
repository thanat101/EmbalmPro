import Foundation
import SQLite3

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: OpaquePointer?
    private let databaseVersion = 9 // 8 = drop fluidsUsed; 9 = caseNumber
    
    // Add static cache for fluids
    private static var cachedFluids: [Fluid]?
    private static var cachedFluidsHeaders: [String] = []
    private static var cachedFluidsRows: [[String]] = []
    
    // Add CacheData struct for proper encoding/decoding
    private struct CacheData: Codable {
        let fluids: [Fluid]
        let headers: [String]
        let rows: [[String]]
        let timestamp: Date
    }
    
    private var cacheURL: URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("fluidsCache.json")
    }
    
    private init() {
        setupDatabase()
    }
    
    private func setupDatabase() {
        print("\n=== Setting up Database ===")
        
        // Get the documents directory path
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("❌ Could not get documents directory path")
            return
        }
        
        let databaseURL = documentsPath.appendingPathComponent("data.db")
        print("📁 Database path: \(databaseURL.path)")
        
        // Check if database exists in documents
        let fileManager = FileManager.default
        let databaseExists = fileManager.fileExists(atPath: databaseURL.path)
        
        if !databaseExists {
            print("📦 Database not found in documents, copying from bundle...")
            
            // Get the bundle database path
            guard let bundlePath = Bundle.main.path(forResource: "data", ofType: "db") else {
                print("❌ Could not find database in bundle")
                return
            }
            
            do {
                // Copy database from bundle to documents
                try fileManager.copyItem(atPath: bundlePath, toPath: databaseURL.path)
                print("✅ Successfully copied database to documents")
                
                // Create a backup of the original database
                let backupURL = documentsPath.appendingPathComponent("data.db.backup")
                try fileManager.copyItem(atPath: bundlePath, toPath: backupURL.path)
                print("✅ Created backup of original database")
                
                // Don't set version yet; migrations will run after open and set it
            } catch {
                print("❌ Failed to copy database: \(error.localizedDescription)")
                return
            }
        } else {
            print("📁 Using existing database in documents")
        }
        
        // Open the database
        if sqlite3_open(databaseURL.path, &db) == SQLITE_OK {
            print("✅ Successfully opened database")
            
            // Run migrations if needed (first install or upgrade)
            let currentVersion = UserDefaults.standard.integer(forKey: "databaseVersion")
            if currentVersion < databaseVersion {
                print("🔄 Database needs update from version \(currentVersion) to \(databaseVersion)")
                runMigrations(from: currentVersion, to: databaseVersion)
                UserDefaults.standard.set(databaseVersion, forKey: "databaseVersion")
            }
            
            // Enable foreign keys
            if sqlite3_exec(db, "PRAGMA foreign_keys = ON;", nil, nil, nil) == SQLITE_OK {
                print("✅ Enabled foreign key support")
            } else {
                print("⚠️ Failed to enable foreign key support")
            }
        } else {
            print("❌ Failed to open database")
            if let error = sqlite3_errmsg(db) {
                print("Error: \(String(cString: error))")
            }
        }
        
        print("=== Database Setup Complete ===\n")
    }

    private func runMigrations(from currentVersion: Int, to targetVersion: Int) {
        guard let db = db else { return }
        // Migration to v2: create Case Log (Embalmer's Report) table
        if currentVersion < 2 && targetVersion >= 2 {
            let createTable = """
            CREATE TABLE IF NOT EXISTS CASE_LOG (
                id TEXT PRIMARY KEY,
                createdAt TEXT NOT NULL,
                updatedAt TEXT NOT NULL,
                decedentName TEXT NOT NULL,
                dateOfDeath TEXT,
                dateOfEmbalming TEXT,
                conditionSummary TEXT,
                fluidsUsed TEXT,
                notes TEXT,
                facilityName TEXT
            );
            """
            if sqlite3_exec(db, createTable, nil, nil, nil) == SQLITE_OK {
                print("✅ Created CASE_LOG table")
            } else if let err = sqlite3_errmsg(db) {
                print("❌ CASE_LOG migration failed: \(String(cString: err))")
            }
        }
        // Migration to v3: add bodyWeight and bodyType to CASE_LOG
        if currentVersion < 3 && targetVersion >= 3 {
            if sqlite3_exec(db, "ALTER TABLE CASE_LOG ADD COLUMN bodyWeight TEXT;", nil, nil, nil) == SQLITE_OK {
                print("✅ Added CASE_LOG.bodyWeight")
            }
            if sqlite3_exec(db, "ALTER TABLE CASE_LOG ADD COLUMN bodyType TEXT;", nil, nil, nil) == SQLITE_OK {
                print("✅ Added CASE_LOG.bodyType")
            }
        }
        if currentVersion < 4 && targetVersion >= 4 {
            if sqlite3_exec(db, "ALTER TABLE CASE_LOG ADD COLUMN solutionDetails TEXT;", nil, nil, nil) == SQLITE_OK {
                print("✅ Added CASE_LOG.solutionDetails")
            }
        }
        if currentVersion < 5 && targetVersion >= 5 {
            let v5Columns = [
                "gender", "age", "race", "placeOfDeath", "embalmerName", "embalmingTimeFinish",
                "mouthClosure", "eyeClosure", "arteriesInjected", "veinsDrained", "drainageMethod",
                "aspiration", "disinfectant", "arterialFluidUsed", "coInjection", "cavityChemical",
                "conditionAfterEmbalming"
            ]
            for col in v5Columns {
                if sqlite3_exec(db, "ALTER TABLE CASE_LOG ADD COLUMN \(col) TEXT;", nil, nil, nil) == SQLITE_OK {
                    print("✅ Added CASE_LOG.\(col)")
                }
            }
        }
        if currentVersion < 6 && targetVersion >= 6 {
            if sqlite3_exec(db, "ALTER TABLE CASE_LOG ADD COLUMN conditionOfRemainsWhenReceived TEXT;", nil, nil, nil) == SQLITE_OK {
                print("✅ Added CASE_LOG.conditionOfRemainsWhenReceived")
            }
        }
        if currentVersion < 7 && targetVersion >= 7 {
            if sqlite3_exec(db, "ALTER TABLE CASE_LOG ADD COLUMN bodyMarks TEXT;", nil, nil, nil) == SQLITE_OK {
                print("✅ Added CASE_LOG.bodyMarks")
            }
        }
        if currentVersion < 8 && targetVersion >= 8 {
            // Merge fluidsUsed into arterialFluidUsed when arterial is empty, then drop fluidsUsed
            if sqlite3_exec(db, "UPDATE CASE_LOG SET arterialFluidUsed = CASE WHEN COALESCE(trim(arterialFluidUsed), '') = '' THEN COALESCE(fluidsUsed, '') ELSE arterialFluidUsed END;", nil, nil, nil) == SQLITE_OK {
                print("✅ Merged CASE_LOG.fluidsUsed into arterialFluidUsed")
            }
            if sqlite3_exec(db, "ALTER TABLE CASE_LOG DROP COLUMN fluidsUsed;", nil, nil, nil) == SQLITE_OK {
                print("✅ Dropped CASE_LOG.fluidsUsed")
            } else if let err = sqlite3_errmsg(db) {
                print("⚠️ DROP COLUMN fluidsUsed: \(String(cString: err))")
            }
        }
        if currentVersion < 9 && targetVersion >= 9 {
            if sqlite3_exec(db, "ALTER TABLE CASE_LOG ADD COLUMN caseNumber INTEGER;", nil, nil, nil) == SQLITE_OK {
                print("✅ Added CASE_LOG.caseNumber")
            }
            // Backfill: assign 1, 2, 3... by createdAt order
            if sqlite3_exec(db, "UPDATE CASE_LOG SET caseNumber = (SELECT COUNT(*) FROM CASE_LOG c2 WHERE c2.createdAt <= CASE_LOG.createdAt);", nil, nil, nil) == SQLITE_OK {
                print("✅ Backfilled CASE_LOG.caseNumber by createdAt")
            }
        }
    }
    
    // Function to reset database to original state
    func resetDatabase() -> Bool {
        print("\n=== Resetting Database ===")
        
        // Close current database connection
        if let db = db {
            sqlite3_close(db)
            self.db = nil
        }
        
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("❌ Could not get documents directory path")
            return false
        }
        
        let databaseURL = documentsPath.appendingPathComponent("data.db")
        let backupURL = documentsPath.appendingPathComponent("data.db.backup")
        let fileManager = FileManager.default
        
        do {
            // Get the bundle database path
            guard let bundlePath = Bundle.main.path(forResource: "data", ofType: "db") else {
                print("❌ Could not find database in bundle")
                return false
            }
            
            // Remove current database if it exists
            if fileManager.fileExists(atPath: databaseURL.path) {
                try fileManager.removeItem(at: databaseURL)
                print("✅ Removed current database")
            }
            
            // Always copy fresh from bundle
            try fileManager.copyItem(at: URL(fileURLWithPath: bundlePath), to: databaseURL)
            print("✅ Copied fresh database from bundle")
            
            // Create new backup of the fresh copy
            if fileManager.fileExists(atPath: backupURL.path) {
                try fileManager.removeItem(at: backupURL)
            }
            try fileManager.copyItem(at: databaseURL, to: backupURL)
            print("✅ Created new backup of fresh database")
            
            // Set version to 0 so setupDatabase() will run migrations (e.g. create CASE_LOG)
            UserDefaults.standard.set(0, forKey: "databaseVersion")
            
            // Clear any existing cache
            if let cacheURL = cacheURL, fileManager.fileExists(atPath: cacheURL.path) {
                try fileManager.removeItem(at: cacheURL)
                print("✅ Cleared existing cache")
            }
            
            // Reopen database
            setupDatabase()
            
            print("✅ Database reset complete - fresh copy from bundle")
        } catch {
            print("❌ Failed to reset database: \(error.localizedDescription)")
            return false
        }
        
        return true
    }
    
    deinit {
        if sqlite3_close(db) == SQLITE_OK {
            print("Database connection closed")
        }
    }
    
    // Add your database operations here
    func executeQuery(_ query: String) -> [[String: Any]]? {
        print("\n=== Executing Query ===")
        print("Query: \(query)")
        
        var statement: OpaquePointer?
        var results: [[String: Any]] = []
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            print("Query prepared successfully")
            var rowCount = 0
            
            while sqlite3_step(statement) == SQLITE_ROW {
                rowCount += 1
                var row: [String: Any] = [:]
                let columns = sqlite3_column_count(statement)
                
                for i in 0..<columns {
                    let columnName = String(cString: sqlite3_column_name(statement, i))
                    let columnType = sqlite3_column_type(statement, i)
                    
                    switch columnType {
                    case SQLITE_INTEGER:
                        row[columnName] = sqlite3_column_int64(statement, i)
                    case SQLITE_FLOAT:
                        row[columnName] = sqlite3_column_double(statement, i)
                    case SQLITE_TEXT:
                        if let text = sqlite3_column_text(statement, i) {
                            row[columnName] = String(cString: text)
                        }
                    case SQLITE_BLOB:
                        if let blob = sqlite3_column_blob(statement, i) {
                            let size = sqlite3_column_bytes(statement, i)
                            row[columnName] = Data(bytes: blob, count: Int(size))
                        }
                    case SQLITE_NULL:
                        row[columnName] = NSNull()
                    default:
                        break
                    }
                }
                results.append(row)
            }
            print("Query returned \(rowCount) rows")
        } else {
            if let error = sqlite3_errmsg(db) {
                print("Query preparation failed. SQLite error: \(String(cString: error))")
            } else {
                print("Query preparation failed. Unknown error.")
            }
        }
        
        sqlite3_finalize(statement)
        print("==============================\n")
        return results
    }
    
    // Test method to verify database connection and show table information
    private func testDatabaseConnection() -> Bool {
        // Get list of all tables
        let query = """
            SELECT name FROM sqlite_master 
            WHERE type='table' 
            AND name NOT LIKE 'sqlite_%'
        """
        
        if let results = executeQuery(query) {
            print("\n=== Database Connection Test ===")
            print("Found \(results.count) tables in the database:")
            
            if results.isEmpty {
                print("WARNING: No tables found in database!")
                return false
            }
            
            for (index, row) in results.enumerated() {
                if let tableName = row["name"] as? String {
                    print("\(index + 1). Table: \(tableName)")
                    
                    // Get column information for each table
                    if let columns = executeQuery("PRAGMA table_info(\(tableName))") {
                        print("   Columns:")
                        for column in columns {
                            if let name = column["name"] as? String,
                               let type = column["type"] as? String {
                                print("   - \(name) (\(type))")
                            }
                        }
                    }
                }
            }
            print("==============================\n")
            return true
        } else {
            print("Failed to query database tables")
            return false
        }
    }
    
    func updateFluid(fluidName: String, updates: [String: Any]) -> Bool {
        print("\n=== Updating Fluid ===")
        print("Fluid: \(fluidName)")
        print("Updates: \(updates)")
        
        var updateFields: [String] = []
        var updateValues: [Any] = []
        
        for (field, value) in updates {
            // Quote column names so reserved words (e.g. INDEX) are valid in SQLite
            updateFields.append("\"\(field)\" = ?")
            updateValues.append(value)
        }
        
        if updateFields.isEmpty {
            print("No fields to update")
            return false
        }
        
        let query = """
            UPDATE FLUID 
            SET \(updateFields.joined(separator: ", "))
            WHERE FLUID = ?
        """
        updateValues.append(fluidName)
        
        var statement: OpaquePointer?
        var success = false
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            // Bind all values
            for (index, value) in updateValues.enumerated() {
                let bindIndex = Int32(index + 1)
                switch value {
                case let stringValue as String:
                    sqlite3_bind_text(statement, bindIndex, (stringValue as NSString).utf8String, -1, nil)
                case let intValue as Int:
                    sqlite3_bind_int64(statement, bindIndex, Int64(intValue))
                case let doubleValue as Double:
                    sqlite3_bind_double(statement, bindIndex, doubleValue)
                case is NSNull:
                    sqlite3_bind_null(statement, bindIndex)
                default:
                    print("Unsupported value type for field at index \(index)")
                    continue
                }
            }
            
            // Execute the update
            if sqlite3_step(statement) == SQLITE_DONE {
                print("✅ Update successful")
                success = true
            } else {
                if let error = sqlite3_errmsg(db) {
                    print("❌ Update failed. SQLite error: \(String(cString: error))")
                } else {
                    print("❌ Update failed. Unknown error.")
                }
            }
        } else {
            if let error = sqlite3_errmsg(db) {
                print("❌ Query preparation failed. SQLite error: \(String(cString: error))")
            } else {
                print("❌ Query preparation failed. Unknown error.")
            }
        }
        
        sqlite3_finalize(statement)
        print("=== Finished Updating Fluid ===\n")
        return success
    }
    
    // Update saveChanges to use the current database connection
    private func saveChanges() {
        // The database is already in the documents directory and writable
        // No need to copy or reopen
        // ... rest of save logic ...
    }
    
    // Add method to get cached fluids
    func getCachedFluids() -> (fluids: [Fluid], headers: [String], rows: [[String]])? {
        guard let cacheURL = cacheURL,
              let data = try? Data(contentsOf: cacheURL),
              let cacheData = try? JSONDecoder().decode(CacheData.self, from: data) else {
            return nil
        }
        
        // Check if cache is older than 5 minutes
        if Date().timeIntervalSince(cacheData.timestamp) > 300 { // 5 minutes
            try? FileManager.default.removeItem(at: cacheURL)
            return nil
        }
        
        return (cacheData.fluids, cacheData.headers, cacheData.rows)
    }
    
    // Add a method to get a single fluid from cache
    func getCachedFluid(name: String) -> Fluid? {
        if let cached = getCachedFluids() {
            return cached.fluids.first { $0.name == name }
        }
        return nil
    }
    
    // Optimize the cache update to be more efficient
    func updateFluidsCache(force: Bool = false) {
        print("\n=== Updating Fluids Cache ===")
        
        // Check if we have a valid cache and not forcing refresh
        if !force, let _ = getCachedFluids() {
            print("Using existing cache (less than 5 minutes old)")
            return
        }
        
        // If forcing refresh or no valid cache, delete existing cache
        if let cacheURL = cacheURL, FileManager.default.fileExists(atPath: cacheURL.path) {
            try? FileManager.default.removeItem(at: cacheURL)
            print("🗑️ Deleted existing cache")
        }
        
        let query = """
            SELECT * FROM FLUID 
            ORDER BY TYPE DESC, FLUID ASC
        """
        
        print("\n=== Executing Query ===")
        print("Query: \(query)")
        
        if let results = executeQuery(query) {
            print("Query prepared successfully")
            print("Query returned \(results.count) rows")
            print("==============================\n")
            
            if !results.isEmpty {
                // Get headers from the first result
                let headers = Array(results[0].keys).sorted()
                
                // Convert results to rows and fluids
                let rows = results.map { dict in
                    headers.map { header in
                        if let value = dict[header] {
                            if let stringValue = value as? String {
                                return stringValue
                            } else if let doubleValue = value as? Double {
                                return String(doubleValue)
                            } else if let intValue = value as? Int64 {
                                return String(intValue)
                            }
                        }
                        return ""
                    }
                }
                
                let fluids = results.compactMap { Fluid(from: $0) }
                
                // Create and encode cache data
                let cacheData = CacheData(fluids: fluids, headers: headers, rows: rows, timestamp: Date())
                if let encodedData = try? JSONEncoder().encode(cacheData),
                   let cacheURL = cacheURL {
                    do {
                        try encodedData.write(to: cacheURL)
                        print("Raw query returned \(results.count) results")
                        print("Successfully cached \(fluids.count) fluids")
                    } catch {
                        print("Failed to write cache to file: \(error)")
                    }
                } else {
                    print("Failed to encode cache data or get cache URL")
                }
            }
        }
        print("=== Finished Updating Fluids Cache ===\n")
    }
    
    // Modify getFluid to use cache
    func getFluid(name: String) -> Fluid? {
        // First try to get from cache
        if let cachedFluids = DatabaseManager.cachedFluids {
            return cachedFluids.first { $0.name == name }
        }
        
        // If not in cache, query database
        guard let db = db else {
            print("❌ Database not available")
            return nil
        }
        
        let query = "SELECT * FROM FLUID WHERE FLUID = ?"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (name as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_ROW {
                // Create a dictionary with the required fields
                var dictionary: [String: Any] = [:]
                
                // Get column names
                let columnCount = sqlite3_column_count(statement)
                for i in 0..<columnCount {
                    if let columnName = sqlite3_column_name(statement, i) {
                        let name = String(cString: columnName)
                        let columnType = sqlite3_column_type(statement, i)
                        
                        switch columnType {
                        case SQLITE_INTEGER:
                            dictionary[name] = sqlite3_column_int64(statement, i)
                        case SQLITE_FLOAT:
                            dictionary[name] = sqlite3_column_double(statement, i)
                        case SQLITE_TEXT:
                            if let text = sqlite3_column_text(statement, i) {
                                dictionary[name] = String(cString: text)
                            }
                        case SQLITE_NULL:
                            dictionary[name] = NSNull()
                        default:
                            break
                        }
                    }
                }
                
                sqlite3_finalize(statement)
                
                // Create Fluid object using the dictionary initializer
                return Fluid(from: dictionary)
            }
            
            sqlite3_finalize(statement)
        }
        
        return nil
    }

    // MARK: - Case Log (Embalmer's Report)

    private static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    func fetchAllCaseLogReports() -> [CaseLogReport] {
        guard let db = db else { return [] }
        let query = "SELECT * FROM CASE_LOG ORDER BY updatedAt DESC"
        var statement: OpaquePointer?
        var results: [CaseLogReport] = []
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(statement) }
        while sqlite3_step(statement) == SQLITE_ROW {
            if let report = rowToCaseLogReport(statement) {
                results.append(report)
            }
        }
        return results
    }

    /// Returns max(caseNumber) + 1 for new reports; 1 if table is empty.
    func getNextCaseNumber() -> Int {
        guard let db = db else { return 1 }
        let query = "SELECT COALESCE(MAX(caseNumber), 0) + 1 FROM CASE_LOG"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else { return 1 }
        defer { sqlite3_finalize(statement) }
        if sqlite3_step(statement) == SQLITE_ROW {
            return Int(sqlite3_column_int(statement, 0))
        }
        return 1
    }

    /// Assumes current schema: 32 columns (through caseNumber). Column order matches migrations.
    private func rowToCaseLogReport(_ statement: OpaquePointer?) -> CaseLogReport? {
        guard let statement = statement else { return nil }
        func text(_ i: Int32) -> String {
            guard sqlite3_column_type(statement, i) == SQLITE_TEXT,
                  let c = sqlite3_column_text(statement, i) else { return "" }
            return String(cString: c)
        }
        let createdAt = Self.iso8601.date(from: text(1)) ?? Date()
        let updatedAt = Self.iso8601.date(from: text(2)) ?? Date()
        let caseNum = Int(sqlite3_column_int(statement, 31))
        return CaseLogReport(
            id: text(0),
            createdAt: createdAt,
            updatedAt: updatedAt,
            caseNumber: caseNum,
            decedentName: text(3),
            gender: text(12),
            age: text(13),
            race: text(14),
            dateOfDeath: text(4),
            placeOfDeath: text(15),
            facilityName: text(8),
            embalmerName: text(16),
            dateOfEmbalming: text(5),
            embalmingTimeFinish: text(17),
            bodyWeight: text(9),
            bodyType: text(10),
            conditionSummary: text(6),
            mouthClosure: text(18),
            eyeClosure: text(19),
            arteriesInjected: text(20),
            veinsDrained: text(21),
            drainageMethod: text(22),
            aspiration: text(23),
            disinfectant: text(24),
            arterialFluidUsed: text(25),
            coInjection: text(26),
            cavityChemical: text(27),
            solutionDetails: text(11),
            conditionAfterEmbalming: text(28),
            notes: text(7),
            conditionOfRemainsWhenReceived: text(29),
            bodyMarks: text(30)
        )
    }

    func insertCaseLogReport(_ report: CaseLogReport) -> Bool {
        guard let db = db else { return false }
        let query = """
        INSERT INTO CASE_LOG (id, createdAt, updatedAt, decedentName, gender, age, race, dateOfDeath, placeOfDeath, facilityName, embalmerName, dateOfEmbalming, embalmingTimeFinish, bodyWeight, bodyType, conditionSummary, mouthClosure, eyeClosure, arteriesInjected, veinsDrained, drainageMethod, aspiration, disinfectant, arterialFluidUsed, coInjection, cavityChemical, solutionDetails, conditionAfterEmbalming, notes, conditionOfRemainsWhenReceived, bodyMarks, caseNumber)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(statement) }
        bindReport(statement, report)
        return sqlite3_step(statement) == SQLITE_DONE
    }

    func updateCaseLogReport(_ report: CaseLogReport) -> Bool {
        guard let db = db else { return false }
        let query = """
        UPDATE CASE_LOG SET updatedAt=?, decedentName=?, gender=?, age=?, race=?, dateOfDeath=?, placeOfDeath=?, facilityName=?, embalmerName=?, dateOfEmbalming=?, embalmingTimeFinish=?, bodyWeight=?, bodyType=?, conditionSummary=?, mouthClosure=?, eyeClosure=?, arteriesInjected=?, veinsDrained=?, drainageMethod=?, aspiration=?, disinfectant=?, arterialFluidUsed=?, coInjection=?, cavityChemical=?, solutionDetails=?, conditionAfterEmbalming=?, notes=?, conditionOfRemainsWhenReceived=?, bodyMarks=?, caseNumber=?
        WHERE id=?
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(statement) }
        var idx: Int32 = 1
        let bind: (String) -> Void = { s in sqlite3_bind_text(statement, idx, (s as NSString).utf8String, -1, nil); idx += 1 }
        bind(Self.iso8601.string(from: report.updatedAt))
        bind(report.decedentName)
        bind(report.gender)
        bind(report.age)
        bind(report.race)
        bind(report.dateOfDeath)
        bind(report.placeOfDeath)
        bind(report.facilityName)
        bind(report.embalmerName)
        bind(report.dateOfEmbalming)
        bind(report.embalmingTimeFinish)
        bind(report.bodyWeight)
        bind(report.bodyType)
        bind(report.conditionSummary)
        bind(report.mouthClosure)
        bind(report.eyeClosure)
        bind(report.arteriesInjected)
        bind(report.veinsDrained)
        bind(report.drainageMethod)
        bind(report.aspiration)
        bind(report.disinfectant)
        bind(report.arterialFluidUsed)
        bind(report.coInjection)
        bind(report.cavityChemical)
        bind(report.solutionDetails)
        bind(report.conditionAfterEmbalming)
        bind(report.notes)
        bind(report.conditionOfRemainsWhenReceived)
        bind(report.bodyMarks)
        sqlite3_bind_int(statement, idx, Int32(report.caseNumber))
        idx += 1
        sqlite3_bind_text(statement, idx, (report.id as NSString).utf8String, -1, nil)
        return sqlite3_step(statement) == SQLITE_DONE
    }

    func deleteCaseLogReport(id: String) -> Bool {
        guard let db = db else { return false }
        let query = "DELETE FROM CASE_LOG WHERE id = ?"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_text(statement, 1, (id as NSString).utf8String, -1, nil)
        return sqlite3_step(statement) == SQLITE_DONE
    }

    private func bindReport(_ statement: OpaquePointer?, _ report: CaseLogReport) {
        guard let statement = statement else { return }
        var i: Int32 = 1
        func b(_ s: String) { sqlite3_bind_text(statement, i, (s as NSString).utf8String, -1, nil); i += 1 }
        b(report.id)
        b(Self.iso8601.string(from: report.createdAt))
        b(Self.iso8601.string(from: report.updatedAt))
        b(report.decedentName)
        b(report.gender)
        b(report.age)
        b(report.race)
        b(report.dateOfDeath)
        b(report.placeOfDeath)
        b(report.facilityName)
        b(report.embalmerName)
        b(report.dateOfEmbalming)
        b(report.embalmingTimeFinish)
        b(report.bodyWeight)
        b(report.bodyType)
        b(report.conditionSummary)
        b(report.mouthClosure)
        b(report.eyeClosure)
        b(report.arteriesInjected)
        b(report.veinsDrained)
        b(report.drainageMethod)
        b(report.aspiration)
        b(report.disinfectant)
        b(report.arterialFluidUsed)
        b(report.coInjection)
        b(report.cavityChemical)
        b(report.solutionDetails)
        b(report.conditionAfterEmbalming)
        b(report.notes)
        b(report.conditionOfRemainsWhenReceived)
        b(report.bodyMarks)
        sqlite3_bind_int(statement, i, Int32(report.caseNumber))
    }
} 
