import SwiftUI

struct ProfileTabView: View {
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppLayout.large) {
                    // Profile Header
                    VStack(spacing: AppLayout.medium) {
                        Circle()
                            .fill(LinearGradient(
                                colors: [AppColors.primary, AppColors.primary.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(.white)
                            )
                        
                        Text(viewModel.name.isEmpty ? "Your Profile" : viewModel.name)
                            .font(AppTypography.title2)
                            .foregroundColor(AppColors.text)
                    }
                    .padding(.top, AppLayout.medium)
                    
                    // Personal Information Card
                    PersonalInfoCard(viewModel: viewModel)
                    
                    // Interests Card
                    InterestsCard(viewModel: viewModel)
                    
                    // Notifications Card
                    NotificationsCard(viewModel: viewModel)
                    
                    // Save Button
                    PrimaryButton(
                        title: "Save Changes",
                        isLoading: viewModel.isSaving
                    ) {
                        viewModel.saveProfile()
                    }
                    .padding(.horizontal, AppLayout.screenPadding)
                    
                    // Success Message
                    if viewModel.saveSuccess {
                        HStack(spacing: AppLayout.small) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppColors.success)
                            Text("Profile updated successfully!")
                                .font(AppTypography.callout)
                                .foregroundColor(AppColors.success)
                        }
                        .padding(AppLayout.medium)
                        .background(AppColors.success.opacity(0.1))
                        .cornerRadius(AppLayout.cornerRadius)
                        .padding(.horizontal, AppLayout.screenPadding)
                    }
                    
                    // Additional Sections
                    VStack(spacing: AppLayout.medium) {
                        NavigationLink(destination: SubscriptionsView()) {
                            SettingsRow(
                                icon: "bell.fill",
                                title: "Manage Bill Subscriptions",
                                iconColor: AppColors.accent
                            )
                        }
                        
                        Button(action: {
                            // Sign out action
                        }) {
                            SettingsRow(
                                icon: "arrow.right.square",
                                title: "Sign Out",
                                iconColor: AppColors.destructive,
                                textColor: AppColors.destructive
                            )
                        }
                    }
                }
                .padding(.horizontal, AppLayout.screenPadding)
                .padding(.bottom, AppLayout.xxLarge)
            }
            .background(AppColors.groupedBackground)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if viewModel.isLoading {
                    VStack(spacing: AppLayout.medium) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                        Text("Loading profile...")
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
                    viewModel.loadProfile()
                }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
            .alert("Save Error", isPresented: .constant(viewModel.saveError != nil)) {
                Button("OK") {}
            } message: {
                if let error = viewModel.saveError {
                    Text("Failed to save profile: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Card Components

struct PersonalInfoCard: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.medium) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.primary)
                Text("Personal Information")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.text)
                Spacer()
            }
            
            VStack(spacing: AppLayout.medium) {
                HStack {
                    TextField("Name", text: $viewModel.name)
                        .font(AppTypography.body)
                        .textFieldStyle(.plain)
                        .textContentType(.name)
                        .padding(AppLayout.medium)
                        .background(AppColors.secondaryBackground)
                        .cornerRadius(AppLayout.cornerRadius)
                }
                
                HStack {
                    Text("Age")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.text)
                    Spacer()
                    Text("\(viewModel.age)")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.text)
                        .padding(.trailing, AppLayout.small)
                    Stepper("", value: $viewModel.age, in: 18...100)
                        .labelsHidden()
                }
                .padding(AppLayout.medium)
                .background(AppColors.secondaryBackground)
                .cornerRadius(AppLayout.cornerRadius)
                
                HStack {
                    TextField("Location", text: $viewModel.location)
                        .font(AppTypography.body)
                        .textFieldStyle(.plain)
                        .textContentType(.addressCity)
                        .padding(AppLayout.medium)
                        .background(AppColors.secondaryBackground)
                        .cornerRadius(AppLayout.cornerRadius)
                }
            }
        }
        .padding(AppLayout.cardPadding)
        .background(AppColors.cardBackground)
        .cornerRadius(AppLayout.largeRadius)
        .cardShadow()
    }
}

struct InterestsCard: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.medium) {
            HStack {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.secondary)
                Text("Causes You Care About")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.text)
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppLayout.small) {
                    ForEach(viewModel.availableInterests, id: \.self) { interest in
                        ModernInterestToggleButton(
                            interest: interest,
                            isSelected: viewModel.selectedInterests.contains(interest),
                            action: {
                                viewModel.toggleInterest(interest)
                            }
                        )
                    }
                }
                .padding(.horizontal, AppLayout.small)
            }
            
            Text("Selected: \(viewModel.selectedInterests.count) interests")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText)
        }
        .padding(AppLayout.cardPadding)
        .background(AppColors.cardBackground)
        .cornerRadius(AppLayout.largeRadius)
        .cardShadow()
    }
}

struct NotificationsCard: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.medium) {
            HStack {
                Image(systemName: "bell.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.accent)
                Text("Notification Settings")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.text)
                Spacer()
            }
            
            VStack(spacing: AppLayout.medium) {
                Picker("Notify", selection: $viewModel.notificationCadence) {
                    Text("Immediate").tag("immediate")
                    Text("Daily Digest").tag("daily")
                }
                .pickerStyle(.segmented)
                
                if viewModel.notificationCadence == "daily" {
                    HStack {
                        Text("Time")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.text)
                        Spacer()
                        DatePicker("", selection: $viewModel.notificationTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    .padding(AppLayout.medium)
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(AppLayout.cornerRadius)
                }
            }
        }
        .padding(AppLayout.cardPadding)
        .background(AppColors.cardBackground)
        .cornerRadius(AppLayout.largeRadius)
        .cardShadow()
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let iconColor: Color
    var textColor: Color = AppColors.text
    
    var body: some View {
        HStack(spacing: AppLayout.medium) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            Text(title)
                .font(AppTypography.body)
                .foregroundColor(textColor)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.tertiaryText)
        }
        .padding(AppLayout.cardPadding)
        .background(AppColors.cardBackground)
        .cornerRadius(AppLayout.largeRadius)
        .cardShadow()
    }
}

struct ModernInterestToggleButton: View {
    let interest: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(interest)
                .font(AppTypography.caption)
                .fontWeight(isSelected ? .semibold : .medium)
                .padding(.horizontal, AppLayout.medium)
                .padding(.vertical, AppLayout.small)
                .background(
                    RoundedRectangle(cornerRadius: AppLayout.largeRadius)
                        .fill(isSelected ? 
                              LinearGradient(colors: [AppColors.primary, AppColors.primary.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                              LinearGradient(colors: [AppColors.secondaryBackground, AppColors.secondaryBackground], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                )
                .foregroundColor(isSelected ? .white : AppColors.text)
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.largeRadius)
                        .stroke(isSelected ? Color.clear : AppColors.primary.opacity(0.2), lineWidth: 1)
                )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    ProfileTabView()
}
