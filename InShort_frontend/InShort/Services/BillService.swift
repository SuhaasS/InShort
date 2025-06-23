import Foundation
import Combine

class BillService {
    static let shared = BillService()
private let jsonDecoder: JSONDecoder = {
  let d = JSONDecoder()
  let fmt = DateFormatter()
  fmt.dateFormat = "yyyy-MM-dd"
  // try the simple date format first, then fall back to full ISO if you want:
  d.dateDecodingStrategy = .custom { decoder in
    let container = try decoder.singleValueContainer()
    let dateString = try container.decode(String.self)
    if let date = fmt.date(from: dateString) {
      return date
    }
    // fallback to ISO8601
    if let iso = ISO8601DateFormatter().date(from: dateString) {
      return iso
    }
    throw DecodingError.dataCorruptedError(
      in: container,
      debugDescription: "Cannot decode date string \(dateString)"
    )
  }
  return d
}()

    private init() {}

    // MARK: - Bill Fetching

    func fetchBills() async throws -> [Bill] {
        // Use DEBUG_USE_FAKE_DATA to control data source, not USE_LOCAL_OPERATIONS
        if DEBUG_USE_FAKE_DATA {
            do {
                // First try cache
                let cached = try loadBillsFromCache()
                if !cached.isEmpty {
                    return cached
                }

                // Then try fixture
                return try await loadBillsFromFixture()
            } catch {
                print("Error fetching bills locally: \(error.localizedDescription)")
                throw error
            }
        } else {
            do {
                let bills: [Bill]
                if DEBUG_USE_FAKE_DATA {
                    bills = try await loadBillsFromFixture()
                } else {
                    // Build the URLRequest
                    var request = URLRequest(url: BILLS_API_URL)
                    request.httpMethod = "GET"
                    // Perform request
                    let (data, response) = try await URLSession.shared.data(for: request)

                    // Inspect status and body
                    guard let http = response as? HTTPURLResponse else {
                        throw URLError(.badServerResponse)
                    }
                    print("🚀 GET \(request.url?.absoluteString ?? "") → \(http.statusCode)")
                    print("📥 Body:", String(data: data, encoding: .utf8) ?? "<empty>")

                    // Only accept 200 OK
                    guard http.statusCode == 200 else {
                        throw URLError(.badServerResponse)
                    }

                    // Decode
                    bills = try jsonDecoder.decode([Bill].self, from: data)
                }

                // Cache & return
                cacheBills(bills)
                return bills
            } catch {
                print("Error fetching bills: \(error.localizedDescription)")
                return try loadBillsFromCache()
            }
        }
    }

    func fetchBillDetails(id: String) async throws -> Bill {
        // If DEBUG_USE_FAKE_DATA is enabled, try to find the bill locally first
        if DEBUG_USE_FAKE_DATA {
            do {
                // First try cache
                let cached = try loadBillsFromCache()
                if let bill = cached.first(where: { $0.id == id }) {
                    return bill
                }

                // Then try fixture
                let fixture = try await loadBillsFromFixture()
                if let bill = fixture.first(where: { $0.id == id }) {
                    return bill
                }

                // If we still can't find it, throw a specific error
                throw NSError(domain: "BillService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Bill not found in cache or fixture data"])
            } catch {
                print("Error fetching bill details locally: \(error.localizedDescription)")
                throw error
            }
        } else {
            do {
                // Build URL
                let encodedId = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
                let url = URL(string: "\(BILL_DETAILS_API_URL.absoluteString)\(encodedId)")!

                // Perform request
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                let (data, response) = try await URLSession.shared.data(for: request)

                // Inspect status and body
                guard let http = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                print("🚀 GET \(url) → \(http.statusCode)")
                print("📥 Body:", String(data: data, encoding: .utf8) ?? "<empty>")

                // Only accept 200 OK
                guard http.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }

                // Decode
                return try jsonDecoder.decode(Bill.self, from: data)

            } catch {
                // FALLBACK: try cache, fixture, etc.
                print("Error fetching bill details: \(error.localizedDescription)")
                let cached = try loadBillsFromCache()
                if let bill = cached.first(where: { $0.id == id }) {
                    return bill
                }
                let fixture = try await loadBillsFromFixture()
                if let bill = fixture.first(where: { $0.id == id }) {
                    return bill
                }
                throw error
            }
        }
    }


    // MARK: - Bill Recommendations
    func fetchRecommendedBills(for userProfile: UserProfile) async throws -> [Bill] {
        // Use DEBUG_USE_FAKE_DATA to control data source, not USE_LOCAL_OPERATIONS
        if DEBUG_USE_FAKE_DATA {
            do {
                // Get all bills from cache or fixture
                let allBills = try loadBillsFromCache().isEmpty ? 
                    try await loadBillsFromFixture() : 
                    try loadBillsFromCache()

                // Filter bills based on user interests
                if userProfile.interests.isEmpty {
                    // If no interests, return most recent bills
                    return Array(allBills.prefix(5))
                } else {
                    // Filter bills that match user interests
                    let filteredBills = allBills.filter { bill in
                        userProfile.interests.contains { interest in
                            bill.title.localizedCaseInsensitiveContains(interest) ||
                            bill.summary.localizedCaseInsensitiveContains(interest)
                        }
                    }

                    // If we have enough filtered bills, return them, otherwise return most recent bills
                    return filteredBills.isEmpty ? Array(allBills.prefix(5)) : filteredBills
                }
            } catch {
                print("Error fetching recommended bills locally: \(error.localizedDescription)")
                throw error
            }
        } else {
            do {
                // 1️⃣ Get a guaranteed URL from Env
                let url = RECOMMENDATIONS_API_URL

                // 2️⃣ Build the request (no `guard let` needed here)
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let requestBody: [String: Any] = [
                    "name": userProfile.name,
                    "age": userProfile.age,
                    "location": userProfile.location,
                    "interests": userProfile.interests,
                    "occupation": userProfile.occupation ?? "citizen"
                ]
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

                // 3️⃣ Perform the call as before
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }

                let recommended = try jsonDecoder.decode([RecommendedBill].self, from: data)
                let bills = recommended.map { r in
                    Bill(
                        id:             r.id,
                        title:          r.title,
                        summary:        r.summary,
                        sponsor:        r.sponsor,
                        relevanceScore: r.score,
                        billNumber:     r.bill_number,
                        billType:       r.bill_type,
                        congress:       String(r.congress),
                        policyArea:     r.policy_area,
                        latestAction:   r.latest_action
                    )
                }

                // Cache the recommended bills
                cacheBills(bills)
                return bills
            } catch {
                // If API call fails, fall back to regular bills filtered by user interests
                print("Error fetching recommended bills: \(error.localizedDescription)")
                let allBills = try await fetchBills()

                // Filter bills based on user interests
                if userProfile.interests.isEmpty {
                    // If no interests, return most recent bills
                    return Array(allBills.prefix(5))
                } else {
                    // Filter bills that match user interests
                    let filteredBills = allBills.filter { bill in
                        userProfile.interests.contains { interest in
                            bill.title.localizedCaseInsensitiveContains(interest) ||
                            bill.summary.localizedCaseInsensitiveContains(interest)
                        }
                    }

                    // If we have enough filtered bills, return them, otherwise return most recent bills
                    return filteredBills.isEmpty ? Array(allBills.prefix(5)) : filteredBills
                }
            }
        }
}


    // MARK: - Bill Actions

      func likeBill(id: String) async throws -> Bill {
    // If USE_LOCAL_OPERATIONS is enabled, perform the operation locally
    if USE_LOCAL_OPERATIONS {
      do {
        // Get bill from cache, if not found then try fixture
        var bills = try loadBillsFromCache()
        if bills.isEmpty {
          bills = try await loadBillsFromFixture()
        }
        
        guard let idx = bills.firstIndex(where: { $0.id == id }) else {
          throw NSError(domain: "BillService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Bill not found"])
        }
        
        // Update the bill
        bills[idx].isLiked = true
        bills[idx].isDisliked = false
        // Save to cache
        cacheBills(bills)
        return bills[idx]
      } catch {
        print("Error performing local like operation: \(error.localizedDescription)")
        throw error
      }
    } else {
      // Original API call implementation
      // 1️⃣ Build URL
      let encodedId = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
      let url = URL(string: "\(BILL_LIKE_API_URL.absoluteString)\(encodedId)")!

      // 2️⃣ Perform request
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      let (data, response) = try await URLSession.shared.data(for: request)

      // 3️⃣ Check status
      guard let http = response as? HTTPURLResponse else {
        throw URLError(.badServerResponse)
      }
      print("🚀 POST \(url) → \(http.statusCode)")
      print("📥 Body:", String(data: data, encoding: .utf8) ?? "<empty>")

      guard (200...204).contains(http.statusCode) else {
        throw URLError(.badServerResponse)
      }

      // 4️⃣ If no content, update cache locally
      if http.statusCode == 204 {
        var bills = try loadBillsFromCache()
        guard let idx = bills.firstIndex(where: { $0.id == id }) else {
          throw URLError(.badServerResponse)
        }
        bills[idx].isLiked = true
        bills[idx].isDisliked = false
        cacheBills(bills)
        return bills[idx]
      }

      // 5️⃣ Otherwise decode the JSON body
      return try jsonDecoder.decode(Bill.self, from: data)
    }
  }

    func dislikeBill(id: String) async throws -> Bill {
        // If USE_LOCAL_OPERATIONS is enabled, perform the operation locally
        if USE_LOCAL_OPERATIONS {
            do {
                // Get bill from cache, if not found then try fixture
                var bills = try loadBillsFromCache()
                if bills.isEmpty {
                    bills = try await loadBillsFromFixture()
                }
                
                guard let idx = bills.firstIndex(where: { $0.id == id }) else {
                    throw NSError(domain: "BillService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Bill not found"])
                }
                
                // Update the bill
                bills[idx].isLiked = false
                bills[idx].isDisliked = true
                // Save to cache
                cacheBills(bills)
                return bills[idx]
            } catch {
                print("Error performing local dislike operation: \(error.localizedDescription)")
                throw error
            }
        } else {
            // Original API call implementation
            let encodedId = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
            let url = URL(string: "\(BILL_DISLIKE_API_URL.absoluteString)\(encodedId)")!

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse else {
              throw URLError(.badServerResponse)
            }
            print("🚀 POST \(url) → \(http.statusCode)")
            print("📥 Body:", String(data: data, encoding: .utf8) ?? "<empty>")

            guard (200...204).contains(http.statusCode) else {
              throw URLError(.badServerResponse)
            }

            if http.statusCode == 204 {
              var bills = try loadBillsFromCache()
              guard let idx = bills.firstIndex(where: { $0.id == id }) else {
                throw URLError(.badServerResponse)
              }
              bills[idx].isLiked = false
              bills[idx].isDisliked = true
              cacheBills(bills)
              return bills[idx]
            }

            return try jsonDecoder.decode(Bill.self, from: data)
        }

  }


    func subscribeToBill(id: String) async throws -> Bill {
        // If USE_LOCAL_OPERATIONS is enabled, perform the operation locally
        if USE_LOCAL_OPERATIONS {
            do {
                // Get bill from cache, if not found then try fixture
                var bills = try loadBillsFromCache()
                if bills.isEmpty {
                    bills = try await loadBillsFromFixture()
                }
                
                guard let idx = bills.firstIndex(where: { $0.id == id }) else {
                    throw NSError(domain: "BillService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Bill not found"])
                }
                
                // Update the bill
                bills[idx].isSubscribed = true
                // Save to cache
                cacheBills(bills)
                return bills[idx]
            } catch {
                print("Error performing local subscribe operation: \(error.localizedDescription)")
                throw error
            }
        } else if DEBUG_USE_FAKE_DATA {
            var bills = try await loadBillsFromFixture()
            guard let index = bills.firstIndex(where: { $0.id == id }) else {
                throw NSError(domain: "BillService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Bill not found"])
            }
            bills[index].isSubscribed = true
            return bills[index]
        } else {
            do {
                // Call the API to subscribe to a bill
                let encodedId = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
                let url = URL(string: "\(BILL_SUBSCRIBE_API_URL.absoluteString)\(encodedId)")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }

                return try jsonDecoder.decode(Bill.self, from: data)
            } catch {
                // If API call fails, update the bill locally
                print("Error subscribing to bill: \(error.localizedDescription)")

                // Try to get the bill from cache or fixture
                var bill: Bill
                do {
                    // First try cache
                    let cachedBills = try loadBillsFromCache()
                    if let cachedBill = cachedBills.first(where: { $0.id == id }) {
                        bill = cachedBill
                    } else {
                        // Then try fixture
                        let fixtureBills = try await loadBillsFromFixture()
                        guard let fixtureBill = fixtureBills.first(where: { $0.id == id }) else {
                            throw error // Rethrow if bill not found
                        }
                        bill = fixtureBill
                    }

                    // Update the bill
                    bill.isSubscribed = true
                    return bill
                } catch {
                    // If we can't find the bill, rethrow the original error
                    throw error
                }
            }
        }
    }

    func unsubscribeFromBill(id: String) async throws -> Bill {
        // If USE_LOCAL_OPERATIONS is enabled, perform the operation locally
        if USE_LOCAL_OPERATIONS {
            do {
                // Get bill from cache, if not found then try fixture
                var bills = try loadBillsFromCache()
                if bills.isEmpty {
                    bills = try await loadBillsFromFixture()
                }
                
                guard let idx = bills.firstIndex(where: { $0.id == id }) else {
                    throw NSError(domain: "BillService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Bill not found"])
                }
                
                // Update the bill
                bills[idx].isSubscribed = false
                // Save to cache
                cacheBills(bills)
                return bills[idx]
            } catch {
                print("Error performing local unsubscribe operation: \(error.localizedDescription)")
                throw error
            }
        } else if DEBUG_USE_FAKE_DATA {
            var bills = try await loadBillsFromFixture()
            guard let index = bills.firstIndex(where: { $0.id == id }) else {
                throw NSError(domain: "BillService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Bill not found"])
            }
            bills[index].isSubscribed = false
            return bills[index]
        } else {
            do {
                // Call the API to unsubscribe from a bill
                let encodedId = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
                let url = URL(string: "\(BILL_UNSUBSCRIBE_API_URL.absoluteString)\(encodedId)")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }

                return try jsonDecoder.decode(Bill.self, from: data)
            } catch {
                // If API call fails, update the bill locally
                print("Error unsubscribing from bill: \(error.localizedDescription)")

                // Try to get the bill from cache or fixture
                var bill: Bill
                do {
                    // First try cache
                    let cachedBills = try loadBillsFromCache()
                    if let cachedBill = cachedBills.first(where: { $0.id == id }) {
                        bill = cachedBill
                    } else {
                        // Then try fixture
                        let fixtureBills = try await loadBillsFromFixture()
                        guard let fixtureBill = fixtureBills.first(where: { $0.id == id }) else {
                            throw error // Rethrow if bill not found
                        }
                        bill = fixtureBill
                    }

                    // Update the bill
                    bill.isSubscribed = false
                    return bill
                } catch {
                    // If we can't find the bill, rethrow the original error
                    throw error
                }
            }
        }
    }

    // MARK: - Offline Caching Helpers

 private func cacheBills(_ bills: [Bill]) {
    do {
      let url = documentsDirectory().appendingPathComponent("bills_cache.json")
      let encoder = JSONEncoder()
      encoder.dateEncodingStrategy = .iso8601
      let data = try encoder.encode(bills)
      try data.write(to: url, options: .atomic)
    } catch let encodingError as EncodingError {
      print("Error encoding bills for cache: \(encodingError)")
      switch encodingError {
      case .invalidValue(let value, let context):
        print("Invalid value: \(value) at path: \(context.codingPath)")
      default:
        print("Unknown encoding error")
      }
    } catch {
      print("Error caching bills: \(error.localizedDescription)")
    }
  }


 private func loadBillsFromCache() throws -> [Bill] {
    let url = documentsDirectory().appendingPathComponent("bills_cache.json")


     // If there's no file, just return an empty array (or whatever your fallback is)
     guard FileManager.default.fileExists(atPath: url.path) else {
         return []
     }


    let data = try Data(contentsOf: url)
    return try jsonDecoder.decode([Bill].self, from: data)
  }

  private func documentsDirectory() -> URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
  }

  // MARK: – Fixture Loader
  private func loadBillsFromFixture() async throws -> [Bill] {
    guard let url = Bundle.main.url(forResource: "bills", withExtension: "json") else {
      fatalError("bills.json not found in bundle")
    }
    let data = try Data(contentsOf: url)
    return try jsonDecoder.decode([Bill].self, from: data)
  }


}
