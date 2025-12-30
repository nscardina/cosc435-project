import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {

    @State private var errorMessage: String? = nil
    @State private var infoMessage: String? = nil

    // Name editing
    @State private var newName: String = ""
    @State private var isEditingName: Bool = false
    @State private var isUpdatingName: Bool = false

    // Password editing
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isEditingPassword: Bool = false
    @State private var isUpdatingPassword: Bool = false

    // Academic (major / org) editing
    @State private var isEditingAcademic: Bool = false
    @State private var tempMajor: String = ""
    @State private var tempOrganization: String = ""
    @State private var isUpdatingAcademic: Bool = false

    var body: some View {
        let user = Auth.auth().currentUser
        let name = user?.displayName ?? "TUHub Student"
        let email = user?.email ?? CurrentUserStore.email ?? "Not set"
        let major = CurrentUserStore.major ?? "Not set"
        let organization = CurrentUserStore.studentOrganization ?? "Not set"

        ScrollView {
            VStack(spacing: 24) {

                // MARK: - Header
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: [Color(hex: "#FFBB00"), Color(hex: "#CC9900")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 160)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                    )

                    HStack(spacing: 16) {
                        // Avatar with initials
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 72, height: 72)

                            Circle()
                                .fill(Color.white)
                                .frame(width: 64, height: 64)

                            Text(initials(from: name))
                                .font(.title2.bold())
                                .foregroundColor(Color(hex: "#151500"))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(name)
                                .font(.title2.bold())
                                .foregroundColor(.white)

                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(1)
                        }

                        Spacer()
                    }
                    .padding()
                }
                .padding(.horizontal)

                // MARK: - Academic Info (read-only display)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Academic")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    VStack(spacing: 0) {
                        ProfileRow(
                            icon: "graduationcap.fill",
                            title: "Major",
                            value: major
                        )

                        Divider()

                        ProfileRow(
                            icon: "person.3.fill",
                            title: "Student Organization",
                            value: organization
                        )
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
                .padding(.horizontal)

                // MARK: - Account Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Account")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    VStack(spacing: 0) {
                        ProfileRow(
                            icon: "envelope.fill",
                            title: "Email",
                            value: email
                        )

                        Divider()

                        ProfileRow(
                            icon: "lock.fill",
                            title: "Authentication",
                            value: "Firebase Email/Password"
                        )
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
                .padding(.horizontal)

                // MARK: - Profile Settings (Name)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Profile Settings")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Display Name")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text(name)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Button {
                                if !isEditingName {
                                    newName = name == "TUHub Student" ? "" : name
                                }
                                withAnimation {
                                    isEditingName.toggle()
                                    infoMessage = nil
                                    errorMessage = nil
                                }
                            } label: {
                                Text(isEditingName ? "Cancel" : "Edit")
                                    .font(.subheadline.bold())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)

                        if isEditingName {
                            VStack(alignment: .leading, spacing: 8) {
                                TextField("New name", text: $newName)
                                    .textInputAutocapitalization(.words)
                                    .disableAutocorrection(true)
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(.secondarySystemBackground))
                                    )

                                Button {
                                    Task { await updateName() }
                                } label: {
                                    HStack {
                                        if isUpdatingName {
                                            ProgressView()
                                                .progressViewStyle(.circular)
                                        }
                                        Text(isUpdatingName ? "Updating..." : "Save Name")
                                            .bold()
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(hex: "#FFBB00"))
                                    .foregroundColor(.black)
                                    .cornerRadius(12)
                                }
                                .disabled(isUpdatingName || newName.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 12)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
                .padding(.horizontal)

                // MARK: - Academic Settings (Major & Club)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Academic Settings")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Major & Organization")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text("\(major) • \(organization)")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Button {
                                withAnimation {
                                    if !isEditingAcademic {
                                        tempMajor = major == "Not set" ? "" : major
                                        tempOrganization = organization == "Not set" ? "" : organization
                                    }
                                    isEditingAcademic.toggle()
                                    infoMessage = nil
                                    errorMessage = nil
                                }
                            } label: {
                                Text(isEditingAcademic ? "Cancel" : "Edit")
                                    .font(.subheadline.bold())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)

                        if isEditingAcademic {
                            VStack(alignment: .leading, spacing: 12) {

                                // Major picker
                                Text("Major")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Menu {
                                    ForEach(TowsonMajors.undergraduate, id: \.self) { m in
                                        Button(m) {
                                            tempMajor = m
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(tempMajor.isEmpty ? "Select your major" : tempMajor)
                                            .foregroundColor(tempMajor.isEmpty ? .secondary : .primary)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(.secondarySystemBackground))
                                    )
                                }

                                // Organization picker
                                Text("Student Organization")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Menu {
                                    ForEach(TowsonStudentOrgs.sample, id: \.self) { org in
                                        Button(org) {
                                            tempOrganization = org
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(tempOrganization.isEmpty ? "Select your organization" : tempOrganization)
                                            .foregroundColor(tempOrganization.isEmpty ? .secondary : .primary)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(.secondarySystemBackground))
                                    )
                                }

                                Button {
                                    Task { await updateAcademic() }
                                } label: {
                                    HStack {
                                        if isUpdatingAcademic {
                                            ProgressView()
                                                .progressViewStyle(.circular)
                                        }
                                        Text(isUpdatingAcademic ? "Saving..." : "Save Academic Info")
                                            .bold()
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(hex: "#FFBB00"))
                                    .foregroundColor(.black)
                                    .cornerRadius(12)
                                }
                                .disabled(isUpdatingAcademic || tempMajor.isEmpty)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 12)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
                .padding(.horizontal)

                // MARK: - Security (Password)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Security")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Password")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text("••••••••")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }

                            Spacer()

                            Button {
                                withAnimation {
                                    isEditingPassword.toggle()
                                    newPassword = ""
                                    confirmPassword = ""
                                    infoMessage = nil
                                    errorMessage = nil
                                }
                            } label: {
                                Text(isEditingPassword ? "Cancel" : "Edit")
                                    .font(.subheadline.bold())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)

                        if isEditingPassword {
                            VStack(alignment: .leading, spacing: 8) {
                                SecureField("New password (min 6 characters)", text: $newPassword)
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(.secondarySystemBackground))
                                    )

                                SecureField("Confirm new password", text: $confirmPassword)
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(.secondarySystemBackground))
                                    )

                                Button {
                                    Task { await updatePassword() }
                                } label: {
                                    HStack {
                                        if isUpdatingPassword {
                                            ProgressView()
                                                .progressViewStyle(.circular)
                                        }
                                        Text(isUpdatingPassword ? "Updating..." : "Update Password")
                                            .bold()
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                .disabled(
                                    isUpdatingPassword ||
                                    newPassword.isEmpty ||
                                    confirmPassword.isEmpty
                                )
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 12)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
                .padding(.horizontal)

                // MARK: - Sign Out
                Button(role: .destructive) {
                    signOut()
                } label: {
                    Text("Sign Out")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.12))
                        .foregroundColor(.red)
                        .cornerRadius(14)
                }
                .padding(.horizontal)

                // Messages
                if let infoMessage = infoMessage {
                    Text(infoMessage)
                        .font(.footnote)
                        .foregroundColor(.green)
                        .padding(.horizontal)
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                Spacer(minLength: 24)
            }
            .padding(.top, 16)
        }
    }

    // MARK: - Actions

    private func signOut() {
        do {
            try Auth.auth().signOut()
            CurrentUserStore.email = nil
            CurrentUserStore.major = nil
            CurrentUserStore.studentOrganization = nil
            infoMessage = "Signed out successfully."
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            infoMessage = nil
        }
    }

    @MainActor
    private func updateName() async {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "No authenticated user."
            infoMessage = nil
            return
        }

        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isUpdatingName = true
        errorMessage = nil
        infoMessage = nil

        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = trimmed

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            changeRequest.commitChanges { error in
                if let error = error {
                    self.errorMessage = "Failed to update name: \(error.localizedDescription)"
                } else {
                    self.infoMessage = "Name updated successfully."
                    self.newName = ""
                    withAnimation {
                        self.isEditingName = false
                    }

                    // Optional: also update Firestore "users" collection
                    let db = Firestore.firestore()
                    db.collection("users").document(user.uid).setData(
                        ["name": trimmed],
                        merge: true
                    ) { firestoreError in
                        if let firestoreError = firestoreError {
                            print("Firestore name update error: \(firestoreError.localizedDescription)")
                        }
                    }
                }
                self.isUpdatingName = false
                cont.resume()
            }
        }
    }

    @MainActor
    private func updateAcademic() async {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "No authenticated user."
            infoMessage = nil
            return
        }

        guard !tempMajor.isEmpty else {
            errorMessage = "Please select a major."
            infoMessage = nil
            return
        }

        isUpdatingAcademic = true
        errorMessage = nil
        infoMessage = nil

        // Update local store
        CurrentUserStore.major = tempMajor
        CurrentUserStore.studentOrganization = tempOrganization.isEmpty ? nil : tempOrganization

        let db = Firestore.firestore()
        let data: [String: Any] = [
            "major": tempMajor,
            "organization": tempOrganization.isEmpty ? "None / Not listed" : tempOrganization
        ]

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            db.collection("users").document(user.uid).setData(data, merge: true) { error in
                if let error = error {
                    self.errorMessage = "Failed to update academic info: \(error.localizedDescription)"
                } else {
                    self.infoMessage = "Academic info updated successfully."
                    withAnimation {
                        self.isEditingAcademic = false
                    }
                }
                self.isUpdatingAcademic = false
                cont.resume()
            }
        }
    }

    @MainActor
    private func updatePassword() async {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "No authenticated user."
            infoMessage = nil
            return
        }

        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match."
            infoMessage = nil
            return
        }

        guard newPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            infoMessage = nil
            return
        }

        isUpdatingPassword = true
        errorMessage = nil
        infoMessage = nil

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            user.updatePassword(to: newPassword) { error in
                if let error = error {
                    self.errorMessage = "Failed to update password: \(error.localizedDescription)"
                } else {
                    self.infoMessage = "Password updated successfully."
                    self.newPassword = ""
                    self.confirmPassword = ""
                    withAnimation {
                        self.isEditingPassword = false
                    }
                }
                self.isUpdatingPassword = false
                cont.resume()
            }
        }
    }

    private func initials(from name: String) -> String {
        let comps = name.split(separator: " ")
        let first = comps.first?.first.map(String.init) ?? "T"
        let last = comps.dropFirst().first?.first.map(String.init) ?? "U"
        return first + last
    }
}

// MARK: - Reusable Row View

struct ProfileRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(.black)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value.isEmpty ? "Not set" : value)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}
