import Foundation
import FirebaseAuth

final class SessionViewModel: ObservableObject {
    @Published var isSignedIn: Bool = Auth.auth().currentUser != nil
    @Published var email: String? = Auth.auth().currentUser?.email

    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        handle = Auth.auth().addStateDidChangeListener { _, user in
            DispatchQueue.main.async {
                self.isSignedIn = (user != nil)
                self.email = user?.email
            }
        }
    }

    deinit {
        if let handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
