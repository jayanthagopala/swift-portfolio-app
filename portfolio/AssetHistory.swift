import Foundation

struct AssetHistory {
    let name: String
    let values: [String: Double] // [Month: Value]
}

struct PortfolioHistory {
    let months: [String]
    let assets: [AssetHistory]
    
    // Returns the latest value for each asset
    var latestValues: [String: Double] {
        var result: [String: Double] = [:]
        for asset in assets {
            if let lastMonth = months.last, let value = asset.values[lastMonth] {
                result[asset.name] = value
            }
        }
        return result
    }
    
    // Returns the total portfolio value for each month
    var totalPerMonth: [String: Double] {
        var result: [String: Double] = [:]
        for month in months {
            var total = 0.0
            for asset in assets {
                if let value = asset.values[month] {
                    total += value
                }
            }
            result[month] = total
        }
        return result
    }
}

class CSVAssetParser {
    static func parse(csv: String) -> PortfolioHistory {
        let lines = csv.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count > 1 else { return PortfolioHistory(months: [], assets: []) }
        let header = lines[0].components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let months = Array(header.dropFirst())
        var assets: [AssetHistory] = []
        for line in lines.dropFirst() {
            let columns = line.components(separatedBy: ",")
            guard let assetName = columns.first?.trimmingCharacters(in: .whitespaces), !assetName.isEmpty else { continue }
            var values: [String: Double] = [:]
            for (i, valueStr) in columns.dropFirst().enumerated() {
                let month = months[safe: i] ?? ""
                let cleanValue = valueStr.replacingOccurrences(of: "[£₹,\"]", with: "", options: .regularExpression)
                let value = Double(cleanValue) ?? 0.0
                values[month] = value
            }
            assets.append(AssetHistory(name: assetName, values: values))
        }
        return PortfolioHistory(months: months, assets: assets)
    }
}

// Array safe subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
} 