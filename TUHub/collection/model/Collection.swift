//
//  Collection.swift
//  TUHub
//
//  Created by Noah Scardina on 11/2/25.
//

import FirebaseFirestore

/**
 Tuple pair that keeps a collection struct together with its Firestore DocumentReference, which
 can be used to edit it in the database or delete it.
 */
typealias CollectionReferencePair = (reference: DocumentReference, collection: Collection)

/**
 Model for collections of posts.
 */
struct Collection: Codable {
    
    /**
     Name of the collection
     */
    var name: String
    
    /**
     Usernames of the users who have access to this collection.
     Will contain 1 username if the collection is a private collection and 1 or
     more usernames if the collection is a group collection.
     */
    var members: [String]
    
    /**
     Posts that have been saved to the collection.
     */
    var posts: [DocumentReference]
    
    /**
     Converts this Collection to a dictionary.
     */
    func toDictionary() -> [String : Any] {
        return [
            "name": name,
            "members": members,
            "posts": posts
        ]
    }
    
}
