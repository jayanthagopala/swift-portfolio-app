import Foundation

class PersistenceManager {
    static let shared = PersistenceManager()
    
    private let fileManager = FileManager.default
    private let documentsURL: URL
    private let manualEntriesFileName = "portfolio_data.json"
    
    private init() {
        // Get the documents directory URL - this persists across app reinstalls if proper backup flags are set
        documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // Create the directory if it doesn't exist
        if !fileManager.fileExists(atPath: documentsURL.path) {
            do {
                try fileManager.createDirectory(at: documentsURL, withIntermediateDirectories: true)
            } catch {
                print("Error creating documents directory: \(error)")
            }
        }
    }
    
    // Save portfolio data to documents directory
    func savePortfolioData(_ entries: [String: [String: Double]]) {
        var fileURL = documentsURL.appendingPathComponent(manualEntriesFileName)
        
        do {
            let data = try JSONEncoder().encode(entries)
            try data.write(to: fileURL)
            
            // Set the file to be included in backups - this is important for persistence across reinstalls
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = false
            try fileURL.setResourceValues(resourceValues)
            
            print("Saved portfolio data to: \(fileURL.path)")
        } catch {
            print("Error saving portfolio data: \(error)")
        }
    }
    
    // Load portfolio data from documents directory
    func loadPortfolioData() -> [String: [String: Double]] {
        let fileURL = documentsURL.appendingPathComponent(manualEntriesFileName)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("No saved portfolio data found")
            return [:]
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let entries = try JSONDecoder().decode([String: [String: Double]].self, from: data)
            print("Loaded portfolio data from: \(fileURL.path)")
            return entries
        } catch {
            print("Error loading portfolio data: \(error)")
            return [:]
        }
    }
}
