// AuthViewModels.swift
import Foundation
import FirebaseAuth
import FirebaseFirestore

final class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var rememberMe: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let auth: AuthServicing

    init(auth: AuthServicing = FirebaseAuthService()) {
        self.auth = auth
    }

    var canSubmit: Bool {
        email.contains("@") && password.count >= 6 && !isLoading
    }

    @MainActor
    func login() async {
        guard canSubmit else { return }
        isLoading = true
        errorMessage = nil
        do {
            try await auth.login(email: email, password: password)

            // Save email locally on successful login
            CurrentUserStore.email = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

final class SignupViewModel: ObservableObject {
    @Published var fullName: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var acceptedTerms: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var major: String = TowsonMajors.undergraduate.first ?? ""
    @Published var org: String = TowsonStudentOrgs.sample.first ?? ""
        
    private let auth: AuthServicing

    init(auth: AuthServicing = FirebaseAuthService()) {
        self.auth = auth
    }

    private var isTowsonEmail: Bool {
        let lower = email.lowercased()
        return lower.hasSuffix("@towson.edu") ||
               lower.hasSuffix("@students.towson.edu")
    }

    var passwordsMatch: Bool { !password.isEmpty && password == confirmPassword }

    var canSubmit: Bool {
        fullName.count >= 2 &&
        email.contains("@") &&
        isTowsonEmail &&
        passwordsMatch &&
        !major.trimmingCharacters(in: .whitespaces).isEmpty &&
        acceptedTerms &&
        !isLoading
    }

    @MainActor
    func signup() async {
        guard canSubmit else {
            if !isTowsonEmail {
                errorMessage = "Please use your Towson email address."
            }
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            // Create auth user
            try await auth.signup(name: fullName, email: email.lowercased(), password: password)

            // If signup succeeded, create/update user profile document in Firestore
            if let user = Auth.auth().currentUser {
                let db = Firestore.firestore()
                let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                try await db.collection("users").document(user.uid).setData([
                    "uid": user.uid,
                    "name": fullName,
                    "email": trimmedEmail,
                    "major": major,
                    "studentOrganization": [org],
                    "createdAt": FieldValue.serverTimestamp()
                ], merge: true)

                // Save locally
                CurrentUserStore.email = trimmedEmail
                CurrentUserStore.major = major
                CurrentUserStore.studentOrganization = org
            }

        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
