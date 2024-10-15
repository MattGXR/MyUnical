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
    @Published var stuId: Int = 0
    @Published var totalCfu: Int = 0
    @Published var media: Double = 0.0
    @Published var baseL: Double = 0.0
    @Published var currentCfu: Double = 0.0
    @Published var voti: [Voto] = []
    @Published var userName: String = ""
    @Published var sex: String = ""
    @Published var insegnamenti: [Insegnamento] = []
    @Published var isFetching: Bool = false
    @Published var semaforo: Semaforo?
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
                    self.aaId = firstTratto.dettaglioTratto.aaIscrId
                    self.stuId = firstTratto.stuId
                    let durataAnni = firstTratto.dettaglioTratto.durataAnni
                    self.totalCfu = durataAnni == 2 ? 60 : 180
                    // Fetch media and grades after authentication
                    self.fetchMedia(username: username, password: password)
                    self.fetchProve(username: username, password: password)
                    self.fetchInsegnamenti(username: username, password: password)
                    self.fetchSemaforo(username: username, password: password)
                    self.fetchFatture(username: username, password: password)
                    completion(true)
                    
                    // Save authenticated user data to cache
                    self.saveUserData()
                } else {
                    completion(false)
                }
            })
            .store(in: &self.cancellables)
    }
    
    func fetchInsegnamenti(username: String, password: String) {
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
        
        // Create the data task publisher
        let cancellable = URLSession.shared.dataTaskPublisher(for: request)
        // Ensure the response is valid
            .tryMap { result -> Data in
                guard let httpResponse = result.response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return result.data
            }
        // Decode the JSON into an array of Insegnamento
            .decode(type: [Insegnamento].self, decoder: JSONDecoder())
        // Switch to the main thread for UI updates
            .receive(on: DispatchQueue.main)
        // Handle the received values
            .sink(receiveCompletion: { completionResult in
                switch completionResult {
                case .finished:
                    // Successfully finished, no action needed
                    break
                case .failure(let error):
                    // Handle the error appropriately
                    print("Error fetching insegnamenti: \(error)")
                }
            }, receiveValue: { [weak self] insegnamenti in
                guard let self = self else { return }
                
                self.insegnamenti = insegnamenti
            })
        
        // Store the cancellable to manage the subscription lifecycle
        cancellable.store(in: &self.cancellables)
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
    
    func prenotaAppello(cdsId: Int, adId: Int, appId: Int, completion: @escaping (Result<Void, Error>) -> Void) {
            enum NetworkError: Error {
                case invalidURL
                case missingCredentials
                case invalidMatId
                case badServerResponse
                // Add other cases as needed
            }
            // Ensure matId is valid
            guard matId != 0 else {
                print("NetworkManager: Invalid matId: \(matId)")
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.invalidMatId))
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
            
            // Construct URL for POST request
            let urlString = "https://unical.esse3.cineca.it/e3rest/api/calesa-service-v1/appelli/\(cdsId)/\(adId)/\(appId)/iscritti"
            
            // Validate the URL
            guard let url = URL(string: urlString) else {
                print("NetworkManager: Invalid URL: \(urlString)")
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.invalidURL))
                }
                return
            }
            
            // Create URLRequest and set headers
            var request = URLRequest(url: url)
            request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Accept") // Optional but recommended
            request.setValue("application/json", forHTTPHeaderField: "Content-Type") // If sending a body
            request.httpMethod = "POST"
            
            // If your API requires a body, add it here
            // For example:
            // let body: [String: Any] = ["key": "value"]
            // request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
            
            // Perform the network request using Combine
            URLSession.shared.dataTaskPublisher(for: request)
                // Validate response status code
                .tryMap { result -> Void in
                    guard let httpResponse = result.response as? HTTPURLResponse else {
                        throw URLError(.badServerResponse)
                    }
                    if httpResponse.statusCode == 201 {
                        // Success
                        return ()
                    } else {
                        if let dataString = String(data: result.data, encoding: .utf8) {
                            print("NetworkManager: Server returned status code \(httpResponse.statusCode): \(dataString)")
                        }
                        throw NetworkError.badServerResponse
                    }
                }
                // Ensure updates happen on the main thread
                .receive(on: DispatchQueue.main)
                // Handle the result
                .sink(receiveCompletion: { completionResult in
                    switch completionResult {
                    case .finished:
                        break
                    case .failure(let error):
                        print("NetworkManager: Error prenotando Appello: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                }, receiveValue: {
                    completion(.success(()))
                })
                .store(in: &cancellables)
        }
    
       
       
    
    /// Fetches the student's average grade (media).
    /// - Parameters:
    ///   - username: The user's username.
    ///   - password: The user's password.
    func fetchMedia(username: String, password: String) {
        // Ensure matId is valid
        guard matId != 0 else { return }
        
        // Prepare the Base64 encoded credentials
        let base64LoginString = "\(username):\(password)"
            .data(using: .utf8)?
            .base64EncodedString() ?? ""
        
        // Construct the URL string
        let urlString = "https://unical.esse3.cineca.it/e3rest/api/libretto-service-v2/libretti/\(matId)/medie"
        
        // Validate the URL
        guard let url = URL(string: urlString) else { return }
        
        // Create the URLRequest and set the Authorization header
        var request = URLRequest(url: url)
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        // Create the data task publisher
        let cancellable = URLSession.shared.dataTaskPublisher(for: request)
        // Ensure the response is valid
            .tryMap { result -> Data in
                guard let httpResponse = result.response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return result.data
            }
        // Decode the JSON into an array of MediaElemento
            .decode(type: [MediaElemento].self, decoder: JSONDecoder())
        // Switch to the main thread for UI updates
            .receive(on: DispatchQueue.main)
        // Handle the received values
            .sink(receiveCompletion: { completionResult in
                switch completionResult {
                case .finished:
                    // Successfully finished, no action needed
                    break
                case .failure(let error):
                    // Handle the error appropriately
                    print("Error fetching media: \(error)")
                }
            }, receiveValue: { [weak self] mediaElements in
                guard let self = self else { return }
                
                // Extract media where base = 30 and tipoMediaCod = "P", provide default value if nil
                self.media = mediaElements.first(where: {
                    $0.base == 30 && $0.tipoMediaCod.value == "P"
                })?.media ?? 0.0 // Replace 0.0 with an appropriate default
                
                // Extract media where base = 110 and tipoMediaCod = "P", provide default value if nil
                self.baseL = mediaElements.first(where: {
                    $0.base == 110 && $0.tipoMediaCod.value == "P"
                })?.media ?? 0.0 // Replace 0.0 with an appropriate default
                
                // Save both media values
                self.saveUserData()
            })
        
        // Store the cancellable to manage the subscription lifecycle
        cancellable.store(in: &self.cancellables)
    }
    
    func fetchSemaforo(username: String, password: String) {
        // Ensure matId is valid
        guard matId != 0 else {
            print("Invalid matId")
            return
        }
        
        // Prepare the Base64 encoded credentials
        let credentials = "\(username):\(password)"
        guard let credentialData = credentials.data(using: .utf8) else {
            print("Failed to encode credentials")
            return
        }
        let base64LoginString = credentialData.base64EncodedString()
        
        // Construct the URL string
        let urlString = "https://unical.esse3.cineca.it/e3rest/api/tasse-service-v1/semaforo/\(stuId)"
        
        // Validate the URL
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        // Create the URLRequest and set the Authorization header
        var request = URLRequest(url: url)
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        // Create the data task publisher
        URLSession.shared.dataTaskPublisher(for: request)
        // Ensure the response is valid
            .tryMap { result -> Data in
                guard let httpResponse = result.response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return result.data
            }
        // Decode the JSON into a Semaforo object
            .decode(type: Semaforo.self, decoder: JSONDecoder())
        // Switch to the main thread for UI updates
            .receive(on: DispatchQueue.main)
        // Handle the received values
            .sink(receiveCompletion: { [weak self] completionResult in
                switch completionResult {
                case .finished:
                    // Successfully finished, no action needed
                    break
                case .failure(let error):
                    // Handle the error appropriately
                    print("Error fetching Semaforo: \(error)")
                    // Optionally, update UI or notify the user
                    // self?.semaforo = nil
                }
            }, receiveValue: { [weak self] semaforo in
                guard let self = self else { return }
                
                self.semaforo = semaforo
                // Optionally, update the UI or perform other actions with the data
            })
        // Store the cancellable to manage the subscription lifecycle
            .store(in: &self.cancellables)
    }
    
    func fetchFatture(username: String, password: String) {
        // Ensure matId is valid
        guard matId != 0 else { return }
        
        // Prepare the Base64 encoded credentials
        let base64LoginString = "\(username):\(password)"
            .data(using: .utf8)?
            .base64EncodedString() ?? ""
        
        // Construct the URL string
        let urlString = "https://unical.esse3.cineca.it/e3rest/api/tasse-service-v1/lista-fatture/?persId=\(persId)&aaId=\(aaId)"
        
        // Validate the URL
        guard let url = URL(string: urlString) else { return }
        
        // Create the URLRequest and set the Authorization header
        var request = URLRequest(url: url)
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        // Create the data task publisher
        let cancellable = URLSession.shared.dataTaskPublisher(for: request)
        // Ensure the response is valid
            .tryMap { result -> Data in
                guard let httpResponse = result.response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return result.data
            }
        // Decode the JSON into an array of Fattura
            .decode(type: [Fattura].self, decoder: JSONDecoder())
        // Switch to the main thread for UI updates
            .receive(on: DispatchQueue.main)
        // Handle the received values
            .sink(receiveCompletion: { completionResult in
                switch completionResult {
                case .finished:
                    // Successfully finished, no action needed
                    break
                case .failure(let error):
                    // Handle the error appropriately
                    print("Error fetching fatture: \(error)")
                }
            }, receiveValue: { [weak self] fatture in
                guard let self = self else { return }
                
                self.fatture = fatture
            })
        
        // Store the cancellable to manage the subscription lifecycle
        cancellable.store(in: &self.cancellables)
    }
    
    /// Processes the fetched grades and updates the published properties.
    /// - Parameters:
    ///   - prove: Array of `Prova` objects representing exam attempts.
    ///   - righe: Array of `Riga` objects representing course details.
    func fetchProve(username: String, password: String) {
            guard matId != 0 else { return }
            let base64LoginString = "\(username):\(password)".data(using: .utf8)!.base64EncodedString()
            let proveURLString = "https://unical.esse3.cineca.it/e3rest/api/libretto-service-v2/libretti/\(matId)/prove"
            let righeURLString = "https://unical.esse3.cineca.it/e3rest/api/libretto-service-v2/libretti/\(matId)/righe"
            
            guard let proveURL = URL(string: proveURLString),
                  let righeURL = URL(string: righeURLString) else { return }
            
            var requestProve = URLRequest(url: proveURL)
            requestProve.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
            
            var requestRighe = URLRequest(url: righeURL)
            requestRighe.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
            
            let provePublisher = URLSession.shared.dataTaskPublisher(for: requestProve)
                .tryMap { result -> Data in
                    guard let httpResponse = result.response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) else {
                        throw URLError(.badServerResponse)
                    }
                    return result.data
                }
                .decode(type: [Prova].self, decoder: JSONDecoder())
            
            let righePublisher = URLSession.shared.dataTaskPublisher(for: requestRighe)
                .tryMap { result -> Data in
                    guard let httpResponse = result.response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) else {
                        throw URLError(.badServerResponse)
                    }
                    return result.data
                }
                .decode(type: [Riga].self, decoder: JSONDecoder())
            
            let cancellable = Publishers.Zip(provePublisher, righePublisher)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completionResult in
                    switch completionResult {
                    case .finished:
                        // Do nothing
                        break
                    case .failure(let error):
                        print("Error fetching grades: \(error)")
                    }
                }, receiveValue: { [weak self] prove, righe in
                    guard let self = self else { return }
                    self.processGrades(prove: prove, righe: righe)
                    self.saveUserData() // Update cache with new grades
                })
            
            // Store the cancellable
            cancellable.store(in: &self.cancellables)
        }
        
    private func processGrades(prove: [Prova], righe: [Riga]) {
            let righeDict = Dictionary(uniqueKeysWithValues: righe.map { ($0.adsceId, $0) })
            var totalCfu = 0.0
            var votiArray: [Voto] = []
            
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
                
                // Skip entries where votoValue is nil
                guard let validVoto = votoValue else { continue }
                
                totalCfu += riga.peso
                let dateString = String(prova.dataApp.prefix(10))
                
                let votoStruct = Voto(
                    insegnamento: riga.adDes,
                    voto: validVoto,
                    cfu: Int(riga.peso),
                    dataAppello: dateString,
                    date: dateFormatter.date(from: dateString) ?? Date()
                )
                votiArray.append(votoStruct)
            }
            
            self.currentCfu = totalCfu
            self.voti = votiArray.sorted(by: { $0.date > $1.date })
        }
    
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
    }
    
    /// Saves the current user data to local storage.
    private func saveUserData() {
        let userData = UserData(
            userName: self.userName,
            sex: self.sex,
            cdsDes: self.cdsDes,
            cdsId : self.cdsId,
            matId: self.matId,
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
    let persId: Int
    let aaId: Int
    let stuId: Int
    let totalCfu: Int
    let media: Double
    let baseL: Double
    let currentCfu: Double
    let voti: [Voto]
}
