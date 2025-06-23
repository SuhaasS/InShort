import Foundation
import Combine

class UserService {
    static let shared = UserService()

    private init() {}

    private let userProfileKey = "userProfile"

    // MARK: - User Profile

    func fetchProfile() async throws -> UserProfile {
        if let data = UserDefaults.standard.data(forKey: userProfileKey) {
            do {
                let profile = try JSONDecoder().decode(UserProfile.self, from: data)
                return profile
            } catch {
                // If decoding fails, fall back to fixture
                print("Failed to decode profile from UserDefaults, falling back to fixture. Error: \(error)")
            }
        }

        // If no data in UserDefaults, load from fixture and save it
        let profile = try loadUserProfileFromFixture()
        try await updateProfile(profile: profile) // Save the fixture profile to start
        return profile
    }

    func updateProfile(profile: UserProfile) async throws -> UserProfile {
        do {
            let data = try JSONEncoder().encode(profile)
            UserDefaults.standard.set(data, forKey: userProfileKey)
            return profile
        } catch {
            print("Failed to encode or save profile: \(error)")
            throw error
        }
    }

    // MARK: - Friends

    func fetchFriends() async throws -> [UserProfile] {
        do {
            if DEBUG_USE_FAKE_DATA {
                // In a real app, this would fetch friends from a database or API
                // For now, we'll just return an empty array
                return []
            } else {
                // Call the API to fetch friends
                let url = FRIENDS_API_URL
                let (data, response) = try await URLSession.shared.data(from: url)

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }

                return try JSONDecoder().decode([UserProfile].self, from: data)
            }
        } catch {
            // If API call fails, log the error and return an empty array
            print("Error fetching friends: \(error.localizedDescription)")
            return []
        }
    }

    func addFriend(id: String) async throws -> UserProfile {
        do {
            if DEBUG_USE_FAKE_DATA {
                // In debug mode, create a fake friend profile
                let fakeFriend = UserProfile(
                    id: id,
                    name: "Friend \(id)",
                    age: Int.random(in: 18...65),
                    location: "United States",
                    interests: ["politics", "legislation"],
                    occupation: "Citizen"
                )
                return fakeFriend
            } else {
                // Call the API to add a friend
                let url = URL(string: "\(FRIEND_ADD_API_URL.absoluteString)\(id)")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }

                return try JSONDecoder().decode(UserProfile.self, from: data)
            }
        } catch {
            // If API call fails, log the error and create a placeholder friend
            print("Error adding friend: \(error.localizedDescription)")

            // Create a placeholder friend profile
            let placeholderFriend = UserProfile(
                id: id,
                name: "Friend \(id)",
                age: 30,
                location: "Unknown",
                interests: [],
                occupation: nil
            )
            return placeholderFriend
        }
    }

    func removeFriend(id: String) async throws {
        do {
            if DEBUG_USE_FAKE_DATA {
                // In debug mode, just pretend we removed the friend
                print("DEBUG: Pretending to remove friend with ID: \(id)")
                // No action needed in debug mode
                return
            } else {
                // Call the API to remove a friend
                let url = URL(string: "\(FRIEND_REMOVE_API_URL.absoluteString)\(id)")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let (_, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }

                // Success, no return value needed
            }
        } catch {
            // If API call fails, log the error but don't throw
            // This allows the UI to update as if the friend was removed
            print("Error removing friend: \(error.localizedDescription)")
            // We don't throw here, so the UI can proceed as if the operation succeeded
            // The next time the friends list is refreshed, it will show the correct state
        }
    }

    // MARK: - Helper Methods

    private func loadUserProfileFromFixture() throws -> UserProfile {
        guard let url = Bundle.main.url(
                forResource: "userProfile",
                withExtension: "json"
        ) else {
            fatalError("userProfile.json not found in bundle")
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(UserProfile.self, from: data)
    }
}
