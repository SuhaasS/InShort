import Foundation
import SwiftData

@Model
final class UserProfile: Identifiable, Codable {
    @Attribute(.unique) var id: String
    var name: String
    var age: Int
    var location: String
    var interests: [String]
    var occupation: String?
    @Relationship(deleteRule: .cascade) var friends: [UserProfile]
    @Relationship(deleteRule: .nullify)
    var subscriptions: [Bill]


    enum CodingKeys: String, CodingKey {
        case id, name, age, location, interests, friends, subscriptions, occupation
    }

    init(id: String = UUID().uuidString, name: String, age: Int, location: String, 
         interests: [String] = [], friends: [UserProfile] = [], subscriptions: [Bill] = [], occupation: String? = nil) {
        self.id = id
        self.name = name
        self.age = age
        self.location = location
        self.interests = interests
        self.friends = friends
        self.subscriptions = subscriptions
        self.occupation = occupation
    }

    // Required for Codable conformance with SwiftData
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        age = try container.decode(Int.self, forKey: .age)
        location = try container.decode(String.self, forKey: .location)
        interests = try container.decode([String].self, forKey: .interests)
        friends = try container.decode([UserProfile].self, forKey: .friends)
        subscriptions = try container.decode([Bill].self, forKey: .subscriptions)
        occupation = try container.decodeIfPresent(String.self, forKey: .occupation)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(age, forKey: .age)
        try container.encode(location, forKey: .location)
        try container.encode(interests, forKey: .interests)
        try container.encode(friends, forKey: .friends)
        try container.encode(subscriptions, forKey: .subscriptions)
        try container.encode(occupation, forKey: .occupation)
    }
}
