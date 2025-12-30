import Foundation
import FirebaseFirestore

typealias PostReferencePair = (reference: DocumentReference, post: Post)

struct Post:Identifiable,Codable {
    var id: String
    let title: String
    let imageURL: String
    let clubName: String
    let description: String
    let datePosted: Date
    var numLikes: Int
    var numDislikes: Int
    var tags: [String]
    var comments: [Comment]
}
