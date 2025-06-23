import Foundation

struct HistoryRecord: Codable, Identifiable {
    let id = UUID()
    let billId: String
    let viewedAt: Date
}

class HistoryService {
    static let shared = HistoryService()
    private let key = "history_records"
    private init() {}
    
    func record(_ bill: Bill) {
        var all = fetchHistory()
        // Remove any previous entries for this bill to avoid duplicates
        all.removeAll { $0.billId == bill.id }
        // Insert the new record at the front
        all.insert(HistoryRecord(billId: bill.id, viewedAt: Date()), at: 0)
        // Keep only the latest 50 entries
        if all.count > 50 { all = Array(all.prefix(50)) }
        save(all)
    }
    
    func fetchHistory() -> [HistoryRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let saved = try? JSONDecoder().decode([HistoryRecord].self, from: data)
        else {
            return []
        }
        return saved
    }
    
    private func save(_ records: [HistoryRecord]) {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
