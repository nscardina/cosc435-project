//
//  MyCollectionsView.swift
//  TUHub
//
//  Created by Noah Scardina on 11/2/25.
//

import SwiftUI
import FirebaseFirestore

/**
 This view is the "My Collections" view, where the user can see a list of
 all the views that they have access to.
 */
struct MyCollectionsView: View {
    
    @EnvironmentObject private var collectionViewModel: CollectionViewModel
    @EnvironmentObject private var postsViewModel: PostViewModel
    
    /**
     Whether to show the "Create New Collection" view or not.
     */
    @State private var newCollectionViewShown = false
    
    var body: some View {
        NavigationStack {
            VStack {
                // If the user has any collections loaded from Firebase, display them
                if let collections = collectionViewModel.collections {
                    
                    HStack {
                        
                        Image("TUHubLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 40)
                        
                        Text("My Collections")
                            .bold()
                        
                    }
                    
                    // Code for deleting items from the list obtained from:
                    // https://www.hackingwithswift.com/quick-start/swiftui/how-to-let-users-delete-rows-from-a-list
                    // which is linked in Assignment 2.
                    List {
                        ForEach(collections, id: \.reference) { pair in
                            CollectionListElementView(
                                reference: pair.reference,
                                collection: pair.collection
                            )
                        }
                        // When the collection is deleted by the user, delete it from Firebase
                        .onDelete(perform: collectionViewModel.deleteCollection(
                            username: CurrentUserStore.email?.lowercased() ?? "",
                            postsViewModel: postsViewModel
                        ))
                    }
                    
                } else {
                    // If the user doesn't have any collections loaded from Firebase,
                    // display this text
                    Text("You do not have any collections.")
                        .padding(.top)
                }
                
                // This is the button that opens the New Collection view.
                HStack {
                    Spacer()
                    
                    // https://developer.apple.com/documentation/swiftui/navigationstack
                    Button {
                        newCollectionViewShown = true
                    } label: {
                        Text("Create New...")
                            .bold()
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color(hex: "#FFBB00"))
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                    .padding()
                    // https://developer.apple.com/documentation/swiftui/view/navigationdestination(ispresented:destination:)
                    .navigationDestination(isPresented: $newCollectionViewShown) {
                        NewCollectionView()
                    }
                    
                }
                
                
                Spacer()
            }.onAppear {
                
                // Get the collection data from Firebase whenever this view appears.
                Task.init {
                    if let email = CurrentUserStore.email?.lowercased() {
                        await collectionViewModel.loadAllCollections(email)
                    }
                }
            }
            
        }
    }
}
