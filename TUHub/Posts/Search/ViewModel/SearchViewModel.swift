//
//  SearchViewModel.swift
//  TUHub
//
//  Created by Rell on 12/5/25.
//

import SwiftUI
import FirebaseFirestore

class SearchViewModel: ObservableObject {
    @Published var searchResults: [Post] = []
    private var database = Firestore.firestore()
    
    func search(_ query: String) {
        let lowerQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !lowerQuery.isEmpty else {
            DispatchQueue.main.async {
                self.searchResults = []
            }
            return
        }

        database.collection("posts")
            .getDocuments { snapshot, error in
                
                if let error = error {
                    print("Error searching posts: \(error.localizedDescription)")
                    return
                }
                
                let posts = snapshot?.documents.compactMap { doc -> Post? in
                    var post = try? doc.data(as: Post.self)
                    post?.id = doc.documentID
                    return post
                } ?? []
                
                let filtered = posts.filter { post in
                    post.title.lowercased().contains(lowerQuery) ||
                    post.clubName.lowercased().contains(lowerQuery) ||
                    post.tags.map { $0.lowercased() }.contains(where: { $0.contains(lowerQuery) })
                }
                
                DispatchQueue.main.async {
                    self.searchResults = filtered
                }
            }
    }
}
