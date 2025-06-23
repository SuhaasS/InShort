import SwiftUI

struct SubscriptionsView: View {
    @StateObject private var newsViewModel = NewsViewModel()

    private var subscribedBills: [Bill] {
        newsViewModel.recommendedBills.filter { $0.isSubscribed }
    }

    var body: some View {
        List {
            if subscribedBills.isEmpty {
                ContentUnavailableView(
                    "No Subscriptions",
                    systemImage: "bell.slash",
                    description: Text("You haven't subscribed to any bills yet. Subscribe to bills to receive updates when they change.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(subscribedBills) { bill in
                    VStack(alignment: .leading, spacing: AppLayout.medium) {
                        VStack(alignment: .leading, spacing: AppLayout.xSmall) {
                            Text(bill.title)
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.text)
                            
                            Text(bill.summary)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.secondaryText)
                                .lineLimit(3)
                        }
                        
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                newsViewModel.toggleSubscription(bill)
                            }) {
                                HStack(spacing: AppLayout.xSmall) {
                                    Image(systemName: "bell.slash")
                                        .font(.system(size: 12, weight: .medium))
                                    Text("Unsubscribe")
                                        .font(AppTypography.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(AppColors.destructive)
                                .padding(.horizontal, AppLayout.medium)
                                .padding(.vertical, AppLayout.small)
                                .background(AppColors.destructive.opacity(0.1))
                                .cornerRadius(AppLayout.smallRadius)
                            }
                        }
                    }
                    .padding(AppLayout.cardPadding)
                    .background(AppColors.cardBackground)
                    .cornerRadius(AppLayout.largeRadius)
                    .cardShadow()
                    // swipe to unsubscribe
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            newsViewModel.toggleSubscription(bill)
                        } label: {
                            Label("Unsubscribe", systemImage: "bell.slash")
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppColors.groupedBackground)
        .navigationTitle("Subscriptions")
        .onAppear {
            if newsViewModel.recommendedBills.isEmpty {
                newsViewModel.loadData()
            }
        }
    }
}

struct SubscriptionsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SubscriptionsView()
        }
    }
}
