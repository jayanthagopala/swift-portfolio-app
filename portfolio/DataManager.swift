import Foundation

class DataManager {
    static let shared = DataManager()
    
    private let fileManager = FileManager.default
    private let documentsURL: URL
    private let manualEntriesFileName = "manualEntries.json"
    
    private init() {
        // Get the documents directory URL
        documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // Create the directory if it doesn't exist
        if !fileManager.fileExists(atPath: documentsURL.path) {
            do {
                try fileManager.createDirectory(at: documentsURL, withIntermediateDirectories: true)
            } catch {
                print("Error creating documents directory: \(error.localizedDescription)")
            }
        }
    }
    
    // Save manual entries to file
    func saveManualEntries(_ entries: [String: [String: Double]]) {
        var fileURL = documentsURL.appendingPathComponent(manualEntriesFileName)
        
        do {
            let data = try JSONEncoder().encode(entries)
            try data.write(to: fileURL)
            
            // Set proper backup attributes to ensure data persists across reinstalls
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = false
            try fileURL.setResourceValues(resourceValues)
            
            print("Saved manual entries to: \(fileURL.path)")
        } catch {
            print("Error saving manual entries: \(error.localizedDescription)")
        }
    }
    
    // Load manual entries from file
    func loadManualEntries() -> [String: [String: Double]] {
        let fileURL = documentsURL.appendingPathComponent(manualEntriesFileName)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("No saved entries found.")
            return [:]
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let entries = try JSONDecoder().decode([String: [String: Double]].self, from: data)
            print("Loaded manual entries from: \(fileURL.path)")
            return entries
        } catch {
            print("Error loading manual entries: \(error.localizedDescription)")
            return [:]
        }
    }
} 