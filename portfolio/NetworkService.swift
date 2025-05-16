import Foundation

enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case unauthorized
    case serverError(Int)
    case invalidAPIKey
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let error):
            return "Failed to decode data: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized. Please check your API key"
        case .serverError(let code):
            return "Server error: \(code)"
        case .invalidAPIKey:
            return "Invalid API key"
        }
    }
}

class NetworkService {
    private let baseURL = "https://api.trading212.com"
    
    // Account data models
    struct AccountCash: Decodable {
        let total: Double
        let free: Double
    }
    
    struct Position: Decodable, Identifiable {
        var id: String { ticker }
        let ticker: String
        let averagePrice: Double
        let currentPrice: Double
        let quantity: Double
        let ppl: Double
        
        var name: String { 
            // This would come from another API call in practice
            // For now, extract from ticker (simplified)
            let parts = ticker.split(separator: "_")
            if parts.count > 0 {
                return String(parts[0])
            }
            return ticker
        }
        
        var currentValue: Double {
            quantity * currentPrice
        }
        
        var profit: Double {
            ppl
        }
        
        var profitPercentage: Double {
            if averagePrice == 0 { return 0 }
            return (currentPrice - averagePrice) / averagePrice * 100
        }
    }
    
    // Fetch account cash
    func fetchAccountCash(apiKey: String, completion: @escaping (Result<AccountCash, APIError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/v0/equity/account/cash") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                guard let data = data else {
                    completion(.failure(.invalidResponse))
                    return
                }
                
                do {
                    let accountCash = try JSONDecoder().decode(AccountCash.self, from: data)
                    completion(.success(accountCash))
                } catch let error {
                    completion(.failure(.decodingError(error)))
                }
            case 401:
                completion(.failure(.unauthorized))
            default:
                completion(.failure(.serverError(httpResponse.statusCode)))
            }
        }
        
        task.resume()
    }
    
    // Fetch portfolio positions
    func fetchPortfolioPositions(apiKey: String, completion: @escaping (Result<[Position], APIError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/v0/equity/portfolio") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                guard let data = data else {
                    completion(.failure(.invalidResponse))
                    return
                }
                
                do {
                    let positions = try JSONDecoder().decode([Position].self, from: data)
                    completion(.success(positions))
                } catch let error {
                    completion(.failure(.decodingError(error)))
                }
            case 401:
                completion(.failure(.unauthorized))
            default:
                completion(.failure(.serverError(httpResponse.statusCode)))
            }
        }
        
        task.resume()
    }
} 
