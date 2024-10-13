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
    @Published var matId: Int = 0
    @Published var totalCfu: Int = 0
    @Published var media: Double = 0.0
    @Published var currentCfu: Double = 0.0
    @Published var voti: [Voto] = []
    @Published var userName: String = ""
    @Published var sex: String = ""
    
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
                self.sex = response.user.sex
                if let firstTratto = response.user.trattiCarriera.first {
                    self.cdsDes = firstTratto.cdsDes
                    self.matId = firstTratto.matId
                    let durataAnni = firstTratto.dettaglioTratto.durataAnni
                    self.totalCfu = durataAnni == 2 ? 60 : 180
                    // Fetch media and grades after authentication
                    self.fetchMedia(username: username, password: password)
                    self.fetchProve(username: username, password: password)
                    completion(true)
                    
                    // Save authenticated user data to cache
                    self.saveUserData()
                } else {
                    completion(false)
                }
            })
            .store(in: &self.cancellables)
    }
    
    /// Fetches the student's average grade (media).
    /// - Parameters:
    ///   - username: The user's username.
    ///   - password: The user's password.
    func fetchMedia(username: String, password: String) {
        guard matId != 0 else { return }
        let base64LoginString = "\(username):\(password)".data(using: .utf8)!.base64EncodedString()
        let urlString = "https://unical.esse3.cineca.it/e3rest/api/libretto-service-v2/libretti/\(matId)/medie"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        let cancellable = URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { result -> Data in
                guard let httpResponse = result.response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return result.data
            }
            .decode(type: [MediaElemento].self, decoder: JSONDecoder())
            .compactMap { $0.first(where: { $0.base == 30 && $0.tipoMediaCod.value == "P" })?.media }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completionResult in
                switch completionResult {
                case .finished:
                    // Do nothing
                    break
                case .failure(let error):
                    print("Error fetching media: \(error)")
                }
            }, receiveValue: { [weak self] mediaValue in
                self?.media = mediaValue
                self?.saveUserData() // Update cache with new media
            })
        
        // Store the cancellable
        cancellable.store(in: &self.cancellables)
    }
    
    /// Fetches the student's grades (voti).
    /// - Parameters:
    ///   - username: The user's username.
    ///   - password: The user's password.
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
    
    /// Processes the fetched grades and updates the published properties.
    /// - Parameters:
    ///   - prove: Array of `Prova` objects representing exam attempts.
    ///   - righe: Array of `Riga` objects representing course details.
    private func processGrades(prove: [Prova], righe: [Riga]) {
        let righeDict = Dictionary(uniqueKeysWithValues: righe.map { ($0.adsceId, $0) })
        var totalCfu = 0.0
        var votiArray: [Voto] = []
        
        for prova in prove {
            if let riga = righeDict[prova.adsceId], let voto = prova.esitoFinale?.voto {
                totalCfu += riga.peso
                let dateString = String(prova.dataApp.prefix(10))
                let votoStruct = Voto(
                    insegnamento: riga.adDes,
                    voto: Int(voto),
                    cfu: Int(riga.peso),
                    dataAppello: dateString,
                    date: dateFormatter.date(from: dateString) ?? Date()
                )
                votiArray.append(votoStruct)
            }
        }
        self.currentCfu = totalCfu
        self.voti = votiArray.sorted(by: { $0.date > $1.date })
    }
    
    /// Clears all stored data and cancels any ongoing subscriptions.
    func clearData() {
        self.cdsDes = ""
        self.matId = 0
        self.totalCfu = 0
        self.media = 0.0
        self.currentCfu = 0.0
        self.voti = []
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
            matId: self.matId,
            totalCfu: self.totalCfu,
            media: self.media,
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
            self.matId = cachedUserData.matId
            self.totalCfu = cachedUserData.totalCfu
            self.media = cachedUserData.media
            self.currentCfu = cachedUserData.currentCfu
            self.voti = cachedUserData.voti.sorted(by: { $0.date > $1.date })
        }
    }
}

struct UserData: Codable {
    let userName: String
    let sex: String
    let cdsDes: String
    let matId: Int
    let totalCfu: Int
    let media: Double
    let currentCfu: Double
    let voti: [Voto]
}
