import SwiftUI

struct BillComparisonView: View {
    let bill1: Bill
    let bill2: Bill
    let comparison: String

    @State private var showFullText1 = false
    @State private var showFullText2 = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppLayout.spacing) {
                HStack(alignment: .top, spacing: AppLayout.spacing) {
                    // First Bill Card
                    VStack(alignment: .leading, spacing: AppLayout.spacing) {
                        Text(bill1.title)
                            .font(AppTypography.title)
                            .foregroundColor(AppColors.text)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Sponsored by: \(bill1.sponsor)")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondaryText)

                        Text(bill1.summary)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.text)
                            .fixedSize(horizontal: false, vertical: true)

                        Button("Read Full Text") {
                            showFullText1.toggle()
                        }
                        .font(AppTypography.subheadline)
                        .sheet(isPresented: $showFullText1) {
                            FullTextView(title: bill1.title, fullText: bill1.fullText ?? "Full text not available.")
                        }
                    }
                    .padding()
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(AppLayout.cornerRadius)
                    .frame(maxWidth: .infinity)

                    // Second Bill Card
                    VStack(alignment: .leading, spacing: AppLayout.spacing) {
                        Text(bill2.title)
                            .font(AppTypography.title)
                            .foregroundColor(AppColors.text)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Sponsored by: \(bill2.sponsor)")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondaryText)

                        Text(bill2.summary)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.text)
                            .fixedSize(horizontal: false, vertical: true)

                        Button("Read Full Text") {
                            showFullText2.toggle()
                        }
                        .font(AppTypography.subheadline)
                        .sheet(isPresented: $showFullText2) {
                            FullTextView(title: bill2.title, fullText: bill2.fullText ?? "Full text not available.")
                        }
                    }
                    .padding()
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(AppLayout.cornerRadius)
                    .frame(maxWidth: .infinity)
                }

                // Comparison Section
                VStack(alignment: .leading, spacing: AppLayout.spacing) {
                    Text("AI-Generated Comparison")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.text)

                    if comparison.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        Text(comparison)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.text)
                            .padding()
                            .background(AppColors.background)
                            .cornerRadius(AppLayout.cornerRadius)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .padding()
        }
    }
}

private struct FullTextView: View {
    let title: String
    let fullText: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                Text(fullText)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.text)
                    .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct BillComparisonView_Previews: PreviewProvider {
    static var previews: some View {
        BillComparisonView(
            bill1: Bill(
                id: "HR1234",
                title: "Clean Energy Innovation Act",
                summary: "A bill to promote research and development in clean energy technologies and provide tax incentives for clean energy production.",
                fullText: "Full text of bill 1 goes here...",
                sponsor: "Rep. Jane Smith (D-CA)",
                relevanceScore: 0.8
            ),
            bill2: Bill(
                id: "S2345",
                title: "National Defense Authorization Act",
                summary: "Annual bill that authorizes funding for the Department of Defense and sets policies for defense programs.",
                fullText: "Full text of bill 2 goes here...",
                sponsor: "Sen. John Miller (R-TX)",
                relevanceScore: -0.7
            ),
            comparison: "Here will appear the AI-generated comparison between the two bills..."
        )
    }
}
