// AuthComponents.swift
import SwiftUI

struct TUTextField: View {
    let title: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        TextField(title, text: $text)
            .keyboardType(keyboard)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(TUHubAuthTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(TUHubAuthTheme.outline, lineWidth: 1)
            )
    }
}

struct TUSecureField: View {
    let title: String
    @Binding var text: String
    @State private var isSecure: Bool = true

    var body: some View {
        HStack {
            Group {
                if isSecure {
                    SecureField(title, text: $text)
                } else {
                    TextField(title, text: $text)
                }
            }
            Button(action: { isSecure.toggle() }) {
                Image(systemName: isSecure ? "eye.slash" : "eye")
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(TUHubAuthTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(TUHubAuthTheme.outline, lineWidth: 1)
        )
    }
}

struct TUPrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .bold()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(TUHubAuthTheme.primary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct TUErrorText: View {
    let message: String

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.octagon")
            Text(message)
        }
        .font(.callout)
        .foregroundStyle(TUHubAuthTheme.destructive)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(TUHubAuthTheme.destructive.opacity(0.08))
        )
    }
}

struct TUDropdownField: View {
    let title: String
    let placeholder: String
    @Binding var selection: String
    let options: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) {
                        selection = option
                    }
                }
            } label: {
                HStack {
                    Text(selection.isEmpty ? placeholder : selection)
                        .foregroundColor(selection.isEmpty ? .gray : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(TUHubAuthTheme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(TUHubAuthTheme.outline, lineWidth: 1)
                )
            }
        }
    }
}
