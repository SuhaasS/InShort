import Foundation

@MainActor
class CompareViewModel: ObservableObject {
    @Published var bills: [Bill] = []
    @Published var firstBill: Bill?
    @Published var secondBill: Bill?
    @Published var comparisonText: String = ""
    @Published var isLoading = false
    @Published var viewModelError: Error?

    func loadBills() {
        Task {
            do {
                bills = try await BillService.shared.fetchBills()
            } catch {
                self.viewModelError = error
            }
        }
    }

    func selectFirst(_ bill: Bill) {
        firstBill = bill
        updateComparison()
    }

    func selectSecond(_ bill: Bill) {
        secondBill = bill
        updateComparison()
    }

    private func updateComparison() {
        guard let b1 = firstBill, let b2 = secondBill else { return }
        isLoading = true
        comparisonText = ""
        Task {
            do {
                let msg = try await LLMChatService.shared.compare(bills: [b1, b2])
                comparisonText = msg.content
            } catch {
                viewModelError = error
            }
            isLoading = false
        }
    }
}
