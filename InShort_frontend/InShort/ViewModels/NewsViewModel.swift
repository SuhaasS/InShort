import Foundation
import Combine
import SwiftData

class NewsViewModel: ObservableObject {
    @Published var recommendedBills: [Bill] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var userProfile: UserProfile?

    private var cancellables = Set<AnyCancellable>()
    private let subscriptionsKey = "subscribed_bill_ids"

    init() {
        loadData()
        
        // Listen for profile changes
        NotificationService.shared.profileDidChangePublisher
            .sink { [weak self] in
                self?.loadData()
            }
            .store(in: &cancellables)
    }

    func loadData() {
        isLoading = true
        error = nil

        Task {
            do {
                // Load user profile
                let profile = try await UserService.shared.fetchProfile()
                
                // Load recommended bills
                let loadedBills = try await BillService.shared.fetchRecommendedBills(for: profile)

                // Retrieve persisted subscription IDs
                let savedIDs = UserDefaults.standard.stringArray(forKey: subscriptionsKey) ?? []

                // Apply persisted subscriptions to the freshly loaded bills
                let updatedBills = loadedBills.map { bill -> Bill in
                    var copy = bill
                    copy.isSubscribed = savedIDs.contains(bill.id)
                    return copy
                }

                await MainActor.run {
                    self.recommendedBills = updatedBills
                    self.userProfile = profile
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

    func likeBill(_ bill: Bill) {
        Task {
            do {
                let updated = try await BillService.shared.likeBill(id: bill.id)
                await MainActor.run {
                    if let idx = recommendedBills.firstIndex(where: { $0.id == bill.id }) {
                        recommendedBills[idx].isLiked = updated.isLiked
                        recommendedBills[idx].isDisliked = updated.isDisliked
                    }
                }
            } catch {
                print("Error liking bill: \(error.localizedDescription)")
            }
        }
    }

    func dislikeBill(_ bill: Bill) {
        Task {
            do {
                let updated = try await BillService.shared.dislikeBill(id: bill.id)
                await MainActor.run {
                    if let idx = recommendedBills.firstIndex(where: { $0.id == bill.id }) {
                        recommendedBills[idx].isLiked = updated.isLiked
                        recommendedBills[idx].isDisliked = updated.isDisliked
                    }
                }
            } catch {
                print("Error disliking bill: \(error.localizedDescription)")
            }
        }
    }

    func toggleSubscription(_ bill: Bill) {
        Task {
            do {
                let currentState = bill.isSubscribed
                let updatedBill: Bill
                
                if currentState {
                    // Unsubscribe
                    updatedBill = try await BillService.shared.unsubscribeFromBill(id: bill.id)
                } else {
                    // Subscribe
                    updatedBill = try await BillService.shared.subscribeToBill(id: bill.id)
                    NotificationService.shared.scheduleBillUpdateNotification(for: updatedBill)
                }
                
                await MainActor.run {
                    // Update the bill in our local array
                    if let idx = recommendedBills.firstIndex(where: { $0.id == bill.id }) {
                        recommendedBills[idx].isSubscribed = updatedBill.isSubscribed
                    }
                    
                    // Update UserDefaults to keep the subscription list in sync
                    var saved = UserDefaults.standard.stringArray(forKey: subscriptionsKey) ?? []
                    if updatedBill.isSubscribed {
                        if !saved.contains(bill.id) {
                            saved.append(bill.id)
                        }
                    } else {
                        saved.removeAll { $0 == bill.id }
                    }
                    UserDefaults.standard.set(saved, forKey: subscriptionsKey)
                }
            } catch {
                print("Error toggling subscription: \(error.localizedDescription)")
                // Handle error - maybe show an alert
                await MainActor.run {
                    self.error = error
                }
            }
        }
    }
}
