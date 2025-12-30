// AuthService.swift
import Foundation
import FirebaseAuth

// MARK: - Auth Service using Firebase
protocol AuthServicing {
    func login(email: String, password: String) async throws
    func signup(name: String, email: String, password: String) async throws
}

struct FirebaseAuthService: AuthServicing {

    func login(email: String, password: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Auth.auth().signIn(withEmail: email.lowercased(), password: password) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func signup(name: String, email: String, password: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                if let user = result?.user {
                    let changeRequest = user.createProfileChangeRequest()
                    changeRequest.displayName = name
                    changeRequest.commitChanges { commitError in
                        if let commitError = commitError {
                            continuation.resume(throwing: commitError)
                        } else {
                            continuation.resume(returning: ())
                        }
                    }
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
