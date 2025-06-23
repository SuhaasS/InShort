import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NewsTabView()
                .tabItem {
                    Label("News", systemImage: "newspaper")
                }
                .tag(0)
            
            ChatTabView()
                .tabItem {
                    Label("Chat", systemImage: "message")
                }
                .tag(1)
            
            ProfileTabView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(2)

            HistoryTabView()
                .tabItem {
                    Label("History", systemImage: "clock")
                }
                .tag(3)

//            CompareTabView()
//                .tabItem {
//                    Label("Compare", systemImage: "doc.on.doc")
//                }
//                .tag(4)
//
//            VoteResultMapView()
//                .tabItem {
//                    Label("Votes", systemImage: "map")
//                }
//                .tag(5)
        }
        .accentColor(AppColors.accent)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MainTabView()
                .environment(\.colorScheme, .light)
            MainTabView()
                .environment(\.colorScheme, .dark)
        }
    }
}
