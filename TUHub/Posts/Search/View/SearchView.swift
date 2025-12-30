//
//  SearchView.swift
//  TUHub
//
//  Created by Rell on 12/5/25.
//

import SwiftUI
import FirebaseFirestore

struct SearchView: View {
    @State private var searchText: String = ""
    @State private var debounceWorkItem: DispatchWorkItem?
    @StateObject private var searchViewModel = SearchViewModel()
    @StateObject private var collectionViewModel = CollectionViewModel()
    
    var body: some View {
        VStack {
            NavigationStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: searchText) { newValue in
                            
                            debounceWorkItem?.cancel()
                            let workItem = DispatchWorkItem {
                                searchViewModel.search(newValue)
                            }
                            debounceWorkItem = workItem
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: workItem)
                        }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top)
                
                List(searchViewModel.searchResults) { post in
                    NavigationLink {
                        PostExpanded(
                            collectionViewModel: collectionViewModel,
                            pair: (reference: Firestore.firestore().collection("posts").document(post.id),
                                   post: post)
                        )
                    } label: {
                        PostView(post: post)
                    }
                }
            }
            .navigationTitle("Search")
        }
    }
}
