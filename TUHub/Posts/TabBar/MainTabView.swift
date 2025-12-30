import SwiftUI
import FirebaseAuth

struct MainTabView: View {
    @State private var selectedTab = 0

    init() {
        UITabBar.tabBarStyling()
    }

    @EnvironmentObject private var collectionViewModel: CollectionViewModel
    @EnvironmentObject private var postViewModel: PostViewModel

    var body: some View {
        TabView {

            // MARK: - Home / Feed
            FeedView()
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                            .environment(\.symbolVariants, selectedTab == 0 ? .fill : .none)
                        Text("Home")
                    }
                }
                .onAppear { selectedTab = 0 }
                .tag(0)

            // MARK: - Search
            SearchView()
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 1 ? "magnifyingglass.circle.fill" : "magnifyingglass")
                            .environment(\.symbolVariants, selectedTab == 1 ? .fill : .none)
                        Text("Search")
                    }
                }
                .onAppear { selectedTab = 1 }
                .tag(1)

            // MARK: - My Collections
            MyCollectionsView()
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 2 ? "bookmark.fill" : "bookmark")
                            .environment(\.symbolVariants, selectedTab == 2 ? .fill : .none)
                        Text("My Collections")
                    }
                }
                .onAppear { selectedTab = 2 }
                .tag(2)

            // MARK: - Profile
            ProfileView()
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 3 ? "person.fill" : "person")
                            .environment(\.symbolVariants, selectedTab == 3 ? .fill : .none)
                        Text("Profile")
                    }
                }
                .onAppear { selectedTab = 3 }
                .tag(3)
        }
        .tint(.black)
    }
}

// MARK: - Tab Bar Styling

extension UITabBar {
    static func tabBarStyling() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color(hex: "#FFBB00"))

        appearance.stackedLayoutAppearance.selected.iconColor = .black
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.black
        ]

        appearance.stackedLayoutAppearance.normal.iconColor = .black
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.black
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    MainTabView()
        .environmentObject(CollectionViewModel())
        .environmentObject(PostViewModel())
}
