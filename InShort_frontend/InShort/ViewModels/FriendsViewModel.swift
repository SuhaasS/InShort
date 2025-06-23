import Foundation
import Combine

class FriendsViewModel: ObservableObject {
    @Published var friends: [UserProfile] = []
    @Published var friendActivity: [FriendActivity] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadFriends()
    }
    
    func loadFriends() {
        isLoading = true
        error = nil
        
        Task {
            do {
                let loadedFriends = try await UserService.shared.fetchFriends()
                
                // Generate some fake activity for friends
                var activities: [FriendActivity] = []
                
                if DEBUG_USE_FAKE_DATA {
                    let bills = try await BillService.shared.fetchBills()
                    
                    for friend in loadedFriends {
                        // Randomly assign some bills as liked or bumped by friends
                        let randomBills = bills.shuffled().prefix(Int.random(in: 1...3))
                        
                        for bill in randomBills {
                            let isLike = Bool.random()
                            let activity = FriendActivity(
                                id: UUID(),
                                friend: friend,
                                bill: bill,
                                activityType: isLike ? .like : .bump,
                                timestamp: Date().addingTimeInterval(-Double.random(in: 0...86400)) // Random time in last 24 hours
                            )
                            activities.append(activity)
                        }
                    }
                    
                    // Sort activities by timestamp (newest first)
                    activities.sort { $0.timestamp > $1.timestamp }
                }
                
                await MainActor.run {
                    self.friends = loadedFriends
                    self.friendActivity = activities
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
    
    func bumpBill(_ bill: Bill) {
        // In a real app, this would call an API to bump the bill
        // For now, we'll just print a message
        print("Bumped bill: \(bill.title)")
    }
}

// Friend activity model
struct FriendActivity: Identifiable {
    enum ActivityType {
        case like
        case bump
        
        var description: String {
            switch self {
            case .like:
                return "liked"
            case .bump:
                return "bumped"
            }
        }
        
        var icon: String {
            switch self {
            case .like:
                return "hand.thumbsup.fill"
            case .bump:
                return "arrowshape.turn.up.right.fill"
            }
        }
    }
    
    let id: UUID
    let friend: UserProfile
    let bill: Bill
    let activityType: ActivityType
    let timestamp: Date
}