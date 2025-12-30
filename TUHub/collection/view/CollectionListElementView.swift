//
//  CollectionListElement.swift
//  TUHub
//
//  Created by Noah Scardina on 11/18/25.
//

import SwiftUI

/**
 This view is used in the MyCollectionsView and displays one of the collections
 in the list, and also provides the functionality for displaying the posts that are in the
 collection in a sheet.
 */
struct CollectionListElementView: View {
    
    /**
     Whether the PostsInCollectionView sheet is shown or not.
     */
    @State var isPresented = false
    
    /**
     Collection to show in this view.
     */
    var (reference, collection): CollectionReferencePair
    
    var body: some View {
        
        Button {
            isPresented = true
        } label: {
            CollectionView(collection: collection)
        }
        .sheet(isPresented: $isPresented) {
          
            PostsInCollectionView(
                pair: (reference, collection)
            )
                
        }
    }
    
}
