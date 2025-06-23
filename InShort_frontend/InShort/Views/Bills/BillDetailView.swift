import SwiftUI
import MessageUI
import MapKit

struct ShareBillButton: View {
    let billID: String
    var body: some View {
        ShareLink(item: URL(string: "https://www.congress.gov/bill/\(billID)")!) {
            Image(systemName: "square.and.arrow.up")
        }
    }
}

struct BillDetailView: View {
    let bill: Bill
    var onLike: () -> Void
    var onDislike: () -> Void
    var onSubscribe: () -> Void

    @State private var isShowingMailComposer = false
    @State private var mailResult: Result<MFMailComposeResult, Error>? = nil
    @State private var isShowingFullTextSheet = false
    
    // 1️⃣ New state to hold fetched text
    @State private var fetchedFullText: String? = nil
    @State private var fetchError: Error?    = nil

    
    // NEW: state for our map
    @State private var votes: [StateVote] = []

    var body: some View {
        ScrollView {
            VStack(spacing: AppLayout.large) {
                // Header Card
                VStack(alignment: .leading, spacing: AppLayout.medium) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: AppLayout.xSmall) {
                            Text(bill.title)
                                .font(AppTypography.title2)
                                .foregroundColor(AppColors.text)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        PartyScoreBadge(sponsor: bill.sponsor)
                    }
                }
                .padding(AppLayout.cardPadding)
                .background(AppColors.cardBackground)
                .cornerRadius(AppLayout.largeRadius)
                .cardShadow()
                .padding(.horizontal, AppLayout.screenPadding)
                
                // Summary Card
                BillDetailCard(
                    title: "Summary",
                    icon: "doc.text",
                    iconColor: AppColors.primary
                ) {
                    Text(bill.summary)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.text)
                        .lineSpacing(2)
                }
                
                // Full Text Card
                BillDetailCard(
                    title: "Full Text",
                    icon: "text.justify",
                    iconColor: AppColors.secondary
                ) {
                    PrimaryButton(title: "Read Full Text", size: .medium) {
                        isShowingFullTextSheet = true
                    }
                }
                
                // Sponsor Card
                BillDetailCard(
                    title: "Sponsor",
                    icon: "person.crop.square",
                    iconColor: AppColors.accent
                ) {
                    NavigationLink(destination: RepInfoView(sponsor: bill.sponsor)) {
                        HStack(spacing: AppLayout.medium) {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [AppColors.accent, AppColors.accent.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading, spacing: AppLayout.xSmall) {
                                Text(bill.sponsor)
                                    .font(AppTypography.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppColors.text)
                                Text("View Details")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.primary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.tertiaryText)
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                // Timeline Card
                BillDetailCard(
                    title: "Timeline",
                    icon: "calendar",
                    iconColor: AppColors.info
                ) {
                    HStack {
                        VStack(alignment: .leading, spacing: AppLayout.xSmall) {
                            Text("Introduced")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                            Text(bill.dateIntroduced ?? defaultIntroducedDate(for: bill.id), style: .date)
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.text)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: AppLayout.xSmall) {
                            Text("Last Updated")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                            Text(bill.lastUpdated ?? defaultLastUpdatedDate(for: bill.id), style: .date)
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.text)
                        }
                    }
                }
                
                // Votes Map Card
                BillDetailCard(
                    title: "Votes",
                    icon: "map",
                    iconColor: AppColors.secondary
                ) {
                    VStack(spacing: AppLayout.medium) {
                        VoteMapView(
                            votes: votes,
                            region: MKCoordinateRegion(
                                center: .init(latitude: 39.8283, longitude: -98.5795),
                                span: .init(latitudeDelta: 35, longitudeDelta: 50)
                            )
                        )
                        .frame(height: 300)
                        .cornerRadius(AppLayout.cornerRadius)
                        
                        VoteRatioBar(votes: votes)
                    }
                }

                // Actions Card
                BillDetailCard(
                    title: "Actions",
                    icon: "bolt.fill",
                    iconColor: AppColors.warning
                ) {
                    VStack(spacing: AppLayout.medium) {
                        HStack(spacing: AppLayout.medium) {
                            // Like button
                            IconButton(
                                icon: bill.isLiked ? "hand.thumbsup.fill" : "hand.thumbsup",
                                style: .secondary
                            ) {
                                onLike()
                            }

                            // Dislike button
                            IconButton(
                                icon: bill.isDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown",
                                style: .secondary
                            ) {
                                onDislike()
                            }

                            // Subscribe button
                            IconButton(
                                icon: bill.isSubscribed ? "bell.fill" : "bell",
                                style: .secondary
                            ) {
                                onSubscribe()
                            }

                            // Share button
                            ShareLink(item: URL(string: "https://www.congress.gov/bill/\(bill.id)")!) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppColors.primary)
                                    .frame(width: 36, height: 36)
                                    .background(AppColors.cardBackground)
                                    .cornerRadius(AppLayout.smallRadius)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppLayout.smallRadius)
                                            .stroke(AppColors.primary.opacity(0.2), lineWidth: 1)
                                    )
                            }
                        }
                        
                        VStack(spacing: AppLayout.small) {
                            PrimaryButton(title: "Email Your Representative", size: .medium) {
                                if MFMailComposeViewController.canSendMail() {
                                    isShowingMailComposer = true
                                }
                            }
                            
                            SecondaryButton(title: "View on Congress.gov", size: .medium) {
                                if let url = URL(string: "https://www.congress.gov/bill/\(bill.id)") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.bottom, AppLayout.xxLarge)
        }
        .background(AppColors.groupedBackground)
        .navigationTitle("Bill Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            HistoryService.shared.record(bill)
            Task {
                do {
                    let polys = try VoteDataLoader.loadStatePolygons()
                    votes = VoteDataLoader.makeFakeVotes(polygons: polys)
                } catch {
                    print("❌ Error loading vote data:", error)
                }
            }
        }
        .sheet(isPresented: $isShowingMailComposer) {
            MailComposeView(
                result: $mailResult,
                recipient: extractEmail(from: bill.sponsor),
                subject: "Regarding \(bill.title) (ID: \(bill.id))",
                messageBody: createEmailTemplate(for: bill)
            )
        }
        .sheet(isPresented: $isShowingFullTextSheet) {
            
            //FULL TEXT SHEET BEGINS HERE
            
            NavigationView {
              ScrollView {
                // 2️⃣ Replace your old Text(...) here:
                if let text = fetchedFullText {
                  Text(text)
                } else if let err = fetchError {
                  Text("Error: \(err.localizedDescription)")
                } else {
                  ProgressView("Loading…")
                    .task { await loadFullText() }
                }
              }
              .font(AppTypography.body)
              .padding()
              .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                  Button("Done") {
                    isShowingFullTextSheet = false
                    fetchedFullText = nil               //TODO: done button verify
                    fetchError = nil
                  }
                }
              }

            }
            
            
            
        }
    }
    

    
    // Helper function to extract email from sponsor string (in a real app, this would come from an API)
    private func extractEmail(from sponsor: String) -> String {
        // This is a placeholder - in a real app, you'd have the actual email
        let name = sponsor.components(separatedBy: " ").first ?? ""
        return "\(name.lowercased())@congress.gov"
    }
    
    // Create email template
    private func createEmailTemplate(for bill: Bill) -> String {
        """
        Dear \(bill.sponsor),
        
        I am writing to express my opinion regarding \(bill.title) (Bill ID: \(bill.id)).
        
        [Your message here]
        
        Thank you for your consideration.
        
        Sincerely,
        [Your Name]
        """
    }
    
    
    
    private func loadFullText() async {
        // ── 1️⃣ Unwrap your optional path components ────────────────────────────────
        guard
            let rawCongress = bill.congress,
            let rawType     = bill.billType,
            let rawNumber   = bill.billNumber
        else {
            fetchError = URLError(.badURL)
            return
        }

        // ── 2️⃣ Normalize (remove “.0”, lowercase, strip non-digits) ───────────────
        let congressString: String = {
            if let dbl = Double(rawCongress) {
                return String(Int(dbl))    // “119.0” → 119 → “119”
            }
            return rawCongress
        }()
        let typeString   = rawType.lowercased()     // “S” → “s”
        let numberString = rawNumber.filter(\.isNumber)  // “S-2029” → “2029”

        // ── 3️⃣ Percent-encode each (now all plain Strings) ───────────────────────
        guard
            let congress = congressString.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
            let type      = typeString.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
            let number    = numberString.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
        else {
            fetchError = URLError(.badURL)
            return
        }

        // ── 4️⃣ Build a JSON-returning URL ──────────────────────────────────────────
        var comps = URLComponents()
        comps.scheme = "https"
        comps.host   = "api.congress.gov"
        comps.path   = "/v3/bill/\(congress)/\(type)/\(number)/text"
        comps.queryItems = [
          .init(name: "api_key", value: "spOBoHz8WKRnSkk5414FkRx6unyXc9ZVp3UePnPD"),
          .init(name: "format",  value: "json")
        ]
        guard let url = comps.url else {
            fetchError = URLError(.badURL)
            return
        }

        do {
            // ── 5️⃣ Fetch & enforce JSON ─────────────────────────────────────────────
            var req = URLRequest(url: url)
            req.setValue("application/json", forHTTPHeaderField: "Accept")
            let (data, response) = try await URLSession.shared.data(for: req)

            // ── 6️⃣ Check status & log raw JSON ────────────────────────────────────
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                let body = String(data: data, encoding: .utf8) ?? "<non-utf8>"
                print("⚠️ HTTP \(http.statusCode):", body)
                throw URLError(.badServerResponse)
            }
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 JSON:", jsonString)
            }

            // ── 7️⃣ Decode with snake_case + wrapper fallback ────────────────────────
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            let resp: TextVersionsResponse
            if let bare = try? decoder.decode(TextVersionsResponse.self, from: data) {
                resp = bare
            } else {
                struct Wrapper: Codable { let data: TextVersionsResponse }
                let wrapped = try decoder.decode(Wrapper.self, from: data)
                resp = wrapped.data
            }

            // ── 8️⃣ Extract first “Formatted Text” URL & fetch that HTML ─────────────
            guard
                let fmt = resp.textVersions
                            .first(where: { $0.formats.contains { $0.type == "Formatted Text" } })?
                            .formats.first(where: { $0.type == "Formatted Text" })?
                            .url,
                let htmlURL = URL(string: fmt)
            else {
                throw URLError(.fileDoesNotExist)
            }

            let html = try String(contentsOf: htmlURL, encoding: .utf8)
            fetchedFullText = html

        } catch {
            fetchError = error
        }
    }




    // Minimal models (you can keep these private in the same file)
    private struct TextVersionsResponse: Codable {
      let textVersions: [TextVersion]
    }
    private struct TextVersion: Codable {
      let formats: [TextFormat]
    }
    private struct TextFormat: Codable {
      let type: String
      let url:  String
    }
    
    // Helper functions to generate realistic fallback dates
    private func defaultIntroducedDate(for billId: String) -> Date {
        // Generate a pseudo-random but consistent date based on the bill ID
        let hash = abs(billId.hashValue)
        let daysAgo = (hash % 365) + 30 // Between 30-395 days ago
        return Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
    }
    
    private func defaultLastUpdatedDate(for billId: String) -> Date {
        // Last updated should be more recent than introduced
        let introducedDate = defaultIntroducedDate(for: billId)
        let hash = abs(billId.hashValue)
        let daysAfterIntroduced = hash % 60 + 1 // 1-60 days after introduced
        return Calendar.current.date(byAdding: .day, value: daysAfterIntroduced, to: introducedDate) ?? Date()
    }
}




// Mail compose view wrapper for SwiftUI
struct MailComposeView: UIViewControllerRepresentable {
    @Binding var result: Result<MFMailComposeResult, Error>?
    let recipient: String
    let subject: String
    let messageBody: String
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients([recipient])
        composer.setSubject(subject)
        composer.setMessageBody(messageBody, isHTML: false)
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailComposeView
        
        init(_ parent: MailComposeView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            if let error = error {
                parent.result = .failure(error)
            } else {
                parent.result = .success(result)
            }
            controller.dismiss(animated: true)
        }
    }
}

// MARK: - Bill Detail Card Component

struct BillDetailCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content
    
    init(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.medium) {
            HStack(spacing: AppLayout.small) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.text)
                
                Spacer()
            }
            
            content
        }
        .padding(AppLayout.cardPadding)
        .background(AppColors.cardBackground)
        .cornerRadius(AppLayout.largeRadius)
        .cardShadow()
        .padding(.horizontal, AppLayout.screenPadding)
    }
}

#Preview {
    NavigationView {
        BillDetailView(
            bill: Bill(
                id: "HR1234",
                title: "Clean Energy Innovation Act",
                summary: "A bill to promote research and development in clean energy technologies and provide tax incentives for clean energy production.",
                fullText: "The Clean Energy Innovation Act is a bill that aims to promote research and development in clean energy technologies and provide tax incentives for clean energy production.",
                sponsor: "Rep. Jane Smith (D-CA)",
                relevanceScore: 0.8,
                isLiked: true,
                isDisliked: false,
                isSubscribed: true,
                dateIntroduced: Date().addingTimeInterval(-7_776_000), // 90 days ago
                lastUpdated: Date().addingTimeInterval(-864_000) // 10 days ago
            ),
            onLike: {},
            onDislike: {},
            onSubscribe: {}
        )
    }
}
