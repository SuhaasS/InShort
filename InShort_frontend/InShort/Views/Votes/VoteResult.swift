import SwiftUI
import MapKit

// --------------------------
// MARK: — MKPolygon + MKMultiPolygon Extensions
// --------------------------

extension MKPolygon {
    /// Pulls out every point of a single polygon
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid,
                                              count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}

extension MKMultiPolygon {
    /// Flattens all sub-polygons into one big array
    var coordinates: [CLLocationCoordinate2D] {
        polygons.flatMap { $0.coordinates }
    }
}

// --------------------------
// MARK: — Your Model
// --------------------------

struct StateVote: Identifiable {
    let id: String
    let yes: Int
    let no: Int
    let polygonCoords: [CLLocationCoordinate2D]

    var majorityYes: Bool { yes >= no }
    var total: Int { yes + no }

    /// simple centroid average
    var centroid: CLLocationCoordinate2D {
        guard !polygonCoords.isEmpty else { return .init() }
        let sums = polygonCoords.reduce((lat: 0.0, lon: 0.0)) {
            (acc, pt) in (acc.lat + pt.latitude, acc.lon + pt.longitude)
        }
        let c = Double(polygonCoords.count)
        return .init(latitude: sums.lat/c, longitude: sums.lon/c)
    }
}

private struct VoteEntry: Decodable {
    let state: String
    let yes: Int
    let no: Int
}

// --------------------------
// MARK: — GeoJSON Loader & Fake Data
// --------------------------

class VoteDataLoader {
    static func loadStatePolygons() throws -> [String:[CLLocationCoordinate2D]] {
        guard let url = Bundle.main.url(forResource: "us_states", withExtension: "geojson") else {
            throw NSError(domain: "VoteResult", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "us_states.geojson not found"])
        }

        let data = try Data(contentsOf: url)
        let features = try MKGeoJSONDecoder()
                         .decode(data)
                         .compactMap { $0 as? MKGeoJSONFeature }
        print("Decoded \(features.count) GeoJSON features")

        var result = [String:[CLLocationCoordinate2D]]()
        for feat in features {
            guard let pdata = feat.properties,
                  let json = try? JSONSerialization
                                    .jsonObject(with: pdata) as? [String:Any]
            else {
                print("❌ Feature without parsable properties")
                continue
            }
            // print("Feature props keys: \(json.keys)")

            // <-- this is the only changed block: pick up "abbr" first
            let abbr: String?
            if let a = json["abbr"]   as? String { abbr = a }
            else if let p = json["postal"] as? String { abbr = p }
            else if let p = json["STUSPS"] as? String { abbr = p }
            else if let p = json["state"]  as? String { abbr = p }
            else if let p = json["STATE"]  as? String { abbr = p }
            else {
                print("⚠️ no abbr found in props: \(json.keys)")
                continue
            }

            // collect all coords (poly + multipoly)
            var allCoords = [CLLocationCoordinate2D]()
            for geom in feat.geometry {
                if let poly  = geom as? MKPolygon      { allCoords += poly.coordinates }
                if let mpoly = geom as? MKMultiPolygon { allCoords += mpoly.coordinates }
            }
            if allCoords.isEmpty {
                print("⚠️ no coords for state \(abbr!)")
                continue
            }

            result[abbr!] = allCoords
        }

        print("✅ Loaded polygons for \(result.count) states.")
        return result
    }

    static func makeFakeVotes(polygons: [String:[CLLocationCoordinate2D]]) -> [StateVote] {
        // your existing code unchanged…
        if
          let url = Bundle.main.url(forResource: "votes", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let entries = try? JSONDecoder().decode([VoteEntry].self, from: data)
        {
          return entries.compactMap { e in
            guard let coords = polygons[e.state] else { return nil }
            return StateVote(id: e.state, yes: e.yes, no: e.no, polygonCoords: coords)
          }
        }

        return polygons.map { (abbr, coords) in
          let y = Int.random(in: 20...200)
          let n = Int.random(in: 20...200)
          return StateVote(id: abbr, yes: y, no: n, polygonCoords: coords)
        }
    }

    static func fetchVotesFromAPI(polygons: [String:[CLLocationCoordinate2D]]) async throws -> [StateVote] {
        // unchanged…
        let url = URL(string: "https://api.yourservice.com/delegation_votes")!
        let (data,_) = try await URLSession.shared.data(from: url)
        struct APIState: Decodable { let state:String; let yes:Int; let no:Int }
        let arr = try JSONDecoder().decode([APIState].self, from: data)
        return arr.compactMap { s in
            guard let coords = polygons[s.state] else { return nil }
            return StateVote(id: s.state, yes: s.yes, no: s.no, polygonCoords: coords)
        }
    }
}

// --------------------------
// MARK: — Annotation + MapView
// --------------------------

class VoteAnnotation: NSObject, MKAnnotation {
    let vote: StateVote
    let diameter: CGFloat
    var coordinate: CLLocationCoordinate2D { vote.centroid }
    init(vote: StateVote, diameter: CGFloat) {
        self.vote = vote; self.diameter = diameter
    }
}

struct VoteMapView: UIViewRepresentable {
    var votes: [StateVote]
    var region: MKCoordinateRegion

    func makeCoordinator() -> Coordinator { .init(self) }
    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView(frame: .zero)
        map.delegate = context.coordinator
        if #available(iOS 13.4, *) { map.mapType = .mutedStandard }
        else                    { map.mapType = .standard }
        if #available(iOS 13.0, *) {
            map.pointOfInterestFilter = .excludingAll
        }
        map.showsCompass = false
        map.showsScale   = false
        map.showsBuildings = false
        map.setRegion(region, animated: false)
        return map
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeAnnotations(mapView.annotations)
        guard !votes.isEmpty else { return }
        let maxTotal = votes.map(\.total).max() ?? 1
        let annos = votes.map { vote -> VoteAnnotation in
            let size = CGFloat(10 + 30 * Double(vote.total) / Double(maxTotal))
            return VoteAnnotation(vote: vote, diameter: size)
        }
        print("🖊️ Adding \(annos.count) annotations")
        mapView.addAnnotations(annos)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: VoteMapView
        init(_ parent: VoteMapView) { self.parent = parent }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation)
             -> MKAnnotationView?
        {
            guard let voteAnno = annotation as? VoteAnnotation else { return nil }
            let id = "voteScatter"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: id)
                     ?? MKAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.annotation = voteAnno
            let d = voteAnno.diameter
            view.bounds = CGRect(x: 0, y: 0, width: d, height: d)
            view.layer.cornerRadius = d/2
            view.clipsToBounds = true
            view.backgroundColor = voteAnno.vote.majorityYes
                ? UIColor(hex: "#82ca9d").withAlphaComponent(0.7)
                : UIColor(hex: "#8884d8").withAlphaComponent(0.7)
            return view
        }
    }
}

// --------------------------
// MARK: — SwiftUI Wrapper
// --------------------------

struct VoteResultMapView: View {
    @State private var votes: [StateVote] = []

    var body: some View {
        VoteMapView(
            votes: votes,
            region: MKCoordinateRegion(
                center: .init(latitude: 39.8283, longitude: -98.5795),
                span:   .init(latitudeDelta: 35, longitudeDelta: 50)
            )
        )
        .ignoresSafeArea()
        .onAppear {
            Task {
                do {
                    let polys  = try VoteDataLoader.loadStatePolygons()
                  #if DEBUG
                    votes      = VoteDataLoader.makeFakeVotes(polygons: polys)
                  #else
                    votes      = try await VoteDataLoader.fetchVotesFromAPI(polygons: polys)
                  #endif
                } catch {
                    print("❌ Error loading votes:", error)
                }
            }
        }
    }
}

extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255
        let g = CGFloat((rgb & 0x00FF00) >> 8)  / 255
        let b = CGFloat(rgb & 0x0000FF) / 255

        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}

struct VoteResultMapView_Previews: PreviewProvider {
    static var previews: some View {
        VoteResultMapView()
    }
}
