import Foundation
import SQLite3

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: OpaquePointer?
    private let databaseVersion = 1 // For future schema updates
    
    // Add static cache for fluids
    private static var cachedFluids: [Fluid]?
    private static var cachedFluidsHeaders: [String] = []
    private static var cachedFluidsRows: [[String]] = []
    
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
                
                // Store the database version
                UserDefaults.standard.set(databaseVersion, forKey: "databaseVersion")
            } catch {
                print("❌ Failed to copy database: \(error.localizedDescription)")
                return
            }
        } else {
            print("📁 Using existing database in documents")
            
            // Check if we need to update the database schema
            let currentVersion = UserDefaults.standard.integer(forKey: "databaseVersion")
            if currentVersion < databaseVersion {
                print("🔄 Database needs update from version \(currentVersion) to \(databaseVersion)")
                // TODO: Implement database migration if needed
                UserDefaults.standard.set(databaseVersion, forKey: "databaseVersion")
            }
        }
        
        // Open the database
        if sqlite3_open(databaseURL.path, &db) == SQLITE_OK {
            print("✅ Successfully opened database")
            
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
            // Remove current database
            if fileManager.fileExists(atPath: databaseURL.path) {
                try fileManager.removeItem(at: databaseURL)
                print("✅ Removed current database")
            }
            
            // Copy backup to restore original state
            if fileManager.fileExists(atPath: backupURL.path) {
                try fileManager.copyItem(at: backupURL, to: databaseURL)
                print("✅ Restored database from backup")
            } else {
                // If no backup exists, copy from bundle
                guard let bundlePath = Bundle.main.path(forResource: "data", ofType: "db") else {
                    print("❌ Could not find database in bundle")
                    return false
                }
                try fileManager.copyItem(atPath: bundlePath, toPath: databaseURL.path)
                print("✅ Restored database from bundle")
            }
            
            // Reset database version
            UserDefaults.standard.set(databaseVersion, forKey: "databaseVersion")
            
            // Reopen database
            setupDatabase()
            
            print("✅ Database reset complete")
            return true
        } catch {
            print("❌ Failed to reset database: \(error.localizedDescription)")
            return false
        }
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
            updateFields.append("\(field) = ?")
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
        if let cached = DatabaseManager.cachedFluids {
            return (cached, DatabaseManager.cachedFluidsHeaders, DatabaseManager.cachedFluidsRows)
        }
        return nil
    }
    
    // Add method to update cache
    func updateFluidsCache() {
        print("\n=== Updating Fluids Cache ===")
        let query = """
            SELECT * FROM FLUID 
            ORDER BY FLUID ASC
        """
        
        if let results = executeQuery(query) {
            print("Raw query returned \(results.count) results")
            
            if !results.isEmpty {
                // Get headers from the first result
                DatabaseManager.cachedFluidsHeaders = Array(results[0].keys).sorted()
                
                // Convert results to rows
                DatabaseManager.cachedFluidsRows = results.map { dict in
                    DatabaseManager.cachedFluidsHeaders.map { header in
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
                
                // Update fluids array
                DatabaseManager.cachedFluids = results.compactMap { dictionary in
                    if let fluid = Fluid(from: dictionary) {
                        return fluid
                    } else {
                        print("Failed to create Fluid from dictionary: \(dictionary)")
                        return nil
                    }
                }
                
                print("Successfully cached \(DatabaseManager.cachedFluids?.count ?? 0) fluids")
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
} 