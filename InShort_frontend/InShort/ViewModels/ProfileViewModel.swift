import Foundation
import Combine

class ProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var isSaving = false
    @Published var saveError: Error?
    @Published var saveSuccess = false
    
    // Editable fields
    @Published var name: String = ""
    @Published var age: Int = 30
    @Published var location: String = ""
    @Published var selectedInterests: Set<String> = []

    // Notification settings
    @Published var notificationCadence: String = "immediate" // "immediate" | "daily" | "weekly"
    @Published var notificationTime: Date = Date()

    // Available interests for selection
    let availableInterests = [
        "Climate Change", "Healthcare", "Education", "Technology", "Veterans Affairs",
        "Immigration", "Economy", "National Security", "Infrastructure", "Civil Rights",
        "Gun Control", "Foreign Policy", "Taxes", "Energy", "Environment",
        "Agriculture", "Labor", "Housing", "Transportation", "Social Security"
    ]
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadProfile()
        loadNotificationSettings()
    }
    
    func loadProfile() {
        isLoading = true
        error = nil
        
        Task {
            do {
                let profile = try await UserService.shared.fetchProfile()
                
                await MainActor.run {
                    self.userProfile = profile
                    self.name = profile.name
                    self.age = profile.age
                    self.location = profile.location
                    self.selectedInterests = Set(profile.interests)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    func saveProfile() {
        guard var profile = userProfile else { return }
        
        isSaving = true
        saveError = nil
        saveSuccess = false
        
        // Update profile with edited values
        profile.name = name
        profile.age = age
        profile.location = location
        profile.interests = Array(selectedInterests)
        
        Task {
            do {
                let updatedProfile = try await UserService.shared.updateProfile(profile: profile)
                
                await MainActor.run {
                    self.userProfile = updatedProfile
                    self.isSaving = false
                    self.saveSuccess = true
                    self.saveNotificationSettings()
                    
                    // Notify other parts of the app that the profile has changed
                    NotificationService.shared.profileDidChangePublisher.send()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.saveSuccess = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.saveError = error
                    self.isSaving = false
                }
            }
        }
    }
    
    func toggleInterest(_ interest: String) {
        if selectedInterests.contains(interest) {
            selectedInterests.remove(interest)
        } else {
            selectedInterests.insert(interest)
        }
    }
    // MARK: - Notification Settings Persistence

    private func loadNotificationSettings() {
        let defaults = UserDefaults.standard
        notificationCadence = defaults.string(forKey: "notificationCadence") ?? "immediate"
        if let time = defaults.object(forKey: "notificationTime") as? Date {
            notificationTime = time
        }
    }

    private func saveNotificationSettings() {
        let defaults = UserDefaults.standard
        defaults.set(notificationCadence, forKey: "notificationCadence")
        defaults.set(notificationTime, forKey: "notificationTime")
    }
}
