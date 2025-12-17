//
//  Contact.swift
//  360Surreal
//
//  Created by William Loftus on 10/12/25.
//

import Foundation
import SwiftUI

/// Domain entity representing a contact
struct Contact360: Identifiable, Codable, Equatable {
    let id: String
    let firstName: String?
    let lastName: String?
    let company: String?
    let jobTitle: String?
    let emails: [ContactEmail]
    let phones: [ContactPhone]
    let avatar: URL?
    let notes: String?
    let isFavorite: Bool
    let tags: [String]
    let createdAt: Date
    let updatedAt: Date

    init(
        id: String = UUID().uuidString,
        firstName: String? = nil,
        lastName: String? = nil,
        company: String? = nil,
        jobTitle: String? = nil,
        emails: [ContactEmail] = [],
        phones: [ContactPhone] = [],
        avatar: URL? = nil,
        notes: String? = nil,
        isFavorite: Bool = false,
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.company = company
        self.jobTitle = jobTitle
        self.emails = emails
        self.phones = phones
        self.avatar = avatar
        self.notes = notes
        self.isFavorite = isFavorite
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var displayName: String {
        let fullName = [firstName, lastName]
            .compactMap { $0 }
            .joined(separator: " ")
        
        if fullName.isEmpty {
            return company ?? primaryEmail ?? "Unknown Contact"
        }
        
        return fullName
    }

    var initials: String {
        let first = firstName?.first.map(String.init) ?? ""
        let last = lastName?.first.map(String.init) ?? ""
        let result = (first + last).uppercased()
        
        if result.isEmpty {
            return company?.first.map(String.init)?.uppercased() ?? "?"
        }
        
        return result
    }

    var primaryEmail: String? {
        emails.first(where: { $0.isPrimary })?.email ?? emails.first?.email
    }

    var primaryPhone: String? {
        phones.first(where: { $0.isPrimary })?.phone ?? phones.first?.phone
    }

    var avatarColor: Color {
        // Generate consistent color based on ID
        let colors: [Color] = [.blue, .green, .orange, .purple, .red, .indigo, .pink, .teal, .mint, .cyan]
        let index = abs(id.hashValue) % colors.count
        return colors[index]
    }
}

struct ContactEmail: Codable, Equatable, Identifiable {
    let id: String
    let email: String
    let label: String
    let isPrimary: Bool

    init(id: String = UUID().uuidString, email: String, label: String = "Email", isPrimary: Bool = false) {
        self.id = id
        self.email = email
        self.label = label
        self.isPrimary = isPrimary
    }
}

struct ContactPhone: Codable, Equatable, Identifiable {
    let id: String
    let phone: String
    let label: String
    let isPrimary: Bool

    init(id: String = UUID().uuidString, phone: String, label: String = "Phone", isPrimary: Bool = false) {
        self.id = id
        self.phone = phone
        self.label = label
        self.isPrimary = isPrimary
    }
}
