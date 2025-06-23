import Foundation
import SwiftData

struct RecommendedBill: Decodable, Identifiable {
    let id: String
    let score: Double
    let title: String
    let bill_number: String
    let bill_type: String
    let sponsor: String
    let congress: Double
    let policy_area: String
    let latest_action: String
    let summary: String
}

@Model
final class Bill: Identifiable, Codable {
    @Attribute(.unique) var id: String
    var title: String
    var summary: String
    var fullText: String?
    var sponsor: String
    var relevanceScore: Double?
    var isLiked: Bool
    var isDisliked: Bool
    var isSubscribed: Bool
    var dateIntroduced: Date?
    var lastUpdated: Date?
    var billNumber: String?
    var billType: String?
    var congress: String?
    var policyArea: String?
    var latestAction: String?

    enum CodingKeys: String, CodingKey {
        case id, title, summary, fullText, sponsor, isLiked, isDisliked, isSubscribed, dateIntroduced, lastUpdated, billNumber, billType, congress, policyArea, latestAction
        case relevanceScore = "partyScore"  // Map partyScore from JSON to relevanceScore
    }

    init(
        id: String,
        title: String,
        summary: String,
        fullText: String? = nil,
        sponsor: String,
        relevanceScore: Double? = nil,
        isLiked: Bool = false,
        isDisliked: Bool = false,
        isSubscribed: Bool = false,
        dateIntroduced: Date? = nil,
        lastUpdated: Date? = nil,
        billNumber: String? = nil,
        billType: String? = nil,
        congress: String? = nil,
        policyArea: String? = nil,
        latestAction: String? = nil
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.fullText = fullText
        self.sponsor = sponsor
        self.relevanceScore = relevanceScore
        self.isLiked = isLiked
        self.isDisliked = isDisliked
        self.isSubscribed = isSubscribed
        self.dateIntroduced = dateIntroduced
        self.lastUpdated = lastUpdated
        self.billNumber = billNumber
        self.billType = billType
        self.congress = congress
        self.policyArea = policyArea
        self.latestAction = latestAction
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        summary = try c.decode(String.self, forKey: .summary)
        fullText = try c.decodeIfPresent(String.self, forKey: .fullText)
        sponsor = try c.decode(String.self, forKey: .sponsor)
        relevanceScore = try c.decodeIfPresent(Double.self, forKey: .relevanceScore)
        isLiked = try c.decode(Bool.self, forKey: .isLiked)
        isDisliked = try c.decode(Bool.self, forKey: .isDisliked)
        isSubscribed = try c.decode(Bool.self, forKey: .isSubscribed)
        dateIntroduced = try c.decodeIfPresent(Date.self, forKey: .dateIntroduced)
        lastUpdated = try c.decodeIfPresent(Date.self, forKey: .lastUpdated)
        billNumber = try c.decodeIfPresent(String.self, forKey: .billNumber)
        billType = try c.decodeIfPresent(String.self, forKey: .billType)
        congress = try c.decodeIfPresent(String.self, forKey: .congress)
        policyArea = try c.decodeIfPresent(String.self, forKey: .policyArea)
        latestAction = try c.decodeIfPresent(String.self, forKey: .latestAction)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(summary, forKey: .summary)
        try c.encode(fullText, forKey: .fullText)
        try c.encode(sponsor, forKey: .sponsor)
        try c.encode(relevanceScore, forKey: .relevanceScore)
        try c.encode(isLiked, forKey: .isLiked)
        try c.encode(isDisliked, forKey: .isDisliked)
        try c.encode(isSubscribed, forKey: .isSubscribed)
        try c.encode(dateIntroduced, forKey: .dateIntroduced)
        try c.encode(lastUpdated, forKey: .lastUpdated)
        try c.encode(billNumber, forKey: .billNumber)
        try c.encode(billType, forKey: .billType)
        try c.encode(congress, forKey: .congress)
        try c.encode(policyArea, forKey: .policyArea)
        try c.encode(latestAction, forKey: .latestAction)
    }
}
