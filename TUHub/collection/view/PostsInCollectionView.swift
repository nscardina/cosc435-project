//
//  PostsInCollectionView.swift
//  TUHub
//
//  Created by Noah Scardina on 11/15/25.
//

import SwiftUI

/**
 View that shows a list of all the posts in a collection.
 */
struct PostsInCollectionView: View {
    
    /**
     Collection reference pair for the collection whose posts will be shown in this view.
     */
    var pair: CollectionReferencePair
    
    @EnvironmentObject private var collectionViewModel: CollectionViewModel
    @EnvironmentObject private var postsViewModel: PostViewModel
    @Environment(\.dismiss) private var dismiss
    
    
    
    var body: some View {
        NavigationView {
            
            VStack {
                HStack {
                    CollectionView(collection: pair.collection)
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Label("", systemImage: "xmark")
                    }
                }
                .padding(.bottom)
                
                
                if (pair.collection.posts.isEmpty) {
                    Text("There are no posts in this collection.")
                } else {
                    
                    // Code for deleting items from the list obtained from:
                    // https://www.hackingwithswift.com/quick-start/swiftui/how-to-let-users-delete-rows-from-a-list
                    // which is linked in Assignment 2.
                    List {
                        ForEach(pair.collection.posts, id: \.self) { postRef in
                            
                            if let pair = postsViewModel.getPair(postRef) {
                                NavigationLink(destination: PostExpanded(collectionViewModel: collectionViewModel, pair: pair)) {
                                    PostView(post: pair.post)
                                }
                            }
                            
                        }
                        // If a user swipes left to delete the post from the collection,
                        // delete the post from Firestore
                        .onDelete(perform: collectionViewModel.removePostFromCollection(
                            postsViewModel: postsViewModel,
                            collectionPair: pair,
                            username: CurrentUserStore.email?.lowercased() ?? ""
                        ))
                    }
                    
                    
                }
                
                Spacer()
            }
            .padding()
            
        }
        
        
    }
}
