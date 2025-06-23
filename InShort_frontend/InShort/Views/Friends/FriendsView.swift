import SwiftUI

struct FriendsView: View {
    @StateObject private var viewModel = FriendsViewModel()

    var body: some View {
        List {
            if viewModel.friendActivity.isEmpty {
                ContentUnavailableView(
                    "No Friend Activity",
                    systemImage: "person.2",
                    description: Text("When your friends like or bump bills, you'll see their activity here.")
                )
            } else {
                ForEach(viewModel.friendActivity) { activity in
                    FriendActivityRow(activity: activity) {
                        viewModel.bumpBill(activity.bill)
                    }
                }
            }
        }
        .navigationTitle("Friends Feed")
        .refreshable {
            viewModel.loadFriends()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading activity...")
                    .padding()
                    .background(Color(.systemBackground).opacity(0.8))
                    .cornerRadius(10)
                    .shadow(radius: 10)
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("Retry") {
                viewModel.loadFriends()
            }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }
}

struct FriendActivityRow: View {
    let activity: FriendActivity
    let onBump: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Friend info and activity type
            HStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.friend.name)
                        .font(.headline)

                    HStack {
                        Image(systemName: activity.activityType.icon)
                            .foregroundColor(activity.activityType == .like ? .blue : .green)

                        Text("\(activity.activityType.description) this bill")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text(activity.timestamp, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Bill info
            VStack(alignment: .leading, spacing: 8) {
                Text(activity.bill.title)
                    .font(.headline)

                Text(activity.bill.summary)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack {
                    Spacer()

                    Button(action: onBump) {
                        Label("Bump", systemImage: "arrowshape.turn.up.right")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.green)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
        .padding(.vertical, 8)
    }
}

// Add a navigation link to the ProfileTabView
extension ProfileTabView {
    var friendsSection: some View {
        Section(header: Text("Social")) {
            NavigationLink(destination: FriendsView()) {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.blue)
                    Text("Friends Feed")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        FriendsView()
    }
}
