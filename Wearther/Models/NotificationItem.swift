//
//  NotificationItem.swift
//  Wearther
//
//  Created by Wearther App
//

import Foundation

enum NotificationType {
    case follow
    case like
    case weather
}

enum NotificationTimeSection: String, CaseIterable {
    case today = "今日"
    case yesterday = "昨日"
    case pastWeek = "過去一週間"
}

struct NotificationItem: Identifiable {
    let id: UUID
    let type: NotificationType
    let username: String?
    let message: String
    let postImageName: String?
    let avatarImageName: String?
    let timestamp: Date
    let timeSection: NotificationTimeSection
    
    init(
        id: UUID = UUID(),
        type: NotificationType,
        username: String? = nil,
        message: String,
        postImageName: String? = nil,
        avatarImageName: String? = nil,
        timestamp: Date = Date(),
        timeSection: NotificationTimeSection
    ) {
        self.id = id
        self.type = type
        self.username = username
        self.message = message
        self.postImageName = postImageName
        self.avatarImageName = avatarImageName
        self.timestamp = timestamp
        self.timeSection = timeSection
    }
}

// MARK: - Mock Data
extension NotificationItem {
    static let mockNotifications: [NotificationItem] = [
        // 今日
        NotificationItem(
            type: .follow,
            username: "tanaka_style",
            message: "tanaka_styleさんがあなたをフォローしました",
            timeSection: .today
        ),
        NotificationItem(
            type: .like,
            username: "fashion_lover",
            message: "fashion_loverさんがあなたの投稿に「いいね！」しました。",
            postImageName: "sample_outfit_1",
            timeSection: .today
        ),
        NotificationItem(
            type: .weather,
            message: "あなたの地域に雨雲が近づいています。",
            timeSection: .today
        ),
        
        // 昨日
        NotificationItem(
            type: .follow,
            username: "tokyo_fashion",
            message: "tokyo_fashionさんがあなたをフォローしました",
            timeSection: .yesterday
        ),
        NotificationItem(
            type: .like,
            username: "style_master",
            message: "style_masterさんがあなたの投稿に「いいね！」しました。",
            postImageName: "sample_outfit_2",
            timeSection: .yesterday
        ),
        NotificationItem(
            type: .weather,
            message: "あなたの地域に雨雲が近づいています。",
            timeSection: .yesterday
        ),
        
        // 過去一週間
        NotificationItem(
            type: .follow,
            username: "outfit_daily",
            message: "outfit_dailyさんがあなたをフォローしました",
            timeSection: .pastWeek
        ),
        NotificationItem(
            type: .like,
            username: "coord_queen",
            message: "coord_queenさんがあなたの投稿に「いいね！」しました。",
            postImageName: "sample_outfit_3",
            timeSection: .pastWeek
        ),
        NotificationItem(
            type: .weather,
            message: "あなたの地域に雨雲が近づいています。",
            timeSection: .pastWeek
        ),
    ]
}
