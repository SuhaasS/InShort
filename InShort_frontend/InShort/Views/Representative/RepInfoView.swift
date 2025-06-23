import SwiftUI
import MapKit

struct RepInfoView: View {
    let sponsor: String
    
    // Dummy data for demonstration
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 38.8977, longitude: -77.0365),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    var body: some View {
        VStack(spacing: 16) {
            Text(sponsor)
                .font(.title2).fontWeight(.bold)
            
            Text("Party: \(sponsor.contains("(D") ? "Democrat" : "Republican")")
            Text("District: 1st District") // placeholder
            
            Map(coordinateRegion: $region)
                .frame(height: 200)
                .cornerRadius(12)
            
            Button("Visit Official Site") {
                // open a placeholder URL
                if let url = URL(string: "https://\(sponsor.components(separatedBy: " ").first?.lowercased() ?? "www").house.gov") {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Representative")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RepInfoView_Previews: PreviewProvider {
    static var previews: some View {
        RepInfoView(sponsor: "Rep. Jane Smith (D-CA)")
    }
}
