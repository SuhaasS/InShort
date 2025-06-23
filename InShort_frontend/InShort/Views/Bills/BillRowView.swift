import SwiftUI

struct BillRowView: View {
    let bill: Bill
    var onLike: () -> Void
    var onDislike: () -> Void
    var onSubscribe: () -> Void
    var onEmailRep: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.medium) {
            // Title and party badge
            HStack(alignment: .top, spacing: AppLayout.medium) {
                VStack(alignment: .leading, spacing: AppLayout.xSmall) {
                    Text(bill.title)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.text)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text("Sponsored by \(bill.sponsor)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.tertiaryText)
                }

                Spacer(minLength: AppLayout.small)

                PartyScoreBadge(sponsor: bill.sponsor)
            }

            // Summary
            Text(bill.summary)
                .font(AppTypography.body)
                .foregroundColor(AppColors.secondaryText)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            // Action buttons with modern design
            HStack(spacing: AppLayout.small) {
                // Like button
                Button(action: onLike) {
                    HStack(spacing: AppLayout.xSmall) {
                        Image(systemName: bill.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 14, weight: .medium))
                        if bill.isLiked {
                            Text("Liked")
                                .font(AppTypography.caption2)
                        }
                    }
                    .foregroundColor(bill.isLiked ? AppColors.success : AppColors.secondaryText)
                    .padding(.horizontal, AppLayout.small)
                    .padding(.vertical, AppLayout.xSmall)
                    .background(
                        Capsule()
                            .fill(bill.isLiked ? AppColors.success.opacity(0.1) : AppColors.secondaryBackground)
                    )
                }
                .accessibilityElement(
                    label: bill.isLiked ? "Unlike bill" : "Like bill",
                    hint: "Double tap to \(bill.isLiked ? "unlike" : "like") this bill"
                )

                // Dislike button
                Button(action: onDislike) {
                    HStack(spacing: AppLayout.xSmall) {
                        Image(systemName: bill.isDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                            .font(.system(size: 14, weight: .medium))
                        if bill.isDisliked {
                            Text("Disliked")
                                .font(AppTypography.caption2)
                        }
                    }
                    .foregroundColor(bill.isDisliked ? AppColors.destructive : AppColors.secondaryText)
                    .padding(.horizontal, AppLayout.small)
                    .padding(.vertical, AppLayout.xSmall)
                    .background(
                        Capsule()
                            .fill(bill.isDisliked ? AppColors.destructive.opacity(0.1) : AppColors.secondaryBackground)
                    )
                }
                .accessibilityElement(
                    label: bill.isDisliked ? "Remove dislike" : "Dislike bill",
                    hint: "Double tap to \(bill.isDisliked ? "remove your dislike from" : "dislike") this bill"
                )

                Spacer()

                // Subscribe/Unsubscribe button
                Button(action: onSubscribe) {
                    HStack(spacing: AppLayout.xSmall) {
                        Image(systemName: bill.isSubscribed ? "bell.fill" : "bell")
                            .font(.system(size: 14, weight: .medium))
                        Text(bill.isSubscribed ? "Subscribed" : "Subscribe")
                            .font(AppTypography.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(bill.isSubscribed ? .white : AppColors.primary)
                    .padding(.horizontal, AppLayout.medium)
                    .padding(.vertical, AppLayout.small)
                    .background(
                        Capsule()
                            .fill(bill.isSubscribed ? AppColors.primary : AppColors.primary.opacity(0.1))
                    )
                }
                .accessibilityElement(
                    label: bill.isSubscribed ? "Unsubscribe from bill" : "Subscribe to bill",
                    hint: "Double tap to \(bill.isSubscribed ? "unsubscribe from" : "subscribe to") this bill and receive notifications"
                )

                // Email Rep button
                IconButton(icon: "envelope", style: .ghost) {
                    onEmailRep()
                }
                .accessibilityElement(
                    label: "Email representative",
                    hint: "Double tap to compose an email to the bill's sponsor"
                )
            }
        }
        .padding(AppLayout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.largeRadius)
                .fill(AppColors.cardBackground)
        )
        .cardShadow()
        .accessibilityElement(
            label: "Bill: \(bill.title)",
            hint: "Sponsored by \(bill.sponsor). Double tap to view details."
        )
        .accessibilityAction(.default) {
            // Handled by NavigationLink in parent view
        }
    }
}

struct PartyScoreBadge: View {
    let sponsor: String

    var body: some View {
        Text(partyLabel)
            .font(AppTypography.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, AppLayout.medium)
            .padding(.vertical, AppLayout.small)
            .background(
                RoundedRectangle(cornerRadius: AppLayout.smallRadius)
                    .fill(partyGradient)
            )
            .accessibilityElement(
                label: "Party affiliation: \(partyLabelAccessible)",
                hint: "This bill is sponsored by a \(partyLabelAccessible) member of Congress"
            )
    }

    private var party: String {
        // Extract party from sponsor string 
        // Handle both formats: "Rep. Jane Smith (D-CA)" and "Sponsored by Rep. Garbarino, Andrew R. [R-NY-2]"
        
        // Try regex for square brackets first (API format)
        if let range = sponsor.range(of: "\\[[DR]-[A-Z]{2}-?\\d*\\]", options: .regularExpression) {
            let partyState = String(sponsor[range])
            if partyState.contains("D-") {
                return "D"
            } else if partyState.contains("R-") {
                return "R"
            }
        }
        
        // Try regex for parentheses (fixture format)
        if let range = sponsor.range(of: "\\([DR]-[A-Z]{2}\\)", options: .regularExpression) {
            let partyState = String(sponsor[range])
            if partyState.contains("D-") {
                return "D"
            } else if partyState.contains("R-") {
                return "R"
            }
        }
        
        // Fallback to simple string search for both formats
        if sponsor.contains("[D-") || sponsor.contains("(D-") {
            return "D"
        } else if sponsor.contains("[R-") || sponsor.contains("(R-") {
            return "R"
        }
        
        return "I" // Independent if not found
    }
    
    private var partyLabel: String {
        switch party {
        case "D":
            return "D-Leaning"
        case "R":
            return "R-Leaning"
        default:
            return "Independent"
        }
    }

    private var partyLabelAccessible: String {
        switch party {
        case "D":
            return "Democratic"
        case "R":
            return "Republican"
        default:
            return "Independent"
        }
    }
    
    private var partyGradient: LinearGradient {
        switch party {
        case "D":
            return LinearGradient(
                colors: [AppColors.democratic, Color(red: 0.4, green: 0.6, blue: 1.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "R":
            return LinearGradient(
                colors: [AppColors.republican, Color(red: 1.0, green: 0.4, blue: 0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [AppColors.bipartisan, Color(red: 0.8, green: 0.6, blue: 1.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

#Preview {
    BillRowView(
        bill: Bill(
            id: "HR1234",
            title: "Clean Energy Innovation Act",
            summary: "A bill to promote research and development in clean energy technologies and provide tax incentives for clean energy production.",
            fullText: "This is the full text of the bill",
            sponsor: "Rep. Jane Smith (D-CA)",
            relevanceScore: 0.8,
            isLiked: true,
            isDisliked: false,
            isSubscribed: true
        ),
        onLike: {},
        onDislike: {},
        onSubscribe: {},
        onEmailRep: {}
    )
    .padding()
    .previewLayout(.sizeThatFits)
}
