import Foundation

enum CurrentUserStore {
    private static let emailKey = "currentUserEmail"
    private static let majorKey = "currentUserMajor"
    private static let orgKey   = "currentUserStudentOrganization"

    static var email: String? {
        get {
            UserDefaults.standard.string(forKey: emailKey)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: emailKey)
        }
    }

    static var major: String? {
        get {
            UserDefaults.standard.string(forKey: majorKey)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: majorKey)
        }
    }

    static var studentOrganization: String? {
        get {
            UserDefaults.standard.string(forKey: orgKey)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: orgKey)
        }
    }
}
