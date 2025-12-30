import SwiftUI
struct PostView: View {
    var post: Post
    let colors: [Color] = [.red, .blue, .green, .orange, .purple, .pink, .teal, .mint, .indigo, .yellow]
    let icons: [String] = [
            "person.crop.circle.fill",
            "tortoise.circle.fill",
            "hare.circle.fill",
            "ant.circle.fill",
            "leaf.circle.fill",
            "flame.circle.fill",
            "bolt.circle.fill",
            "pawprint.circle.fill",
            "star.circle.fill",
            "moon.circle.fill"
        ]
    var body: some View {
        HStack(alignment:.top){
            Image(systemName: icons[abs(post.clubName.hashValue % icons.count)])
                .font(.system(size:55))
                .foregroundColor(colors[abs(post.clubName.hashValue % colors.count)])
                .padding(.top)
                .padding(.trailing,5)
            
            VStack(alignment:.leading){
                HStack{
                    Text(post.clubName)
                        .bold()
                        .lineLimit(1)
                    Text("@\(post.clubName)")
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundColor(.gray)
                }
                .padding(.top,5)
                
                Text(post.description)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                HStack{
                    Button(action:{}) {
                        Image(systemName:"message")
                    }
                    Text(post.comments.count > 0 ? "\(post.comments.count)" : "")
                    
                    Spacer()
                    
                    Button(action:{}) {
                        Image(systemName:"heart")
                    }
                    Text(post.numLikes > 0 ? "\(post.numLikes)" : "")
                    
                    Spacer()
                    
                    
                }
            }
            
            
        }
    }
}



