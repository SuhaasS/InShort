import SwiftUI

struct ChatTabView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var showingBillPicker = false
    @StateObject private var newsViewModel = NewsViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                ChatMessagesView(viewModel: viewModel)

                if let bill = viewModel.selectedBill {
                    SelectedBillView(bill: bill) {
                        viewModel.selectBill(nil)
                    }
                }

                InputAreaView(
                    inputText: $viewModel.inputText,
                    onSend: viewModel.sendMessage,
                    onPickBill: { showingBillPicker = true }
                )
            }
            .background(AppColors.groupedBackground)
            .navigationTitle("Chat with AI")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.clearChat) {
                        Image(systemName: "trash")
                    }
                }
            }
            .sheet(isPresented: $showingBillPicker) {
                BillPickerView(bills: newsViewModel.recommendedBills, onSelect: { bill in
                    viewModel.selectBill(bill)
                    showingBillPicker = false
                })
            }
            .onAppear {
                if newsViewModel.recommendedBills.isEmpty {
                    newsViewModel.loadData()
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {}
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - Subviews

private struct ChatMessagesView: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                LazyVStack(spacing: AppLayout.medium) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }

                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            VStack(spacing: AppLayout.small) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                                Text("Thinking...")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.secondaryText)
                            }
                            .padding(AppLayout.medium)
                            .background(.ultraThinMaterial)
                            .cornerRadius(AppLayout.largeRadius)
                            .cardShadow()
                            Spacer()
                        }
                    }
                }
                .padding(AppLayout.screenPadding)
            }
            .background(AppColors.groupedBackground)
            .onChange(of: viewModel.messages) { _, _ in
                if let lastMessage = viewModel.messages.last {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}

private struct SelectedBillView: View {
    let bill: Bill
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: AppLayout.medium) {
            HStack(spacing: AppLayout.small) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.primary)
                
                VStack(alignment: .leading, spacing: AppLayout.xSmall) {
                    Text("Discussing Bill")
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.tertiaryText)
                        .textCase(.uppercase)
                    
                    Text(bill.title)
                        .font(AppTypography.callout)
                        .foregroundColor(AppColors.text)
                        .lineLimit(1)
                }
            }

            Spacer()

            IconButton(icon: "xmark", style: .ghost) {
                onClear()
            }
        }
        .padding(.horizontal, AppLayout.screenPadding)
        .padding(.vertical, AppLayout.medium)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppColors.primary.opacity(0.2)),
            alignment: .bottom
        )
    }
}

private struct InputAreaView: View {
    @Binding var inputText: String
    let onSend: () -> Void
    let onPickBill: () -> Void

    var body: some View {
        HStack(spacing: AppLayout.medium) {
            IconButton(icon: "doc.text", style: .secondary) {
                onPickBill()
            }

            HStack(spacing: AppLayout.small) {
                TextField("Ask a question...", text: $inputText)
                    .font(AppTypography.body)
                    .textFieldStyle(.plain)
                    .submitLabel(.send)
                    .onSubmit(onSend)
                
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
                                       ? AppColors.tertiaryText 
                                       : AppColors.primary)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, AppLayout.medium)
            .padding(.vertical, AppLayout.medium)
            .background(AppColors.secondaryBackground)
            .cornerRadius(AppLayout.largeRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.largeRadius)
                    .stroke(AppColors.primary.opacity(inputText.isEmpty ? 0 : 0.3), lineWidth: 1)
            )
        }
        .padding(.horizontal, AppLayout.screenPadding)
        .padding(.vertical, AppLayout.medium)
        .background(.ultraThinMaterial)
    }
}

struct MessageBubble: View {
  let message: ChatMessage

  var body: some View {
    HStack {
      if message.isUser { Spacer() }
      content
        .padding(AppLayout.medium)
        .background(
          message.isUser 
            ? LinearGradient(colors: [AppColors.primary, AppColors.primary.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
            : LinearGradient(colors: [AppColors.cardBackground, AppColors.cardBackground], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .foregroundColor(message.isUser ? .white : AppColors.text)
        .cornerRadius(AppLayout.largeRadius)
        .cornerRadius(
          AppLayout.largeRadius,
          corners: message.isUser
            ? [.topLeft, .topRight, .bottomLeft]
            : [.topLeft, .topRight, .bottomRight]
        )
        .frame(maxWidth: 320, alignment: message.isUser ? .trailing : .leading)
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
      if !message.isUser { Spacer() }
    }
  }

  @ViewBuilder
  private var content: some View {
    if #available(iOS 15, *) {
      // Convert newlines to markdown line breaks
      let processedContent = message.content
        .replacingOccurrences(of: "\n", with: "  \n")

      // Parse with FULL Markdown syntax
      let opts = AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)
      if let attributed = try? AttributedString(markdown: processedContent, options: opts) {
        return Text(attributed)
          
      }
    }

    // Fallback for iOS < 15 or parse failure
    return Text(message.content)
  }
}


private extension Text {
  func styled() -> some View {
    self
      .padding(12)
      .background(Color(.systemGray6))
      .foregroundColor(.primary)
      .cornerRadius(16)
      .cornerRadius(
        16,
        corners: [.topLeft, .topRight, .bottomLeft]
      )
      .frame(maxWidth: 280, alignment: .leading)
  }
}



struct BillPickerView: View {
    let bills: [Bill]
    let onSelect: (Bill) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var filteredBills: [Bill] {
        if searchText.isEmpty {
            return bills
        } else {
            return bills.filter { bill in
                bill.title.lowercased().contains(searchText.lowercased()) ||
                (bill.summary).lowercased().contains(searchText.lowercased())
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredBills) { bill in
                    Button(action: {
                        onSelect(bill)
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(bill.title)
                                .font(.headline)
                                .lineLimit(1)

                            Text(bill.summary)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Select a Bill")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search bills")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Extension to apply rounded corners to specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    ChatTabView()
}
