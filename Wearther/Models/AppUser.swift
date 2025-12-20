//
//  AppUser.swift
//  Wearther
//
//  Created by 阿久津咲千 on 2025/12/18.
//

import Foundation
import FirebaseFirestore

struct AppUser: Codable, Identifiable {
    @DocumentID var id: String?
    
    var email: String
    var username: String
    var displayName: String
    var avatarURL: String?
    var bio: String?
    var postsCount: Int
    var followersCount: Int
    var followingCount: Int
    var gender: String?
    var location: String?
    var temperatureTolerance: String?
    var createdAt: Date
}
