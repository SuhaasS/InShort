import Foundation
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading = false
    @Published var selectedBill: Bill?
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Add a welcome message
        messages.append(ChatMessage(
            content: "Hello! I'm your InShort assistant. I can help you understand U.S. bills and legislation. Is there a specific bill you'd like to discuss?",
            isUser: false
        ))
    }
    
    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(content: inputText, isUser: true)
        messages.append(userMessage)
        
        let userQuestion = inputText
        inputText = ""
        
        isLoading = true
        error = nil
        
        Task {
            do {
                let response = try await LLMChatService.shared.ask(bill: selectedBill, question: userQuestion)
                
                await MainActor.run {
                    self.messages.append(response)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                    
                    // Add an error message
                    self.messages.append(ChatMessage(
                        content: "I'm sorry, I encountered an error while processing your question. Please try again.",
                        isUser: false
                    ))
                }
            }
        }
    }
    
    func selectBill(_ bill: Bill?) {
        selectedBill = bill
        
        if let bill = bill {
            messages.append(ChatMessage(
                content: "You've selected \"\(bill.title)\". What would you like to know about this bill?",
                isUser: false
            ))
        }
    }
    
    func clearChat() {
        messages = [ChatMessage(
            content: "Hello! I'm your InShort assistant. I can help you understand U.S. bills and legislation. Is there a specific bill you'd like to discuss?",
            isUser: false
        )]
        selectedBill = nil
    }
}