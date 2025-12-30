//
//  SaveToCollectionView.swift
//  TUHub
//
//  Created by Noah Scardina on 11/15/25.
//

import SwiftUI

/**
 View that allows the user to save a post to any of their collections that they haven't
 already added the post to (or to create a new one to add the post to).
 */
struct SaveToCollectionView: View {
    
    @EnvironmentObject private var collectionsViewModel: CollectionViewModel
    @Environment(\.dismiss) private var dismiss
    
    var postPair: PostReferencePair
    
    /**
     Whether to show the New Collection view (if the user decides to create a new collection
     rather than adding the post to one of their existing collections)
     */
    @State private var newCollectionViewShown = false
    
    var body: some View {
        
        NavigationStack {
            VStack {
                HStack {
                    Text("Save to Collection")
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Label("", systemImage: "xmark")
                    }
                }
                
                // display all the collections that this post is not
                // already added to
                if let collections = collectionsViewModel
                    .collectionsNotContainingPost(postPair.reference)
                {
                    List(collections, id: \.reference) { pair in
                        Button {
                            // save the post to the selected collection
                            Task.init {
                                await collectionsViewModel.addPostToCollection(collectionPair: pair, postPair: postPair, username: CurrentUserStore.email?.lowercased() ?? "")
                            }
                        } label: {
                            CollectionView(collection: pair.collection)
                        }
                    }
                } else {
                    Text("You do not have any collections.")
                        .padding(.top)
                    Spacer()
                }
                
                Button("Create New...") {
                    newCollectionViewShown = true
                }
                // https://developer.apple.com/documentation/swiftui/view/navigationdestination(ispresented:destination:)
                    .navigationDestination(isPresented: $newCollectionViewShown) {
                    NewCollectionView()
                }
                
                
                
            }
        }
        .padding()
    }
    
}
