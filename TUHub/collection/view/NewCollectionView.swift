//
//  NewCollectionView.swift
//  TUHub
//
//  Created by Rell on 12/6/25.
//

import SwiftUI
import FirebaseFirestore

/**
 View that is used to create a new collection. The user enters the name of the collection and
 whether it is a group or private collection.
 */
struct NewCollectionView: View {
    
    @EnvironmentObject private var collectionViewModel: CollectionViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Name of the collection entered by the user.
    @State private var collectionName: String = ""
    
    // Whether the collection is a group collection or not.
    @State private var isGroup: Bool = false
    
    // The email addresses of other users entered if this collection is
    // a group collection.
    @State private var inviteText: String = ""
    
    // Set to true while the collection is currently saving in Firebase.
    @State private var isSaving = false
    
    /**
     This method has validation logic for the input fields on this view. It will only
     allow the "Create Collection" button at the bottom to be tapped if a
     name has been entered for the field, and if the group option is selected, it will only allow
     the button to be tapped if at least one other user has been added to the group.
     It also does not allow the button to be clicked if the collection is currently being saved.
     */
    private var canCreateCollection: Bool {
        // Collection name is a required field
        guard !collectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        
        // If the group option is selected, then at least one other user must be added to the group
        if isGroup {
            let invited = inviteText
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            return !invited.isEmpty && !isSaving
        }
        
        return !isSaving
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            
            TextField("Collection Name", text: $collectionName)
                .textFieldStyle(.roundedBorder)
                .padding(.bottom, 12)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Collection Type:")
                    .font(.subheadline)
                
                HStack {
                    RadioButton(isSelected: !isGroup) {
                        isGroup = false
                    }
                    Text("Individual")
                    
                    Spacer()
                    
                    RadioButton(isSelected: isGroup) {
                        isGroup = true
                    }
                    Text("Group")
                }
            }
            .padding(.bottom, 12)
            
            if isGroup {
                TextField("Invite by email... (comma separated)", text: $inviteText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.bottom, 12)
            }
            
            Spacer()
            
            Button {
                // If this is a group collection, get all of the emails entered in the
                // "Invite by email..." field, and split on commas
                var members: [String] = if (isGroup) {
                    inviteText
                        .split(separator: ",")
                        .map { name in name.trimmingCharacters(in: .whitespaces)}
                        
                } else {
                    []
                }
                // always include the current user in the list of users, whether it's
                // an individual or group collection
                members.append(CurrentUserStore.email?.lowercased() ?? "")
                
                Task {
                    await collectionViewModel.createCollection(
                        collectionName: collectionName,
                        members: members,
                        posts: [] // initially no posts in the collection
                    )
                }
                
                dismiss()
                                                        
            } label: {
                Text(isSaving ? "Creating..." : "Create Collection")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canCreateCollection ? Color(hex: "#FFBB00") : Color.gray.opacity(0.4))
                    .foregroundColor(.black)
                    .cornerRadius(12)
            }
            .disabled(!canCreateCollection)
        }
        .padding()
        .navigationTitle("New Collection")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
    }
}

/**
 Radio button used for the group/individual collection selector.
 */
struct RadioButton: View {
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .stroke(lineWidth: 2)
                .frame(width: 22, height: 22)
                .overlay(
                    Circle()
                        .fill(isSelected ? Color.blue : Color.clear)
                        .frame(width: 12, height: 12)
                )
        }
        .buttonStyle(.plain)
    }
}
