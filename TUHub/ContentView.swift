import SwiftUI

struct ContentView: View {

    // https://developer.apple.com/documentation/swiftui/stateobject
    @StateObject private var sessionViewModel = SessionViewModel()
    @StateObject private var loginViewModel = LoginViewModel()
    @StateObject private var signupViewModel = SignupViewModel()
    
    @StateObject private var collectionViewModel = CollectionViewModel()
    @StateObject private var postViewModel = PostViewModel()

    var body: some View {
        Group {
            if sessionViewModel.isSignedIn {
                // User is logged in - show main app
                MainTabView()
            } else {
                // User is logged out - show auth flow
                AuthView()
            }
        }
        .animation(.easeInOut, value: sessionViewModel.isSignedIn)
        .onAppear {
            
            Task.init {
                if let email = CurrentUserStore.email?.lowercased() {
                    await collectionViewModel.loadAllCollections(email)
                }
                
                await postViewModel.fetchData()
            }
            
            
        }
        
        // https://developer.apple.com/documentation/swiftui/environmentobject
        .environmentObject(sessionViewModel)
        .environmentObject(loginViewModel)
        .environmentObject(signupViewModel)
        .environmentObject(collectionViewModel)
        .environmentObject(postViewModel)
    }
}
