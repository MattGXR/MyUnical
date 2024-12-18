// NetworkManager.swift
// MyUnical
//
// Created by Mattia Meligeni on 13/10/24.
//


import Foundation
import Combine
import SwiftUI

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    // Published properties to update UI in real-time
    @Published var cdsDes: String = ""
    @Published var cdsId: Int = 0
    @Published var matId: Int = 0
    @Published var matricola: String = ""
    @Published var stuId: Int = 0
    @Published var totalCfu: Int = 0
    @Published var media: Double = 0.0
    @Published var baseL: Double = 0.0
    @Published var currentCfu: Double = 0.0
    @Published var voti: [Voto] = []
    var righe: [Riga] = []
    @Published var prenotazioni: [Prenotazioni] = []
    @Published var userName: String = ""
    @Published var sex: String = ""
    @Published var insegnamenti: [Insegnamento] = []
    @Published var isFetching: Bool = false
    @Published var fatture: [Fattura] = []
    @Published var persId: Int = 0
    @Published var aaId: Int = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    /// Authenticates the user and fetches initial data.
    /// - Parameters:
    ///   - username: The user's username.
    ///   - password: The user's password.
    ///   - completion: A closure called with `true` if authentication succeeds, `false` otherwise.
    func authenticate(username: String, password: String, completion: @escaping (Bool) -> Void) {
        let base64LoginString = "\(username):\(password)".data(using: .utf8)!.base64EncodedString()
        let url = URL(string: "https://unical.esse3.cineca.it/e3rest/api/login")!
        
        var request = URLRequest(url: url)
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { result -> Data in
                guard let httpResponse = result.response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return result.data
            }
            .decode(type: AuthResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completionResult in
                switch completionResult {
                case .finished:
                    // Do nothing
                    break
                case .failure(let error):
                    print("Authentication error: \(error)")
                    completion(false)
                }
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }
                self.userName = response.user.firstName
                self.persId = response.user.persId
                self.sex = response.user.sex
                if let firstTratto = response.user.trattiCarriera.first {
                    self.cdsDes = firstTratto.cdsDes
                    self.cdsId = firstTratto.cdsId
                    self.matId = firstTratto.matId
                    self.matricola = firstTratto.matricola
                    self.aaId = firstTratto.dettaglioTratto.aaIscrId
                    self.stuId = firstTratto.stuId
                    let durataAnni = firstTratto.dettaglioTratto.durataAnni
                    self.totalCfu = durataAnni * 60
                    
                    Task {
                        await self.fetchMedia(username: username, password: password)
                        await self.fetchProve(username: username, password: password)
                        await self.fetchInsegnamenti(username: username, password: password)
                        await self.fetchFatture(username: username, password: password)
                        DispatchQueue.main.async {
                            completion(true)
                        }
                        self.saveUserData()
                    }
                } else {
                    completion(false)
                }
            })
            .store(in: &self.cancellables)
    }
    
    func fetchInsegnamenti(username: String, password: String) async {
        // Ensure matId is valid
        guard matId != 0 else { return }
        
        // Prepare the Base64 encoded credentials
        let base64LoginString = "\(username):\(password)"
            .data(using: .utf8)?
            .base64EncodedString() ?? ""
        
        // Construct the URL string
        let urlString = "https://unical.esse3.cineca.it/e3rest/api/calesa-service-v1/appelli"
        
        // Validate the URL
        guard let url = URL(string: urlString) else { return }
        
        // Create the URLRequest and set the Authorization header
        var request = URLRequest(url: url)
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        do {
            // Perform the network request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check for HTTP errors
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                throw URLError(.badServerResponse)
            }
            
            // Decode the data
            let insegnamenti = try JSONDecoder().decode([Insegnamento].self, from: data)
            
            // Update the published property on the main thread
            DispatchQueue.main.async {
                self.insegnamenti = insegnamenti
            }
        } catch {
            print("Error fetching insegnamenti: \(error)")
        }
    }
    
    // Updated fetchAppelli with completion handler
    func fetchAppelli(adId: Int, completion: @escaping (Result<[Appello], Error>) -> Void) {
        // Ensure matId is valid
        guard matId != 0 else {
            print("NetworkManager: Invalid matId: \(matId)")
            DispatchQueue.main.async {
                completion(.success([]))
            }
            return
        }
        
        // Retrieve credentials from Keychain
        guard let usernameData = KeychainHelper.shared.read(service: "it.mattiameligeni.MyUnical", account: "username"),
              let passwordData = KeychainHelper.shared.read(service: "it.mattiameligeni.MyUnical", account: "password") else {
            print("NetworkManager: Unable to retrieve credentials from Keychain.")
            DispatchQueue.main.async {
                completion(.failure(NetworkError.missingCredentials))
            }
            return
        }
        
        let username = String(data: usernameData, encoding: .utf8) ?? ""
        let password = String(data: passwordData, encoding: .utf8) ?? ""
        
        let base64LoginString = "\(username):\(password)"
            .data(using: .utf8)?
            .base64EncodedString() ?? ""
        
        // Construct URL with query parameters using URLComponents
        let urlString = "https://unical.esse3.cineca.it/e3rest/api/calesa-service-v1/appelli/\(cdsId)/\(adId)/?q=APPELLI_PRENOTABILI_E_FUTURI"
        
        // Validate the URL
        guard let url = URL(string: urlString) else {
            print("NetworkManager: Invalid URL: \(urlString)")
            DispatchQueue.main.async {
                completion(.success([]))
            }
            return
        }
        
        // Create URLRequest and set Authorization header
        var request = URLRequest(url: url)
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept") // Optional but recommended
        request.httpMethod = "GET"
        
        // Perform the network request using Combine
        URLSession.shared.dataTaskPublisher(for: request)
        // Validate response status code and log response data
            .tryMap { result -> Data in
                guard let httpResponse = result.response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                guard (200...299).contains(httpResponse.statusCode) else {
                    if let dataString = String(data: result.data, encoding: .utf8) {
                        print("NetworkManager: Server returned status code \(httpResponse.statusCode): \(dataString)")
                    }
                    throw URLError(.badServerResponse)
                }
                return result.data
            }
        // Decode JSON response into [Appello]
            .decode(type: [Appello].self, decoder: JSONDecoder())
        // Ensure updates happen on the main thread
            .receive(on: DispatchQueue.main)
        // Handle the result
            .sink(receiveCompletion: { completionResult in
                switch completionResult {
                case .finished:
                    break
                case .failure(let error):
                    print("NetworkManager: Error fetching Appelli: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }, receiveValue: { receivedAppelli in
                completion(.success(receivedAppelli))
            })
            .store(in: &cancellables)
        // Define network errors
        enum NetworkError: Error, LocalizedError {
            case invalidURL
            case invalidResponse
            case missingCredentials
            
            var errorDescription: String? {
                switch self {
                case .invalidURL:
                    return "Invalid URL."
                case .invalidResponse:
                    return "Invalid response from server."
                case .missingCredentials:
                    return "Missing credentials."
                }
            }
        }
    }
    
    func prenotaAppello(cdsId: Int, adId: Int, appId: Int, adDes: String) async throws {
        enum NetworkError: Error {
            case invalidURL
            case missingCredentials
            case invalidMatId
            case badServerResponse(String)
        }
        
        var adsceId: Int = 0
        for riga in self.righe {
            if riga.adDes == adDes {
                adsceId = riga.adsceId
            }
        }
        
        // Ensure matId is valid
        guard matId != 0 else {
            print("NetworkManager: Invalid matId: \(matId)")
            throw NetworkError.invalidMatId
        }
        
        // Retrieve credentials from Keychain
        guard let usernameData = KeychainHelper.shared.read(service: "it.mattiameligeni.MyUnical", account: "username"),
              let passwordData = KeychainHelper.shared.read(service: "it.mattiameligeni.MyUnical", account: "password"),
              let username = String(data: usernameData, encoding: .utf8),
              let password = String(data: passwordData, encoding: .utf8) else {
            print("NetworkManager: Unable to retrieve credentials from Keychain.")
            throw NetworkError.missingCredentials
        }
        
        let base64LoginString = "\(username):\(password)"
            .data(using: .utf8)?
            .base64EncodedString() ?? ""
        
        // Construct URL for POST request
        let urlString = "https://unical.esse3.cineca.it/e3rest/api/calesa-service-v1/appelli/\(cdsId)/\(adId)/\(appId)/iscritti"
        
        // Validate the URL
        guard let url = URL(string: urlString) else {
            print("NetworkManager: Invalid URL: \(urlString)")
            throw NetworkError.invalidURL
        }
        
        // Create URLRequest and set headers
        var request = URLRequest(url: url)
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        
        
        // If your API requires a body, add it here
        // For example:
        let body: [String: Any] = ["adsceId": adsceId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        do {
            // Perform the network request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Validate response status code
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 201 {
                    print("Success")
                    return
                } else {
                    // Try to parse the error message from the response body
                    if let dataString = String(data: data, encoding: .utf8) {
                        print("NetworkManager: Server returned status code \(httpResponse.statusCode): \(dataString)")
                        
                        // Parse JSON for error details
                        if let jsonData = dataString.data(using: .utf8),
                           let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                           let retErrMsg = json["retErrMsg"] as? String {
                            throw NetworkError.badServerResponse(retErrMsg)
                        }
                    }
                    throw NetworkError.badServerResponse("Unknown error occurred.")
                }
            } else {
                throw URLError(.badServerResponse)
            }
        } catch {
            throw error
        }
    }
    
    
    /// Fetches the student's average grade (media).
    /// - Parameters:
    ///   - username: The user's username.
    ///   - password: The user's password.
    func fetchMedia(username: String, password: String) async {
        // Ensure matId is valid
        guard matId != 0 else { return }
        
        // Prepare the Base64 encoded credentials
        let credentials = "\(username):\(password)"
        guard let credentialData = credentials.data(using: .utf8) else {
            print("Failed to encode credentials")
            return
        }
        let base64LoginString = credentialData.base64EncodedString()
        
        // Construct the URL string
        let urlString = "https://unical.esse3.cineca.it/e3rest/api/libretto-service-v2/libretti/\(matId)/medie"
        
        // Validate the URL
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        // Create the URLRequest and set the Authorization header
        var request = URLRequest(url: url)
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        do {
            // Perform the network request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Ensure the response is valid
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                throw URLError(.badServerResponse)
            }
            
            // Decode the JSON into an array of MediaElemento
            let mediaElements = try JSONDecoder().decode([MediaElemento].self, from: data)
            
            // Update properties on the main thread
            DispatchQueue.main.async {
                // Extract media where base = 30 and tipoMediaCod = "P"
                self.media = mediaElements.first(where: {
                    $0.base == 30 && $0.tipoMediaCod.value == "P"
                })?.media ?? 0.0
                
                // Extract media where base = 110 and tipoMediaCod = "P"
                self.baseL = mediaElements.first(where: {
                    $0.base == 110 && $0.tipoMediaCod.value == "P"
                })?.media ?? 0.0
                
                // Save both media values
                self.saveUserData()
            }
        } catch {
            // Handle errors appropriately
            print("Error fetching media: \(error)")
        }
    }
    
    func fetchFatture(username: String, password: String) async {
        // Ensure matId is valid
        guard matId != 0 else { return }
        
        // Prepare the Base64 encoded credentials
        let credentials = "\(username):\(password)"
        guard let credentialData = credentials.data(using: .utf8) else {
            print("Failed to encode credentials")
            return
        }
        let base64LoginString = credentialData.base64EncodedString()
        
        // Construct the URL string
        let urlString = "https://unical.esse3.cineca.it/e3rest/api/tasse-service-v1/lista-fatture/?persId=\(persId)&aaId=\(aaId)"
        
        // Validate the URL
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        // Create the URLRequest and set the Authorization header
        var request = URLRequest(url: url)
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        do {
            // Perform the network request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Ensure the response is valid
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                throw URLError(.badServerResponse)
            }
            
            // Decode the JSON into an array of Fattura
            let fatture = try JSONDecoder().decode([Fattura].self, from: data)
            
            // Update the published property on the main thread
            DispatchQueue.main.async {
                self.fatture = fatture
            }
        } catch {
            // Handle errors appropriately
            print("Error fetching fatture: \(error)")
        }
    }
    
    /// Processes the fetched grades and updates the published properties.
    /// - Parameters:
    ///   - prove: Array of `Prova` objects representing exam attempts.
    ///   - righe: Array of `Riga` objects representing course details.
    func fetchProve(username: String, password: String) async {
        guard matId != 0 else { return }
        let base64LoginString = "\(username):\(password)".data(using: .utf8)!.base64EncodedString()
        let proveURLString = "https://unical.esse3.cineca.it/e3rest/api/libretto-service-v2/libretti/\(matId)/prove"
        let righeURLString = "https://unical.esse3.cineca.it/e3rest/api/libretto-service-v2/libretti/\(matId)/righe"
        
        guard let proveURL = URL(string: proveURLString),
              let righeURL = URL(string: righeURLString) else { return }
        
        // Use closures to create immutable URLRequests
        let requestProve: URLRequest = {
            var request = URLRequest(url: proveURL)
            request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
            return request
        }()
        
        let requestRighe: URLRequest = {
            var request = URLRequest(url: righeURL)
            request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
            return request
        }()
        
        do {
            // Perform concurrent network requests
            async let (proveData, _) = URLSession.shared.data(for: requestProve)
            async let (righeData, _) = URLSession.shared.data(for: requestRighe)
            
            let proveResult = try await proveData
            let righeResult = try await righeData
            
            // Decode the data
            let prove = try JSONDecoder().decode([Prova].self, from: proveResult)
            self.righe = try JSONDecoder().decode([Riga].self, from: righeResult)
            
            // Process grades
            self.processGrades(prove: prove, righe: self.righe)
            
            // Update UI on the main thread
            DispatchQueue.main.async {
                self.saveUserData()
            }
        } catch {
            print("Error fetching grades: \(error)")
        }
    }
    
    private func processGrades(prove: [Prova], righe: [Riga]) {
        let righeDict = Dictionary(uniqueKeysWithValues: righe.map { ($0.adsceId, $0) })
        var totalCfu = 0.0
        var votiArray: [Voto] = []
        var appelli: [Prenotazioni] = []
        
        for prova in prove {
            guard let riga = righeDict[prova.adsceId],
                  let esitoFinale = prova.esitoFinale else { continue }
            
            // Determine votoValue based on modValCod
            let votoValue: String?
            
            if let modValCod = esitoFinale.modValCod {
                if modValCod == "V", let votoDouble = esitoFinale.voto {
                    votoValue = String(Int(votoDouble))
                } else if modValCod == "G", let tipoGiudCod = esitoFinale.tipoGiudCod, !tipoGiudCod.isEmpty {
                    votoValue = tipoGiudCod
                } else {
                    votoValue = nil // Invalid or unsupported modValCod
                }
            } else {
                votoValue = nil // modValCod is missing
            }
            
            let dateString = String(prova.dataApp.prefix(10))
            let dateFormatter = DateFormatter() // Inline date formatter
            dateFormatter.dateFormat = "dd/MM/yyyy" // Match the input format

            if let dateAppello = dateFormatter.date(from: dateString), dateAppello > Date() {
                let appello = Prenotazioni(insegnamento: riga.adDes, dataAppello: dateString)
                appelli.append(appello)
            }
           
            
            // Skip entries where votoValue is nil
            guard let validVoto = votoValue else { continue }
            
            totalCfu += riga.peso
            //let dateString = String(prova.dataApp.prefix(10))
            
            let votoStruct = Voto(
                insegnamento: riga.adDes,
                voto: validVoto,
                cfu: Int(riga.peso),
                dataAppello: dateString,
                date: dateFormatter.date(from: dateString) ?? Date()
            )
            votiArray.append(votoStruct)
        }
        
        // Update @Published properties on the main thread
        DispatchQueue.main.async {
            self.currentCfu = totalCfu
            self.voti = votiArray.sorted(by: { $0.date > $1.date })
            self.prenotazioni = appelli
        }
    }
    
    @MainActor
    /// Clears all stored data and cancels any ongoing subscriptions.
    func clearData() {
        self.cdsDes = ""
        self.cdsId = 0
        self.matId = 0
        self.stuId = 0
        self.persId = 0
        self.aaId = 0
        self.totalCfu = 0
        self.media = 0.0
        self.baseL = 0.0
        self.currentCfu = 0.0
        self.fatture.removeAll()
        self.insegnamenti.removeAll()
        self.voti.removeAll()
        // Cancel any ongoing subscriptions
        self.cancellables.forEach { $0.cancel() }
        self.cancellables.removeAll()
        
        // Remove cached data
        DataPersistence.shared.save([Voto](), to: "voti.json")
        DataPersistence.shared.save("", to: "userData.json")
        //DataPersistence.shared.save([Lecture](), to: "schedule.json")
    }
    
    /// Saves the current user data to local storage.
    private func saveUserData() {
        let userData = UserData(
            userName: self.userName,
            sex: self.sex,
            cdsDes: self.cdsDes,
            cdsId : self.cdsId,
            matId: self.matId,
            matricola: self.matricola,
            persId: self.persId,
            aaId: self.aaId,
            stuId : self.stuId,
            totalCfu: self.totalCfu,
            media: self.media,
            baseL: self.baseL,
            currentCfu: self.currentCfu,
            voti: self.voti
        )
        DataPersistence.shared.save(userData, to: "userData.json")
    }
    
    /// Loads user data from local storage.
    func loadCachedData() {
        if let cachedUserData = DataPersistence.shared.load("userData.json", as: UserData.self) {
            self.userName = cachedUserData.userName
            self.sex = cachedUserData.sex
            self.cdsDes = cachedUserData.cdsDes
            self.cdsId = cachedUserData.cdsId
            self.matId = cachedUserData.matId
            self.matricola = cachedUserData.matricola
            self.persId = cachedUserData.persId
            self.aaId = cachedUserData.aaId
            self.stuId = cachedUserData.stuId
            self.totalCfu = cachedUserData.totalCfu
            self.media = cachedUserData.media
            self.baseL = cachedUserData.baseL
            self.currentCfu = cachedUserData.currentCfu
            self.voti = cachedUserData.voti.sorted(by: { $0.date > $1.date })
        }
    }
}

struct UserData: Codable {
    let userName: String
    let sex: String
    let cdsDes: String
    let cdsId: Int
    let matId: Int
    let matricola: String
    let persId: Int
    let aaId: Int
    let stuId: Int
    let totalCfu: Int
    let media: Double
    let baseL: Double
    let currentCfu: Double
    let voti: [Voto]
}
