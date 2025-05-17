import Foundation
import Combine

class CurrencyService: ObservableObject {
    // Singleton instance
    static let shared = CurrencyService()
    
    // Default fallback values in case API is unavailable
    private let defaultGbpToInrRate: Double = 104.5
    private let defaultInrToGbpRate: Double = 1.0 / 104.5
    
    // Published values that will be observed by the app
    @Published var gbpToInrRate: Double = 104.5
    @Published var inrToGbpRate: Double = 1.0 / 104.5
    @Published var lastUpdated: Date?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Load cached rates on initialization
        loadCachedRates()
        
        // Automatically fetch rates
        fetchExchangeRates()
    }
    
    // Fetch current exchange rates from a public API
    func fetchExchangeRates() {
        isLoading = true
        errorMessage = nil
        
        // Using Exchange Rate API - a free public API for exchange rates
        // We're getting GBP to INR rate
        let url = URL(string: "https://open.er-api.com/v6/latest/GBP")!
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: ExchangeRateResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self?.errorMessage = "Failed to fetch exchange rates: \(error.localizedDescription)"
                        print("Exchange rate error: \(error)")
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    
                    if let inrRate = response.rates["INR"] {
                        // Update the rates
                        self.gbpToInrRate = inrRate
                        self.inrToGbpRate = 1.0 / inrRate
                        self.lastUpdated = Date()
                        
                        // Cache the rates
                        self.cacheRates()
                        
                        print("Updated exchange rates: 1 GBP = \(inrRate) INR")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // Cache rates for offline use
    private func cacheRates() {
        let rates = [
            "gbpToInr": gbpToInrRate,
            "inrToGbp": inrToGbpRate,
            "lastUpdated": lastUpdated?.timeIntervalSince1970 ?? 0
        ] as [String: Any]
        
        UserDefaults.standard.set(rates, forKey: "cachedExchangeRates")
    }
    
    // Load cached rates 
    private func loadCachedRates() {
        if let cached = UserDefaults.standard.dictionary(forKey: "cachedExchangeRates") {
            if let gbpToInr = cached["gbpToInr"] as? Double {
                self.gbpToInrRate = gbpToInr
            }
            
            if let inrToGbp = cached["inrToGbp"] as? Double {
                self.inrToGbpRate = inrToGbp
            }
            
            if let timestamp = cached["lastUpdated"] as? TimeInterval {
                self.lastUpdated = Date(timeIntervalSince1970: timestamp)
            }
        }
    }
    
    // Method to get rates even if API call fails
    func getGbpToInrRate() -> Double {
        return gbpToInrRate
    }
    
    func getInrToGbpRate() -> Double {
        return inrToGbpRate
    }
    
    // Check if rates are older than a day and need refreshing
    var ratesNeedRefresh: Bool {
        guard let lastUpdated = lastUpdated else { return true }
        let calendar = Calendar.current
        return !calendar.isDateInToday(lastUpdated)
    }
}

// Response structure for the exchange rate API
struct ExchangeRateResponse: Decodable {
    let result: String
    let base_code: String
    let rates: [String: Double]
} 