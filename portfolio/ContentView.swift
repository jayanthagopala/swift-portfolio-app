//
//  ContentView.swift
//  portfolio
//
//  Created by Jayanth Gopal on 15/05/2025.
//

import SwiftUI
import Charts
import Foundation

struct AssetCategory {
    let name: String
    let value: Double
    let change: Double
}

struct PortfolioDataPoint {
    let date: Date
    let value: Double
}

struct ContentView: View {
    // Sample data - would be replaced with actual data source
    @State private var totalAssets = AssetCategory(name: "Total", value: 0, change: 0)
    @State private var ukAssets = AssetCategory(name: "UK Assets", value: 0, change: 0)
    @State private var indiaAssets = AssetCategory(name: "India Assets", value: 0, change: 0)
    
    // UK Detailed assets
    @State private var ukISA = AssetCategory(name: "UK ISA", value: 0, change: 0)
    @State private var ukInvest = AssetCategory(name: "UK Invest", value: 0, change: 0)
    @State private var ukCashISA = AssetCategory(name: "UK Cash ISA", value: 0, change: 0)
    @State private var ukMonzoPot = AssetCategory(name: "UK Monzo Pot", value: 0, change: 0)
    @State private var ukOakNorthPot = AssetCategory(name: "UK OakNorth Pot", value: 0, change: 0)
    @State private var ukCoinbase = AssetCategory(name: "UK Coinbase", value: 0, change: 0)
    
    // India Detailed assets
    @State private var indiaShares = AssetCategory(name: "India Shares", value: 0, change: 0)
    @State private var indiaSmallcase = AssetCategory(name: "India Smallcase", value: 0, change: 0)
    @State private var indiaMF = AssetCategory(name: "India MF", value: 0, change: 0)
    
    // New investment form
    @State private var showAddInvestmentSheet = false
    @State private var investmentAmount: String = ""
    @State private var selectedAssetType: String = "UK ISA"
    @State private var selectedMonth: String = ""
    @State private var isUpdatingExisting = false
    @State private var updateAmount: String = ""
    
    // Portfolio growth data - sample data
    @State private var portfolioHistory: [PortfolioDataPoint] = [
        PortfolioDataPoint(date: Calendar.current.date(byAdding: .month, value: -6, to: Date())!, value: 0),
        PortfolioDataPoint(date: Calendar.current.date(byAdding: .month, value: -5, to: Date())!, value: 0),
        PortfolioDataPoint(date: Calendar.current.date(byAdding: .month, value: -4, to: Date())!, value: 0),
        PortfolioDataPoint(date: Calendar.current.date(byAdding: .month, value: -3, to: Date())!, value: 0),
        PortfolioDataPoint(date: Calendar.current.date(byAdding: .month, value: -2, to: Date())!, value: 0),
        PortfolioDataPoint(date: Calendar.current.date(byAdding: .month, value: -1, to: Date())!, value: 0),
        PortfolioDataPoint(date: Date(), value: 0)
    ]
    
    // Asset types
    private let assetTypes = ["UK ISA", "UK Invest", "UK Cash ISA", "UK Monzo Pot", "UK OakNorth Pot", "UK Coinbase", "India Shares", "India Smallcase", "India MF"]
    
    // Gradients
    private var ukGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.red.opacity(0.1)]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var indiaGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.orange.opacity(0.1), Color.green.opacity(0.1), Color.white.opacity(0.1)]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // List of months for manual entry (can be extended as needed)
    let months: [String] = [
        "Jan 24", "Feb 24", "Mar 24", "Apr 24", "May 24", "Jun 24", "Jul 24", "Aug 24", "Sep 24", "Oct 24", "Nov 24", "Dec 24",
        "Jan 25", "Feb 25", "Mar 25", "Apr 25", "May 25"
    ]
    
    // Store manual entries: [AssetName: [Month: Value]]
    @State private var manualEntries: [String: [String: Double]] = [:]
    
    // Helper to get the current month string in the same format as above
    var currentMonthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yy"
        let now = Date()
        let candidate = formatter.string(from: now)
        if months.contains(candidate) { return candidate }
        return months.last ?? ""
    }
    
    // Helper to get value for an asset for the current month (manual > 0)
    func valueForCurrentMonth(asset: String) -> Double {
        if let manual = manualEntries[asset]?[currentMonthString] {
            return manual
        }
        return 0.0
    }
    
    // Helper to get full history for an asset, using manual entries
    func mergedHistory(for asset: String) -> [(String, Double)] {
        var merged: [String: Double] = [:]
        if let manual = manualEntries[asset] {
            for (month, value) in manual { merged[month] = value }
        }
        // Sort by months order
        return months.map { ($0, merged[$0] ?? 0.0) }
    }
    
    // Helper to get total portfolio value per month, using manual entries
    var mergedTotalPortfolioHistory: [(String, Double)] {
        months.map { month in
            let total = assetTypes.map { asset in
                manualEntries[asset]?[month] ?? 0.0
            }.reduce(0, +)
            return (month, total)
        }
    }
    
    // Helper to get the latest value for an asset (from any month)
    func latestValueForAsset(_ asset: String) -> Double {
        let assetEntries = manualEntries[asset] ?? [:]
        
        // If no entries, return 0
        if assetEntries.isEmpty { return 0 }
        
        // Find the latest month that has a value
        let monthsWithValues = assetEntries.keys.filter { months.contains($0) }
        let sortedMonths = monthsWithValues.sorted { first, second in
            let firstIndex = months.firstIndex(of: first) ?? -1
            let secondIndex = months.firstIndex(of: second) ?? -1
            return firstIndex > secondIndex
        }
        
        if let latestMonth = sortedMonths.first {
            return assetEntries[latestMonth] ?? 0
        }
        
        return 0
    }
    
    // Calculate UK assets total (sum of latest values for UK assets)
    var ukAssetsTotal: Double {
        let ukAssetTypes = assetTypes.filter { $0.starts(with: "UK") }
        return ukAssetTypes.reduce(0) { $0 + latestValueForAsset($1) }
    }
    
    // Calculate India assets total (sum of latest values for India assets)
    var indiaAssetsTotal: Double {
        let indiaAssetTypes = assetTypes.filter { $0.starts(with: "India") }
        return indiaAssetTypes.reduce(0) { $0 + latestValueForAsset($1) }
    }
    
    // Calculate overall total
    var overallTotal: Double {
        return ukAssetsTotal + indiaAssetsTotal
    }
    
    // Helper to update UK and India assets with latest totals
    func updateTotals() {
        // Update the asset categories with calculated values
        totalAssets = AssetCategory(name: "Total", value: overallTotal, change: 0)
        ukAssets = AssetCategory(name: "UK Assets", value: ukAssetsTotal, change: 0)
        indiaAssets = AssetCategory(name: "India Assets", value: indiaAssetsTotal, change: 0)
    }
    
    var body: some View {
        TabView {
            summaryView
                .tabItem {
                    Label("Summary", systemImage: "chart.pie")
                }
                .onAppear {
                    updateTotals()
                }
            
            portfolioGrowthView
                .tabItem {
                    Label("Growth", systemImage: "chart.line.uptrend.xyaxis")
                }
            
            addInvestmentView
                .tabItem {
                    Label("Add", systemImage: "plus.circle")
                }
        }
    }
    
    // Summary Tab View
    var summaryView: some View {
        ScrollView {
            VStack {
                VStack(spacing: 20) {
                    AssetSummaryView(asset: totalAssets)
                    
                    Divider()
                    
                    HStack(spacing: 10) {
                        VStack {
                            Text("UK Assets")
                                .font(.headline)
                                .padding(.bottom, 5)
                            
                            Text("£\(Int(ukAssets.value))")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .padding(.bottom, 4)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: ukAssets.change >= 0 ? "arrow.up" : "arrow.down")
                                    .foregroundColor(ukAssets.change >= 0 ? .green : .red)
                                
                                Text("£\(Int(abs(ukAssets.change)))")
                                    .font(.subheadline)
                                    .foregroundColor(ukAssets.change >= 0 ? .green : .red)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                        .background(ukGradient)
                        .cornerRadius(10)
                        
                        VStack {
                            Text("India Assets")
                                .font(.headline)
                                .padding(.bottom, 5)
                            
                            Text("£\(Int(indiaAssets.value))")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("₹\(Int(indiaAssets.value * 104.5))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: indiaAssets.change >= 0 ? "arrow.up" : "arrow.down")
                                    .foregroundColor(indiaAssets.change >= 0 ? .green : .red)
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("£\(Int(abs(indiaAssets.change)))")
                                        .font(.subheadline)
                                        .foregroundColor(indiaAssets.change >= 0 ? .green : .red)
                                    
                                    Text("₹\(Int(abs(indiaAssets.change) * 104.5))")
                                        .font(.caption2)
                                        .foregroundColor(indiaAssets.change >= 0 ? .green : .red)
                                        .opacity(0.8)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                        .background(indiaGradient)
                        .cornerRadius(10)
                    }
                    .frame(height: 160) // Fixed height for both sections
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
                .padding()
                
                Divider()
                    .padding(.horizontal)
                    .padding(.top)
                
                // UK Assets Breakdown
                VStack(spacing: 15) {
                    Text("UK Assets")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 5)
                    
                    AssetSummaryView(asset: ukISA)
                        .padding()
                        .background(ukGradient)
                        .cornerRadius(10)
                    
                    AssetSummaryView(asset: ukInvest)
                        .padding()
                        .background(ukGradient)
                        .cornerRadius(10)
                    
                    AssetSummaryView(asset: ukCashISA)
                        .padding()
                        .background(ukGradient)
                        .cornerRadius(10)
                    
                    AssetSummaryView(asset: ukMonzoPot)
                        .padding()
                        .background(ukGradient)
                        .cornerRadius(10)
                    
                    AssetSummaryView(asset: ukOakNorthPot)
                        .padding()
                        .background(ukGradient)
                        .cornerRadius(10)
                    
                    AssetSummaryView(asset: ukCoinbase)
                        .padding()
                        .background(ukGradient)
                        .cornerRadius(10)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
                .padding()
                
                // India Assets Breakdown
                VStack(spacing: 15) {
                    Text("India Assets")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 5)
                    
                    AssetSummaryView(asset: indiaShares)
                        .padding()
                        .background(indiaGradient)
                        .cornerRadius(10)
                    
                    AssetSummaryView(asset: indiaSmallcase)
                        .padding()
                        .background(indiaGradient)
                        .cornerRadius(10)
                    
                    AssetSummaryView(asset: indiaMF)
                        .padding()
                        .background(indiaGradient)
                        .cornerRadius(10)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
                .padding()
            }
        }
    }
    
    // Portfolio Growth View
    var portfolioGrowthView: some View {
        VStack {
            Text("Portfolio Growth")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            Chart {
                ForEach(portfolioHistory, id: \.date) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Value", dataPoint.value)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    
                    AreaMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Value", dataPoint.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.3), .blue.opacity(0.1)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    PointMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Value", dataPoint.value)
                    )
                    .foregroundStyle(.blue)
                }
            }
            .frame(height: 300)
            .padding()
            
            Text("6 Month Growth: £\(Int(portfolioHistory.last!.value - portfolioHistory.first!.value))")
                .fontWeight(.semibold)
                .padding()
            
            Spacer()
        }
        .padding()
    }
    
    // Add Investment View
    var addInvestmentView: some View {
        VStack {
            Text("Manage Investments")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            Picker("Action", selection: $isUpdatingExisting) {
                Text("Add New").tag(false)
                Text("Update Existing").tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            if isUpdatingExisting {
                updateExistingInvestmentForm
            } else {
                addNewInvestmentForm
            }
        }
    }
    
    var addNewInvestmentForm: some View {
        Form {
            Section(header: Text("New Investment Details")) {
                Picker("Asset Type", selection: $selectedAssetType) {
                    ForEach(assetTypes, id: \.self) { assetType in
                        Text(assetType)
                    }
                }
                
                TextField("Amount", text: $investmentAmount)
                    .keyboardType(.decimalPad)
                
                Picker("Month", selection: $selectedMonth) {
                    ForEach(months, id: \.self) { month in
                        Text(month)
                    }
                }
                .onAppear {
                    if selectedMonth.isEmpty {
                        selectedMonth = currentMonthString
                    }
                }
            }
            
            Button(action: addInvestment) {
                Text("Add Investment")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }
    
    var updateExistingInvestmentForm: some View {
        Form {
            Section(header: Text("Update Investment")) {
                Picker("Asset Type", selection: $selectedAssetType) {
                    ForEach(assetTypes, id: \.self) { assetType in
                        Text(assetType)
                    }
                }
                
                TextField("New Value", text: $updateAmount)
                    .keyboardType(.decimalPad)
                
                Picker("Month", selection: $selectedMonth) {
                    ForEach(months, id: \.self) { month in
                        Text(month)
                    }
                }
                .onAppear {
                    if selectedMonth.isEmpty {
                        selectedMonth = currentMonthString
                    }
                }
            }
            
            Button(action: updateInvestment) {
                Text("Update Investment")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }
    
    func addInvestment() {
        // Update the selected asset for the selected month
        if let amount = Double(investmentAmount) {
            var assetDict = manualEntries[selectedAssetType] ?? [:]
            assetDict[selectedMonth] = amount
            manualEntries[selectedAssetType] = assetDict
            updateTotals()
        }
        investmentAmount = ""
        selectedAssetType = "UK ISA"
        selectedMonth = currentMonthString
    }
    
    func updateInvestment() {
        // Update the selected asset for the selected month
        if let amount = Double(updateAmount) {
            var assetDict = manualEntries[selectedAssetType] ?? [:]
            assetDict[selectedMonth] = amount
            manualEntries[selectedAssetType] = assetDict
            updateTotals()
        }
        updateAmount = ""
        selectedAssetType = "UK ISA"
        selectedMonth = currentMonthString
    }
}

struct AssetSummaryView: View {
    let asset: AssetCategory
    // Conversion rate from GBP to INR (sample rate)
    let gbpToInrRate: Double = 104.5
    
    // Function to determine currency symbol based on asset name
    func currencySymbol(for assetName: String) -> String {
        if assetName == "ISA" || assetName == "Crypto" || assetName == "UK Assets" || assetName == "Total" {
            return "£"
        } else if assetName == "Smallcase" || assetName == "Mutual Funds" || assetName == "India Assets" {
            return "₹"
        }
        return "£" // Default
    }
    
    var body: some View {
        HStack {
            Text(asset.name)
                .font(.headline)
            
            Spacer()
            
            VStack(alignment: .trailing) {
                if asset.name == "India Assets" {
                    Text("£\(Int(asset.value))")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("₹\(Int(asset.value * gbpToInrRate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: asset.change >= 0 ? "arrow.up" : "arrow.down")
                            .foregroundColor(asset.change >= 0 ? .green : .red)
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("£\(Int(abs(asset.change))) today")
                                .font(.subheadline)
                                .foregroundColor(asset.change >= 0 ? .green : .red)
                            
                            Text("₹\(Int(abs(asset.change) * gbpToInrRate))")
                                .font(.caption2)
                                .foregroundColor(asset.change >= 0 ? .green : .red)
                                .opacity(0.8)
                        }
                    }
                } else {
                    Text("\(currencySymbol(for: asset.name))\(Int(asset.value))")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 4) {
                        Image(systemName: asset.change >= 0 ? "arrow.up" : "arrow.down")
                            .foregroundColor(asset.change >= 0 ? .green : .red)
                        
                        Text("\(currencySymbol(for: asset.name))\(Int(abs(asset.change))) today")
                            .font(.subheadline)
                            .foregroundColor(asset.change >= 0 ? .green : .red)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
