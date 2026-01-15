//
//  NotificationView.swift
//  Wearther
//
//  Created by Wearther App
//

import SwiftUI

struct NotificationView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let notifications = NotificationItem.mockNotifications
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            headerView
            
            // MARK: - Content
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(NotificationTimeSection.allCases, id: \.self) { section in
                        let sectionNotifications = notifications.filter { $0.timeSection == section }
                        if !sectionNotifications.isEmpty {
                            NotificationSectionView(
                                title: section.rawValue,
                                notifications: sectionNotifications
                            )
                        }
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .background(Color(hex: "F8F8F8"))
        }
        .background(Color(hex: "F8F8F8"))
        .navigationBarHidden(true)
    }
    
    // MARK: - Header View
    private var headerView: some View {
        ZStack {
            // Title
            Text("通知")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
            
            // Back Button
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.black)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .frame(height: 50)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color(hex: "DDDDDD"))
                .frame(height: 0.2),
            alignment: .bottom
        )
    }
}

// MARK: - Section View
private struct NotificationSectionView: View {
    let title: String
    let notifications: [NotificationItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section Title
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 17)
            
            // Notification Items
            VStack(spacing: 10) {
                ForEach(notifications) { notification in
                    NotificationItemView(notification: notification)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 20)
    }
}

// MARK: - Notification Item View
private struct NotificationItemView: View {
    let notification: NotificationItem
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Avatar / Icon
            notificationIcon
            
            // Message
            Text(notification.message)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.black)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Post Image (for like notifications)
            if let postImageName = notification.postImageName {
                postThumbnail(imageName: postImageName)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(15)
        .overlay(
            // Like badge for like notifications
            likedBadge,
            alignment: .bottomLeading
        )
    }
    
    // MARK: - Notification Icon
    @ViewBuilder
    private var notificationIcon: some View {
        switch notification.type {
        case .follow, .like:
            // User Avatar
            Circle()
                .fill(Color(hex: "E0E0E0"))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "A0A0A0"))
                )
        case .weather:
            // Weather Icon
            ZStack {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 44, height: 44)
                Image(systemName: "cloud.rain.fill")
                    .font(.system(size: 30))
                    .foregroundColor(Color(hex: "2D2D2D"))
            }
        }
    }
    
    // MARK: - Post Thumbnail
    private func postThumbnail(imageName: String) -> some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(Color(hex: "EDEDED"))
            .frame(width: 44, height: 44)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "A0A0A0"))
            )
    }
    
    // MARK: - Liked Badge
    @ViewBuilder
    private var likedBadge: some View {
        if notification.type == .like {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 22, height: 22)
                
                Circle()
                    .fill(Color(hex: "FF000F"))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                    )
            }
            .offset(x: 42, y: -1)
        }
    }
}

#Preview {
    NotificationView()
}
