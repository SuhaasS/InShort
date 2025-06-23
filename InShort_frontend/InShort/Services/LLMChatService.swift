import Foundation
import Combine

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date

    init(id: UUID = UUID(), content: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

class LLMChatService {
    static let shared = LLMChatService()

    private init() {}

    // MARK: - Chat

    func ask(bill: Bill?, question: String) async throws -> ChatMessage {
        if DEBUG_USE_FAKE_DATA {
            // Simulate a delay to make it feel like an AI is responding
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

            let response: String

            if let bill = bill {
                response = generateFakeResponse(for: bill, question: question)
            } else {
                response = generateGenericFakeResponse(for: question)
            }

            return ChatMessage(content: response, isUser: false)
        } else {
            // Construct a prompt that includes bill information if available
            let prompt: String
            if let bill = bill {
                prompt = """
                Bill Information:
                Title: \(bill.title)
                Summary: \(bill.summary)
                Sponsor: \(bill.sponsor)

                User Question: \(question)
                """
            } else {
                prompt = question
            }

            // Call the LLM API
            let response = try await callLLMAPI(with: prompt)
            return ChatMessage(content: response, isUser: false)
        }
    }

    // MARK: - Helper Methods

    private func generateFakeResponse(for bill: Bill, question: String) -> String {
        let lowercaseQuestion = question.lowercased()

        if lowercaseQuestion.contains("what is") || lowercaseQuestion.contains("summary") {
            return "The \(bill.title) is \(bill.summary)"
        } else if lowercaseQuestion.contains("who sponsor") || lowercaseQuestion.contains("who introduced") {
            return "The bill was sponsored by \(bill.sponsor)."
        } else if lowercaseQuestion.contains("when") || lowercaseQuestion.contains("date") {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            if let date = bill.dateIntroduced {
                return "The bill was introduced on \(dateFormatter.string(from: date))."
            } else {
                return "The bill's introduction date is not available."
            }
        } else if lowercaseQuestion.contains("democrat") || lowercaseQuestion.contains("republican") || lowercaseQuestion.contains("party") {
            if let score = bill.relevanceScore {
                let party = score > 0 ? "Democratic" : "Republican"
                let strength = abs(score) > 0.7 ? "strongly" : "somewhat"
                return "This bill is \(strength) aligned with \(party) values, with a relevance score of \(score)."
            } else {
                return "Relevance score is not available for this bill."
            }
        } else {
            return "I don't have specific information about that aspect of the \(bill.title). Would you like to know about its summary, sponsor, or introduction date?"
        }
    }

    private func generateGenericFakeResponse(for question: String) -> String {
        let lowercaseQuestion = question.lowercased()

        if lowercaseQuestion.contains("hello") || lowercaseQuestion.contains("hi") {
            return "Hello! I'm your InShort assistant. I can help you understand U.S. bills and legislation. Is there a specific bill you'd like to discuss?"
        } else if lowercaseQuestion.contains("how are you") {
            return "I'm just a digital assistant, but I'm ready to help you understand legislation! What would you like to know?"
        } else if lowercaseQuestion.contains("what can you do") || lowercaseQuestion.contains("help") {
            return "I can help you understand U.S. bills and legislation. You can ask me about specific bills, their summaries, sponsors, or other details. Just let me know which bill you're interested in!"
        } else if lowercaseQuestion.contains("bill") || lowercaseQuestion.contains("legislation") {
            return "I'd be happy to discuss bills and legislation with you. To provide specific information, I'll need to know which bill you're interested in. You can browse bills in the News tab."
        } else {
            return "I'm designed to help with questions about U.S. legislation and bills. If you have a specific bill in mind, I can provide information about it. Otherwise, you can browse bills in the News tab."
        }
    }


    /// Compare two bills and return an AI-generated summary of their differences.
    func compare(bills: [Bill]) async throws -> ChatMessage {
        if DEBUG_USE_FAKE_DATA {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            let b1 = bills[0], b2 = bills[1]
            let response = generateFakeComparison(bill1: b1, bill2: b2)
            return ChatMessage(content: response, isUser: false)
        } else {
            let prompt = """
            Compare the following two bills and highlight differences in title, sponsor, summary, and full text:

            Bill 1:
            \(bills[0].fullText)

            Bill 2:
            \(bills[1].fullText)
            """
            let aiResponse = try await callLLMAPI(with: prompt)
            return ChatMessage(content: aiResponse, isUser: false)
        }
    }

    private func generateFakeComparison(bill1: Bill, bill2: Bill) -> String {
        """
        Comparison between "\(bill1.title)" and "\(bill2.title)":

        Titles:
        - Bill 1: \(bill1.title)
        - Bill 2: \(bill2.title)

        Sponsors:
        - Bill 1: \(bill1.sponsor)
        - Bill 2: \(bill2.sponsor)

        Summary:
        - Bill 1: \(bill1.summary)
        - Bill 2: \(bill2.summary)

        Full Text Excerpt Differences (first 100 chars):
        - Bill 1: \((bill1.fullText ?? "N/A").prefix(100))
        - Bill 2: \((bill2.fullText ?? "N/A").prefix(100))
        """
    }

    private func callLLMAPI(with prompt: String) async throws -> String {
        do {
            // Create a request to the chat API
            let url = CHAT_API_URL
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            // Create a unique session ID for this conversation
            let sessionId = UUID().uuidString

            // Fetch the user profile
            let userProfile = try await UserService.shared.fetchProfile()

            // Create the request body
            let requestBody: [String: Any] = [
                "user_input": prompt,
                "session_id": sessionId,
                "user_profile": [
                    "name": userProfile.name,
                    "age": userProfile.age,
                    "gender": "unknown",
                    "location": userProfile.location,
                    "interests": userProfile.interests
                ]
            ]

            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

            // Make the API call
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }

            // Parse the response
            guard let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let responseText = responseDict["response"] as? String else {
                throw NSError(
                    domain: "LLMChatService",
                    code: 422,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid response format from LLM API"]
                )
            }

            return responseText
        } catch {
            // If API call fails, log the error and generate a fallback response
            print("Error calling LLM API: \(error.localizedDescription)")

            // Log more detailed error information
            if let urlError = error as? URLError {
                print("URL Error: \(urlError.code.rawValue) - \(urlError.localizedDescription)")
                print("URL: \(urlError.failingURL?.absoluteString ?? "unknown")")
            } else if let httpResponse = error as? HTTPURLResponse {
                print("HTTP Error: \(httpResponse.statusCode)")
                print("Response: \(httpResponse.description)")
            } else {
                print("Unknown error type: \(type(of: error))")
                print("Error details: \(error)")
            }

            // Extract the question from the prompt
            let question: String
            if prompt.contains("User Question:") {
                // This is from the ask() method with a bill
                if let range = prompt.range(of: "User Question:") {
                    question = String(prompt[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                } else {
                    question = prompt
                }
            } else if prompt.contains("Compare the following two bills") {
                // This is from the compare() method
                return "I'm sorry, but I couldn't compare these bills at the moment. Please try again later."
            } else {
                // This is a direct question
                question = prompt
            }

            // Generate a fallback response
            return "I apologize, but I'm having trouble connecting to my knowledge base right now. " +
                   "Here's what I can tell you based on general information:\n\n" +
                   "Your question was about: \"\(question)\"\n\n" +
                   "For specific details about bills and legislation, please try again later when the connection is restored."
        }
    }
}
