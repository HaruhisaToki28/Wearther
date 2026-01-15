//
//  LocationSearchView.swift
//  Wearther
//
//  Created by Wearther on 2026/01/15.
//

import SwiftUI

struct LocationSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = LocationSearchViewModel()
    
    let onLocationSelected: (LocationSearchResult) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header with Search Bar
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // 戻るボタン
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(hex: "2D2D2D"))
                    }
                    
                    // 検索入力欄
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "68717B"))
                        
                        TextField("地名を検索", text: $viewModel.searchText)
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "2D2D2D"))
                            .autocorrectionDisabled()
                            .onChange(of: viewModel.searchText) { _, _ in
                                viewModel.search()
                            }
                        
                        if !viewModel.searchText.isEmpty {
                            Button(action: { viewModel.clearSearch() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(hex: "AAAAAA"))
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(hex: "F5F5F5"))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 12)
            .padding(.bottom, 12)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .fill(Color(hex: "DDDDDD"))
                    .frame(height: 0.5),
                alignment: .bottom
            )
            
            // MARK: - Content
            ScrollView {
                VStack(spacing: 0) {
                    if viewModel.isSearching {
                        // ローディング
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("検索中...")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "68717B"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if !viewModel.searchText.isEmpty {
                        // 検索結果
                        if viewModel.searchResults.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 32))
                                    .foregroundColor(Color(hex: "AAAAAA"))
                                Text("該当する場所が見つかりません")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "68717B"))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            SearchResultsSection(
                                results: viewModel.searchResults,
                                onSelect: { result in
                                    selectLocation(result)
                                }
                            )
                        }
                    } else {
                        // 検索履歴
                        SearchHistorySection(
                            history: viewModel.searchHistory,
                            onSelect: { result in
                                selectLocation(result)
                            },
                            onRemove: { result in
                                viewModel.removeFromHistory(result)
                            },
                            onClear: {
                                viewModel.clearHistory()
                            }
                        )
                    }
                }
                .padding(.top, 16)
            }
        }
        .background(Color(hex: "F8F8F8"))
        .navigationBarHidden(true)
    }
    
    private func selectLocation(_ result: LocationSearchResult) {
        viewModel.addToHistory(result)
        onLocationSelected(result)
        dismiss()
    }
}

// MARK: - Search Results Section
private struct SearchResultsSection: View {
    let results: [LocationSearchResult]
    let onSelect: (LocationSearchResult) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("検索結果")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "68717B"))
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            
            VStack(spacing: 0) {
                ForEach(results) { result in
                    LocationRow(result: result, onTap: { onSelect(result) })
                    
                    if result.id != results.last?.id {
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Search History Section
private struct SearchHistorySection: View {
    let history: [LocationSearchResult]
    let onSelect: (LocationSearchResult) -> Void
    let onRemove: (LocationSearchResult) -> Void
    let onClear: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if history.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 32))
                        .foregroundColor(Color(hex: "AAAAAA"))
                    Text("検索履歴がありません")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "68717B"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                HStack {
                    Text("検索履歴")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "68717B"))
                    
                    Spacer()
                    
                    Button(action: onClear) {
                        Text("すべて削除")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(hex: "FF2539"))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                
                VStack(spacing: 0) {
                    ForEach(history) { result in
                        HistoryRow(
                            result: result,
                            onTap: { onSelect(result) },
                            onRemove: { onRemove(result) }
                        )
                        
                        if result.id != history.last?.id {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(16)
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Location Row
private struct LocationRow: View {
    let result: LocationSearchResult
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // アイコン
                ZStack {
                    Circle()
                        .fill(Color(hex: "F5F5F5"))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "08C4FA"))
                }
                
                // 地名
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "2D2D2D"))
                    
                    if result.fullName != result.name {
                        Text(result.fullName)
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "68717B"))
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "AAAAAA"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - History Row
private struct HistoryRow: View {
    let result: LocationSearchResult
    let onTap: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // アイコン
                    ZStack {
                        Circle()
                            .fill(Color(hex: "F5F5F5"))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "clock.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "68717B"))
                    }
                    
                    // 地名
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.name)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(hex: "2D2D2D"))
                        
                        if result.fullName != result.name {
                            Text(result.fullName)
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "68717B"))
                        }
                    }
                    
                    Spacer()
                }
            }
            
            // 削除ボタン
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "AAAAAA"))
                    .padding(8)
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
    }
}

#Preview {
    LocationSearchView { result in
        print("Selected: \(result.fullName)")
    }
}
