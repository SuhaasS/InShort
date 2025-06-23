import SwiftUI

// A wrapper to pair a history record with its fetched Bill
struct HistoryEntry: Identifiable {
    let record: HistoryRecord
    let bill: Bill?
    var id: UUID { record.id }
}

struct HistoryTabView: View {
    @State private var entries: [HistoryEntry] = []

    var body: some View {
        NavigationStack {
            List(entries) { entry in
                if let bill = entry.bill {
                    NavigationLink(
                        destination: BillDetailView(
                            bill: bill,
                            onLike: { likeBill(bill) },
                            onDislike: { dislikeBill(bill) },
                            onSubscribe: { toggleSubscription(bill) }
                        )
                    ) {
                        VStack(alignment: .leading) {
                            Text(bill.title)
                                .font(.headline)
                            Text(entry.record.viewedAt, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    VStack(alignment: .leading) {
                        Text("Unknown Bill")
                            .font(.headline)
                        Text(entry.record.viewedAt, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Recently Viewed")
            .refreshable {
                await loadEntries()
            }
            .task {
                await loadEntries()
            }
        }
    }

    @MainActor
    private func loadEntries() async {
        let records = HistoryService.shared.fetchHistory()
        var newEntries: [HistoryEntry] = []
        for record in records {
            let bill = try? await BillService.shared.fetchBillDetails(id: record.billId)
            newEntries.append(HistoryEntry(record: record, bill: bill))
        }
        entries = newEntries
    }

    private func likeBill(_ bill: Bill) {
        Task {
            do {
                let updated = try await BillService.shared.likeBill(id: bill.id)
                await MainActor.run {
                    if let idx = entries.firstIndex(where: { $0.bill?.id == bill.id }) {
                        entries[idx].bill?.isLiked = updated.isLiked
                        entries[idx].bill?.isDisliked = updated.isDisliked
                    }
                }
            } catch {
                print("Error liking bill: \(error.localizedDescription)")
            }
        }
    }

    private func dislikeBill(_ bill: Bill) {
        Task {
            do {
                let updated = try await BillService.shared.dislikeBill(id: bill.id)
                await MainActor.run {
                    if let idx = entries.firstIndex(where: { $0.bill?.id == bill.id }) {
                        entries[idx].bill?.isLiked = updated.isLiked
                        entries[idx].bill?.isDisliked = updated.isDisliked
                    }
                }
            } catch {
                print("Error disliking bill: \(error.localizedDescription)")
            }
        }
    }

    private func toggleSubscription(_ bill: Bill) {
        Task {
            do {
                let isCurrentlySubscribed = bill.isSubscribed
                let updated = isCurrentlySubscribed 
                    ? try await BillService.shared.unsubscribeFromBill(id: bill.id)
                    : try await BillService.shared.subscribeToBill(id: bill.id)

                await MainActor.run {
                    if let idx = entries.firstIndex(where: { $0.bill?.id == bill.id }) {
                        entries[idx].bill?.isSubscribed = updated.isSubscribed
                    }
                }
            } catch {
                print("Error toggling subscription: \(error.localizedDescription)")
            }
        }
    }
}

struct HistoryTabView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryTabView()
    }
}
