//
//  ContentView.swift
//  portfolio
//
//  Created by Jayanth Gopal on 15/05/2025.
//

import SwiftUI
import Foundation
import Combine
import UIKit

struct AssetCategory {
    let name: String
    let value: Double
}



struct ContentView: View {
    // Currency service for exchange rates
    @StateObject private var currencyService = CurrencyService.shared
    
    // Initialize view with saved data
    init() {
        // Load saved portfolio data
        let savedData = PersistenceManager.shared.loadPortfolioData()
        _manualEntries = State(initialValue: savedData)
    }
    
    // Sample data - would be replaced with actual data source
    @State private var totalAssets = AssetCategory(name: "Total", value: 0)
    @State private var ukAssets = AssetCategory(name: "UK Assets", value: 0)
    @State private var indiaAssets = AssetCategory(name: "India Assets", value: 0)
    
    // UK Detailed assets
    @State private var ukISA = AssetCategory(name: "UK ISA", value: 0)
    @State private var ukPot = AssetCategory(name: "UK Pot", value: 0)
    @State private var ukCoinbase = AssetCategory(name: "UK Coinbase", value: 0)
    
    // India Detailed assets
    @State private var indiaShares = AssetCategory(name: "India Shares", value: 0)
    @State private var indiaSmallcase = AssetCategory(name: "India Smallcase", value: 0)
    @State private var indiaMF = AssetCategory(name: "India MF", value: 0)
    
    // New investment form
    @State private var investmentAmount: String = ""
    @State private var selectedAssetType: String = "UK ISA"
    @State private var selectedDate = Date()
    @State private var isUpdatingExisting = false
    @State private var updateAmount: String = ""
    
    // Function to dismiss keyboard
    @FocusState private var isInputActive: Bool
    
    private func hideKeyboard() {
        isInputActive = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // Date formatter for displaying last updated time
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    // Date range for date picker
    private let dateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let startComponents = DateComponents(year: 2023, month: 1, day: 1)
        let endComponents = DateComponents(year: 2026, month: 12, day: 31)
        return calendar.date(from: startComponents)!...calendar.date(from: endComponents)!
    }()
    
    // Date formatter for displaying dates
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    

    
    // Asset types
    private let assetTypes = ["UK ISA", "UK Pot", "UK Coinbase", "India Shares", "India Smallcase", "India MF"]
    
    // Gradients - enhanced for dark mode visibility
    private var ukGradient: some View {
        // Using environment to detect dark/light mode
        return GeometryReader { _ in
            ZStack {
                // Base gradient that adapts to color scheme
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.25),
                        Color.purple.opacity(0.25),
                        Color.red.opacity(0.25)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Overlay with more vibrant accent colors
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.blue.opacity(0.15),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }
        .background(Color(.systemBackground))
    }
    
    private var indiaGradient: some View {
        // Using environment to detect dark/light mode
        return GeometryReader { _ in
            ZStack {
                // Base gradient that adapts to color scheme
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.orange.opacity(0.25),
                        Color.green.opacity(0.25),
                        Color.yellow.opacity(0.15)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Overlay with more vibrant accent colors
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.orange.opacity(0.15),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }
        .background(Color(.systemBackground))
    }
    
    // Store manual entries: [AssetName: [DateString: Value]]
    // For UK assets, values are in GBP
    // For India assets, values are in INR
    @State private var manualEntries: [String: [String: Double]] = [:] {
        didSet {
            // Save data whenever it changes
            PersistenceManager.shared.savePortfolioData(manualEntries)
        }
    }
    
    // Helper to check if an asset is from India
    func isIndianAsset(_ assetName: String) -> Bool {
        return assetName.starts(with: "India")
    }
    
    // Helper to get the appropriate currency symbol for an asset
    func currencySymbol(for assetName: String) -> String {
        return isIndianAsset(assetName) ? "₹" : "£"
    }
    
    // Helper to format currency value
    func formattedCurrency(value: Double, assetName: String) -> String {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        currencyFormatter.maximumFractionDigits = 0
        
        if isIndianAsset(assetName) {
            currencyFormatter.currencySymbol = "₹"
            return currencyFormatter.string(from: NSNumber(value: value)) ?? "₹0"
        } else {
            currencyFormatter.currencySymbol = "£"
            return currencyFormatter.string(from: NSNumber(value: value)) ?? "£0"
        }
    }
    
    // Helper to convert a date to a string key
    func dateString(from date: Date) -> String {
        dateFormatter.string(from: date)
    }
    
    // Helper to get value for an asset for the current date
    func valueForCurrentDate(asset: String) -> Double {
        let today = dateString(from: Date())
        if let manual = manualEntries[asset]?[today] {
            return manual
        }
        return 0.0
    }
    
    // Helper to get the latest value for an asset (from any date)
    // For India assets, this returns the value in INR
    func latestValueForAsset(_ asset: String) -> Double {
        let assetEntries = manualEntries[asset] ?? [:]
        
        // If no entries, return 0
        if assetEntries.isEmpty { return 0 }
        
        // Find the entries, convert string dates back to Date objects for sorting
        let dateFormatter = self.dateFormatter
        let sortedDates = assetEntries.keys.compactMap { key -> (Date, Double)? in
            if let date = dateFormatter.date(from: key),
               let value = assetEntries[key] {
                return (date, value)
            }
            return nil
        }.sorted { $0.0 > $1.0 } // Sort by date, most recent first
        
        if let latest = sortedDates.first {
            return latest.1 // Return the value
        }
        
        return 0
    }
    
    // Helper to get the latest value for an asset in GBP (converted if needed)
    func latestValueInGBP(_ asset: String) -> Double {
        let value = latestValueForAsset(asset)
        return isIndianAsset(asset) ? value * currencyService.inrToGbpRate : value
    }
    
    // Helper to get all values for an asset with dates
    func historyForAsset(_ asset: String) -> [(Date, Double)] {
        let assetEntries = manualEntries[asset] ?? [:]
        let dateFormatter = self.dateFormatter
        
        return assetEntries.compactMap { key, value in
            if let date = dateFormatter.date(from: key) {
                return (date, value)
            }
            return nil
        }.sorted { $0.0 < $1.0 } // Sort by date, oldest first
    }
    
    // Calculate UK assets total (sum of latest values for UK assets in GBP)
    var ukAssetsTotal: Double {
        let ukAssetTypes = assetTypes.filter { $0.starts(with: "UK") }
        return ukAssetTypes.reduce(0) { $0 + latestValueInGBP($1) }
    }
    
    // Calculate India assets total (sum of latest values for India assets converted to GBP)
    var indiaAssetsTotal: Double {
        let indiaAssetTypes = assetTypes.filter { $0.starts(with: "India") }
        return indiaAssetTypes.reduce(0) { $0 + latestValueInGBP($1) }
    }
    
    // Calculate overall total in GBP
    var overallTotal: Double {
        return ukAssetsTotal + indiaAssetsTotal
    }
    

    
    // Helper to update UK and India assets with latest totals
    func updateTotals() {
        // Update the asset categories with calculated values
        totalAssets = AssetCategory(name: "Total", value: overallTotal)
        ukAssets = AssetCategory(name: "UK Assets", value: ukAssetsTotal)
        indiaAssets = AssetCategory(name: "India Assets", value: indiaAssetsTotal)
        
        // Update individual asset categories with their latest values (in native currency)
        ukISA = AssetCategory(name: "UK ISA", value: latestValueForAsset("UK ISA"))
        ukPot = AssetCategory(name: "UK Pot", value: latestValueForAsset("UK Pot"))
        ukCoinbase = AssetCategory(name: "UK Coinbase", value: latestValueForAsset("UK Coinbase"))
        
        indiaShares = AssetCategory(name: "India Shares", value: latestValueForAsset("India Shares"))
        indiaSmallcase = AssetCategory(name: "India Smallcase", value: latestValueForAsset("India Smallcase"))
        indiaMF = AssetCategory(name: "India MF", value: latestValueForAsset("India MF"))
    }
    
    var body: some View {
        TabView {
            summaryView
                .tabItem {
                    Label("Summary", systemImage: "chart.pie")
                }
                .onAppear {
                    updateTotals()
                    
                    // Check if exchange rates need refreshing
                    if currencyService.ratesNeedRefresh {
                        currencyService.fetchExchangeRates()
                    }
                }
            
            addInvestmentView
                .tabItem {
                    Label("Add", systemImage: "plus.circle")
                }
        }
        .onChange(of: currencyService.gbpToInrRate) { _ in
            // Recalculate totals whenever the exchange rate changes
            updateTotals()
        }
    }
    
    // Summary Tab View
    var summaryView: some View {
        ScrollView {
            VStack {
                VStack(spacing: 20) {
                    HStack {
                        Text("Total")
                            .font(.headline)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("£\(Int(totalAssets.value))")
                                .font(.title)
                                .fontWeight(.bold)
                        }
                    }
                    
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
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                        .background(ukGradient.cornerRadius(10))
                        .cornerRadius(10)
                        
                        VStack {
                            Text("India Assets")
                                .font(.headline)
                                .padding(.bottom, 5)
                            
                            Text("£\(Int(indiaAssets.value))")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("₹\(Int(indiaAssets.value * currencyService.gbpToInrRate))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                        .background(indiaGradient.cornerRadius(10))
                        .cornerRadius(10)
                    }
                    .frame(height: 160) // Fixed height for both sections
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
                .padding()
                
                Text("All values based on your latest manual entries")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
                
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
                        .background(ukGradient.cornerRadius(10))
                        .cornerRadius(10)
                    
                    AssetSummaryView(asset: ukPot)
                        .padding()
                        .background(ukGradient.cornerRadius(10))
                        .cornerRadius(10)
                    
                    AssetSummaryView(asset: ukCoinbase)
                        .padding()
                        .background(ukGradient.cornerRadius(10))
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
                    
                    IndianAssetSummaryView(asset: indiaShares, gbpToInrRate: currencyService.gbpToInrRate)
                        .padding()
                        .background(indiaGradient.cornerRadius(10))
                        .cornerRadius(10)
                    
                    IndianAssetSummaryView(asset: indiaSmallcase, gbpToInrRate: currencyService.gbpToInrRate)
                        .padding()
                        .background(indiaGradient.cornerRadius(10))
                        .cornerRadius(10)
                    
                    IndianAssetSummaryView(asset: indiaMF, gbpToInrRate: currencyService.gbpToInrRate)
                        .padding()
                        .background(indiaGradient.cornerRadius(10))
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
    
    // Exchange rate display view
    var exchangeRateView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Exchange Rate:")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("£1 = ₹\(String(format: "%.2f", currencyService.gbpToInrRate))")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                
                if let lastUpdated = currencyService.lastUpdated {
                    Text("Last updated: \(timeFormatter.string(from: lastUpdated))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Using default exchange rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: {
                // Refresh exchange rate
                currencyService.fetchExchangeRates()
            }) {
                HStack {
                    Text("Refresh")
                        .font(.callout)
                    
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                }
                .padding(8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            .disabled(currencyService.isLoading)
            .overlay(
                Group {
                    if currencyService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(0.7)
                    }
                }
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
    

    
    // Add Investment View
    var addInvestmentView: some View {
        VStack {
            Text("Manage Investments")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            // Exchange rate indicator for reference
            exchangeRateView
                .padding(.horizontal)
                .padding(.bottom)
                .onTapGesture {
                    hideKeyboard()
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Manual Data Entry")
                    .font(.headline)
                
                Text("Asset values are currently entered manually. Enter the latest values for your assets below.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Note: UK assets are entered in £ (GBP) and Indian assets in ₹ (INR)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
            
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
                
                HStack {
                    Text(isIndianAsset(selectedAssetType) ? "₹" : "£")
                        .foregroundColor(.secondary)
                    
                    TextField("Amount", text: $investmentAmount)
                        .keyboardType(.decimalPad)
                        .focused($isInputActive)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    hideKeyboard()
                                }
                            }
                        }
                }
                
                DatePicker(
                    "Date",
                    selection: $selectedDate,
                    in: dateRange,
                    displayedComponents: .date
                )
                
                // Show informational text with conversion rate if Indian asset
                if isIndianAsset(selectedAssetType) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enter amount in Indian Rupees (₹)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let amount = Double(investmentAmount), amount > 0 {
                            let gbpValue = amount * currencyService.inrToGbpRate
                            Text("Equivalent to approximately £\(Int(gbpValue)) GBP")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                } else {
                    Text("Enter amount in British Pounds (£)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(footer: Text("All totals are calculated based on the latest value entered for each asset. Indian values are converted to GBP for portfolio totals.")) {
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
    }
    
    var updateExistingInvestmentForm: some View {
        Form {
            Section(header: Text("Update Investment")) {
                Picker("Asset Type", selection: $selectedAssetType) {
                    ForEach(assetTypes, id: \.self) { assetType in
                        Text(assetType)
                    }
                }
                
                HStack {
                    Text(isIndianAsset(selectedAssetType) ? "₹" : "£")
                        .foregroundColor(.secondary)
                    
                    TextField("New Value", text: $updateAmount)
                        .keyboardType(.decimalPad)
                        .focused($isInputActive)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    hideKeyboard()
                                }
                            }
                        }
                }
                
                DatePicker(
                    "Date",
                    selection: $selectedDate,
                    in: dateRange,
                    displayedComponents: .date
                )
                
                // Show existing value for selected date if available
                let dateKey = dateString(from: selectedDate)
                if let existingValue = manualEntries[selectedAssetType]?[dateKey] {
                    HStack {
                        Text("Current Value:")
                        Spacer()
                        Text("\(isIndianAsset(selectedAssetType) ? "₹" : "£")\(Int(existingValue))")
                            .foregroundColor(.secondary)
                    }
                    
                    // If Indian asset, show the GBP equivalent
                    if isIndianAsset(selectedAssetType) {
                        HStack {
                            Text("GBP Equivalent:")
                            Spacer()
                            Text("£\(Int(existingValue * currencyService.inrToGbpRate))")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // Show preview of conversion if it's an Indian asset
                if isIndianAsset(selectedAssetType), let amount = Double(updateAmount), amount > 0 {
                    HStack {
                        Text("Will convert to:")
                        Spacer()
                        Text("£\(Int(amount * currencyService.inrToGbpRate))")
                            .foregroundColor(.blue)
                    }
                }
                
                // Show informational text
                if isIndianAsset(selectedAssetType) {
                    Text("Enter amount in Indian Rupees (₹)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Enter amount in British Pounds (£)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(footer: Text("All totals are calculated based on the latest value entered for each asset. Indian values are converted to GBP for portfolio totals.")) {
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
    }
    
    func addInvestment() {
        // Update the selected asset for the selected date
        if let amount = Double(investmentAmount) {
            let dateKey = dateString(from: selectedDate)
            var assetDict = manualEntries[selectedAssetType] ?? [:]
            assetDict[dateKey] = amount
            manualEntries[selectedAssetType] = assetDict
            updateTotals()
        }
        investmentAmount = ""
        selectedAssetType = "UK ISA"
        selectedDate = Date() // Reset to current date
    }
    
    func updateInvestment() {
        // Update the selected asset for the selected date
        if let amount = Double(updateAmount) {
            let dateKey = dateString(from: selectedDate)
            var assetDict = manualEntries[selectedAssetType] ?? [:]
            assetDict[dateKey] = amount
            manualEntries[selectedAssetType] = assetDict
            updateTotals()
        }
        updateAmount = ""
        selectedAssetType = "UK ISA"
        selectedDate = Date() // Reset to current date
    }
}

struct AssetSummaryView: View {
    let asset: AssetCategory
    
    var body: some View {
        HStack {
            Text(asset.name)
                .font(.headline)
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("£\(Int(asset.value))")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
        }
    }
}

struct IndianAssetSummaryView: View {
    let asset: AssetCategory
    let gbpToInrRate: Double
    
    var body: some View {
        HStack {
            Text(asset.name)
                .font(.headline)
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("₹\(Int(asset.value))")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("£\(Int(asset.value / gbpToInrRate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
}
