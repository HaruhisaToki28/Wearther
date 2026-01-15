//
//  LocationSearchViewModel.swift
//  Wearther
//
//  Created by Wearther on 2026/01/15.
//

import Foundation
import MapKit
import Combine

// MARK: - Search Result Model
struct LocationSearchResult: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String           // 地名（例: 渋谷区）
    let fullName: String       // フルネーム（例: 東京都渋谷区）
    let latitude: Double
    let longitude: Double
    
    init(id: UUID = UUID(), name: String, fullName: String, latitude: Double, longitude: Double) {
        self.id = id
        self.name = name
        self.fullName = fullName
        self.latitude = latitude
        self.longitude = longitude
    }
}

// MARK: - Location Search ViewModel
@MainActor
class LocationSearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var searchResults: [LocationSearchResult] = []
    @Published var isSearching: Bool = false
    @Published var searchHistory: [LocationSearchResult] = []
    
    private var searchTask: Task<Void, Never>?
    private let historyKey = "locationSearchHistory"
    private let maxHistoryCount = 10
    
    init() {
        loadSearchHistory()
    }
    
    // MARK: - Search
    func search() {
        // 前の検索をキャンセル
        searchTask?.cancel()
        
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !query.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        
        isSearching = true
        
        searchTask = Task {
            // デバウンス（0.3秒待機）
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            guard !Task.isCancelled else { return }
            
            await performSearch(query: query)
        }
    }
    
    private func performSearch(query: String) async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        // 日本国内に限定
        let japanRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 36.0, longitude: 138.0),
            span: MKCoordinateSpan(latitudeDelta: 20.0, longitudeDelta: 20.0)
        )
        request.region = japanRegion
        request.resultTypes = [.address, .pointOfInterest]
        
        let search = MKLocalSearch(request: request)
        
        do {
            let response = try await search.start()
            
            guard !Task.isCancelled else { return }
            
            // 日本国内の結果のみフィルタリング
            let japanResults = response.mapItems.filter { item in
                item.placemark.countryCode == "JP"
            }
            
            searchResults = japanResults.compactMap { item -> LocationSearchResult? in
                let placemark = item.placemark
                
                // 地名を構築
                let name = placemark.locality ?? placemark.subLocality ?? placemark.name ?? ""
                
                var fullNameComponents: [String] = []
                if let prefecture = placemark.administrativeArea {
                    fullNameComponents.append(prefecture)
                }
                if let city = placemark.locality {
                    fullNameComponents.append(city)
                }
                if let subLocality = placemark.subLocality, subLocality != placemark.locality {
                    fullNameComponents.append(subLocality)
                }
                
                let fullName = fullNameComponents.isEmpty ? (placemark.name ?? "") : fullNameComponents.joined()
                
                guard !name.isEmpty else { return nil }
                
                return LocationSearchResult(
                    name: name,
                    fullName: fullName,
                    latitude: placemark.coordinate.latitude,
                    longitude: placemark.coordinate.longitude
                )
            }
            
            // 重複を除去
            var seen = Set<String>()
            searchResults = searchResults.filter { result in
                let key = "\(result.fullName)"
                if seen.contains(key) {
                    return false
                }
                seen.insert(key)
                return true
            }
            
            isSearching = false
        } catch {
            print("Search error: \(error.localizedDescription)")
            searchResults = []
            isSearching = false
        }
    }
    
    // MARK: - Search History
    func addToHistory(_ result: LocationSearchResult) {
        // 既存の同じ場所を削除
        searchHistory.removeAll { $0.fullName == result.fullName }
        
        // 先頭に追加
        searchHistory.insert(result, at: 0)
        
        // 最大件数を超えたら古いものを削除
        if searchHistory.count > maxHistoryCount {
            searchHistory = Array(searchHistory.prefix(maxHistoryCount))
        }
        
        saveSearchHistory()
    }
    
    func removeFromHistory(_ result: LocationSearchResult) {
        searchHistory.removeAll { $0.id == result.id }
        saveSearchHistory()
    }
    
    func clearHistory() {
        searchHistory = []
        saveSearchHistory()
    }
    
    private func loadSearchHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let history = try? JSONDecoder().decode([LocationSearchResult].self, from: data) else {
            return
        }
        searchHistory = history
    }
    
    private func saveSearchHistory() {
        guard let data = try? JSONEncoder().encode(searchHistory) else { return }
        UserDefaults.standard.set(data, forKey: historyKey)
    }
    
    // MARK: - Clear
    func clearSearch() {
        searchText = ""
        searchResults = []
        isSearching = false
    }
}
