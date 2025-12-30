//
//  CollectionView.swift
//  TUHub
//
//  Created by Noah Scardina on 11/15/25.
//

import SwiftUI

/**
 Displays a collection in the list with the name of the collection and an icon.
 If the collection is private, the icon has one person's head, and if the collection
 is shared with other users, then the icon has three heads.
 */
struct CollectionView: View {
    
    var collection: Collection
    
    var body: some View {
        
        HStack {
            let systemImage = if (collection.members.count == 1) { "person.fill" } else { "person.3.fill" }
            
            Label(collection.name, systemImage: systemImage)

        }
        
    }
    
}
