//
//  Untitled.swift
//  TUHub
//
//  Created by Noah Scardina on 11/3/25.
//

import FirebaseFirestore
import SwiftUI

/**
 ViewModel holding the data for the collections that the user has access to.
 */
class CollectionViewModel: ObservableObject {
    
    /**
     List of CollectionReferencePairs for the collections that the user has access to.
     These hold the DocumentReference object for each collection, and the
     Collection struct, in a tuple.
     This is nil until the collections are loaded from Firestore using the
     loadAllCollections function.
     */
    @Published var collections: [CollectionReferencePair]?
    
    /**
     Returns all the loaded collections that do not have a specified post DocumentReference
     in their posts array.
     */
    func collectionsNotContainingPost(_ postRef: DocumentReference) -> [CollectionReferencePair]? {
        self.collections?.filter { collection in
            !collection.collection.posts.contains(postRef)
        }
    }
    
    /**
     Given a DocumentReference to a collection, finds the matching
     CollectionReferencePair in the collections array.
     */
    func getPair(_ reference: DocumentReference) -> CollectionReferencePair? {
        self.collections?.first { pair in pair.reference == reference }
    }
    
    
    
    /**
     Loads all the collections that the user has access to from Firestore.
     */
    func loadAllCollections(_ username: String) async {
        
        do {
            let loadedCollections = try await Firestore
                .firestore()
                .collection("collections")
                .whereField("members", arrayContains: username)
                .getDocuments()
                .documents
                .compactMap { document in
                    do {
                        return try (
                            document.reference,
                            document.data(as: Collection.self)
                        )
                    } catch {
                        return nil
                    }
                }
            
            DispatchQueue.main.sync {
                self.collections = loadedCollections
            }
        } catch {
            print("Error loading collections: \(error.localizedDescription)")
        }
    }
    
    /**
     Creates a new collection, given the collection's name, the usernames of
     the people that will have access to the collection, and the initial array of
     posts that will be in the collection. Also loads all the collections from Firestore
     after doing this to show the new collection in the app.
     */
    func createCollection(
        collectionName: String,
        members: [String],
        posts: [DocumentReference]
    ) async {
        let users = Firestore.firestore()
            .collection("collections")
        
        let collection = Collection(name: collectionName, members: members, posts: posts)
        
        do {
            try users.addDocument(from: collection)
            await loadAllCollections(CurrentUserStore.email?.lowercased() ?? "")
        } catch {
            print("\(error.localizedDescription)")
        }
    }
    
    /**
     Delete a collection from Firestore and reload all the collections from Firestore so that the
     UI shows this.
     This function is based on the code shown here:
     https://www.hackingwithswift.com/quick-start/swiftui/how-to-let-users-delete-rows-from-a-list
     */
    func deleteCollection(
        username: String,
        postsViewModel: PostViewModel
    ) -> (IndexSet) -> Void {
        
        func delete(at offsets: IndexSet) {
            Task.init {
                do {
                    let index = offsets.first ?? 0
                    try await collections?[index].reference.delete()
                } catch {
                    print("\(error.localizedDescription)")
                }
                
                await loadAllCollections(username)
                await postsViewModel.fetchData()
            }
        }
        
        return delete
        
    }
    
    /**
     Adds a post to the specified collection.
     */
    func addPostToCollection(
        collectionPair: CollectionReferencePair,
        postPair: PostReferencePair,
        username: String
    ) async {
        do {
            var collectionDocument = try await Firestore.firestore()
                .document(collectionPair.reference.path)
                .getDocument(as: Collection.self)
            
            // Don't add the post if it's already in the collection
            // This should not never occur, though, because the SaveToCollectionView
            // shouldn't allow the user to try to do that
            if (collectionDocument.posts.contains(postPair.reference)) {
                return
            }
            
            collectionDocument.posts.append(postPair.reference)
            
            try Firestore.firestore()
                .document(collectionPair.reference.path)
                .setData(from: collectionDocument)
                
            
            await loadAllCollections(username)
        } catch {
            print("\(error.localizedDescription)")
        }
        
        
    }
    
    /**
     Remove a post from the specified collection in Firestore and update the UI
     so that this is shown.
     This function is based on the code shown here:
     https://www.hackingwithswift.com/quick-start/swiftui/how-to-let-users-delete-rows-from-a-list
     */
    func removePostFromCollection(
        postsViewModel: PostViewModel,
        collectionPair: CollectionReferencePair,
        username: String
    ) -> (IndexSet) -> Void  {
        
        func delete(at offsets: IndexSet) {
            
            Task.init {
                do {
                    let doc = Firestore.firestore()
                        .document(collectionPair.reference.path)
                    var collection = try await doc.getDocument(as: Collection.self)
                    collection.posts.remove(atOffsets: offsets)
                    
                    try await doc.updateData([
                        "posts": collection.posts
                    ])
                } catch {
                    print("\(error.localizedDescription)")
                }
                
                await loadAllCollections(username)
                await postsViewModel.fetchData()
            }
            
        }
        
        
        return delete
    }
    
}
