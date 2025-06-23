import SwiftUI

struct NewsTabView: View {
    @StateObject private var viewModel = NewsViewModel()
    @State private var selectedTab = 0
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Modern search bar
                HStack(spacing: AppLayout.small) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.tertiaryText)
                        .font(.system(size: 16, weight: .medium))
                    
                    TextField("Search bills...", text: $searchText)
                        .font(AppTypography.body)
                        .textFieldStyle(.plain)
                }
                .padding(AppLayout.medium)
                .background(AppColors.secondaryBackground)
                .cornerRadius(AppLayout.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                        .stroke(AppColors.primary.opacity(searchText.isEmpty ? 0 : 0.3), lineWidth: 1)
                )
                .padding(.horizontal, AppLayout.screenPadding)
                .padding(.top, AppLayout.small)
                .padding(.bottom, AppLayout.medium)
                .background(AppColors.groupedBackground)

                // Content based on selected tab
                billsList(bills: viewModel.recommendedBills)
            }
            .navigationTitle("Recommended For You")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.loadData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    VStack(spacing: AppLayout.medium) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                            .scaleEffect(1.2)
                        
                        Text("Loading bills...")
                            .font(AppTypography.callout)
                            .foregroundColor(AppColors.secondaryText)
                    }
                    .padding(AppLayout.large)
                    .background(.ultraThinMaterial)
                    .cornerRadius(AppLayout.largeRadius)
                    .cardShadow()
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("Retry") {
                    viewModel.loadData()
                }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
        }
    }

    @ViewBuilder
    private func billsList(bills: [Bill]) -> some View {
        let filtered = bills.filter { bill in
            searchText.isEmpty ||
            bill.title.localizedCaseInsensitiveContains(searchText) ||
            bill.summary.localizedCaseInsensitiveContains(searchText) ||
            bill.sponsor.localizedCaseInsensitiveContains(searchText)
        }

        if filtered.isEmpty {
            emptyStateView(
                title: "No Recommendations Found",
                message: "We couldn't find any bills based on your interests. Please try updating your profile.",
                systemImage: "newspaper"
            )
        } else {
            ScrollView {
                LazyVStack(spacing: AppLayout.spacing) {
                    ForEach(filtered) { bill in
                        NavigationLink(destination: BillDetailView(
                            bill: bill,
                            onLike: { viewModel.likeBill(bill) },
                            onDislike: { viewModel.dislikeBill(bill) },
                            onSubscribe: { viewModel.toggleSubscription(bill) }
                        )) {
                            BillRowView(
                                bill: bill,
                                onLike: { viewModel.likeBill(bill) },
                                onDislike: { viewModel.dislikeBill(bill) },
                                onSubscribe: { viewModel.toggleSubscription(bill) },
                                onEmailRep: {}
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, AppLayout.screenPadding)
                .padding(.vertical, AppLayout.medium)
            }
            .background(AppColors.groupedBackground)
            .scrollContentBackground(.hidden)
            .refreshable { viewModel.loadData() }
        }
    }

    private func emptyStateView(title: String, message: String, systemImage: String) -> some View {
        VStack(spacing: AppLayout.large) {
            VStack(spacing: AppLayout.medium) {
                Image(systemName: systemImage)
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(AppColors.primary.opacity(0.6))

                Text(title)
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.text)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppLayout.xxLarge)
            }

            PrimaryButton(title: "Refresh", size: .medium) {
                viewModel.loadData()
            }
            .frame(maxWidth: 200)
        }
        .padding(AppLayout.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.groupedBackground)
    }

    private func refreshData() async {
        viewModel.loadData()
    }
}

struct NewsTabView_Previews: PreviewProvider {
    static var previews: some View {
    NewsTabView()
            .environment(\.colorScheme, .light)
        NewsTabView()
            .environment(\.colorScheme, .dark)
    }
}
