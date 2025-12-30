import SwiftUI

struct PostExpanded: View {
    
    @ObservedObject var collectionViewModel: CollectionViewModel
    
    let pair: PostReferencePair
    @State private var showingCommentSheet = false
    @State private var newCommentText = ""
    @State private var createdEventAlertIsPresented = false
    @State private var saveToCollectionViewIsPresented = false
    @EnvironmentObject var postvm: PostViewModel
    @State private var followChecked: Bool = false
    @State private var comments: [Comment] = []
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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                let post = pair.post
                
                HStack(alignment: .center, spacing: 8) {
                    Image(systemName: icons[abs(post.clubName.hashValue % icons.count)])
                        .font(.system(size:55))
                        .foregroundColor(colors[abs(post.clubName.hashValue % colors.count)])
                        .padding(.top)
                        .padding(.trailing,5)
                    Text(post.clubName)
                        .font(.subheadline)
                    
                    Spacer()
                    let isFollowing = postvm.clubFollowList.contains(post.clubName)
                    if(isFollowing){
                        
                        Button(action:{
                            postvm.removeUserClubs(userID: CurrentUserStore.email ?? "", clubName: post.clubName)
                            self.followChecked.toggle()
                            let _  = print(followChecked)
                        }){
                            Text(isFollowing ? "Following" : "Follow")
                                .font(.headline)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 8)
                                .background(Color(red: 60, green: 60, blue: 60))
                                .foregroundColor(.black)
                                .cornerRadius(10)
                        }
                    }
                    if(!isFollowing){
                        Button(action:{
                            postvm.addUserClubs(userID: CurrentUserStore.email ?? "", clubName: post.clubName)
                            self.followChecked.toggle()
                            let _  = print(followChecked)
                        }){
                            Text(isFollowing ? "Following" : "Follow")
                                .font(.headline)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 8)
                                .background(Color(.gray))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
                
                HStack( spacing: 4) {
                    
                    Text(post.title)
                        .font(.title)
                        .bold()
                    
                }
                
                AsyncImage(url: URL(string: post.imageURL)) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(8)
                } placeholder: {
                    ProgressView()
                }
                
                Text(post.datePosted, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(post.description)
                    .font(.body)
                
                //For tags
                if !post.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .bold()
                        HStack {
                            ForEach(post.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                HStack(spacing: 16) {
                    Button {
                        postvm.updateLike(userID: post.id)
                    } label: {
                        Image(systemName: "hand.thumbsup")
                    }
                    
                    Button {
                        // add to update dislike count

                        postvm.updateDislike(userID: post.id)

                    } label: {
                        Image(systemName: "hand.thumbsdown")
                    }
                    
                    Spacer()
                    
                    Button("Save to Collection") {
                        //save collection logic will go here
                        saveToCollectionViewIsPresented = true
                    }
                    .sheet(isPresented: $saveToCollectionViewIsPresented) {
                        SaveToCollectionView(postPair: pair)
                    }
                    
                    Button {
                        let calendarManager = CalendarManager()
                        Task.init {
                            
                            /**
                             This code to call the calendarManager functions
                             was generated by ChatGPT with the prompts
                             "I want to create a new event in a user's calendar with EventKit in my SwiftUI app. How can I do this where I set the data in the event with values from in my code?"
                             and
                             "I am getting the error "XPC connection was invalidated". How can I fix this?"
                             */
                            Task { @MainActor in
                                try? await calendarManager.requestAccessIfNeeded()
                                try? calendarManager.addEvent(title: post.title, whenEventIs: post.datePosted)
                                createdEventAlertIsPresented = true
                            }
                            
                        }
                    } label: {
                        Image(systemName: "calendar.badge.plus")
                    }
                    .alert(isPresented: $createdEventAlertIsPresented) {
                        Alert(title: Text("Added event to the calendar"))
                    }
                }
                
                Divider()
                
                // for comments
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Comments")
                            .bold()
                        Spacer()
                        Button("Add") {
                            showingCommentSheet = true
                        }
                        .font(.caption)
                    }
                    
                    ForEach(comments.indices, id: \.self) { index in
                        let comment = comments[index]
                        HStack(alignment: .top, spacing: 8) {
                            AsyncImage(url: URL(string: comment.profileURL)){phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.circle")
                                }
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(comment.username)
                                    .font(.subheadline)
                                    .bold()
                                Text(comment.comment)
                                    .font(.subheadline)
                            }
                        }
                        if index != comments.indices.last {
                            Divider()
                        }
                    }
                }
            }
            .padding()
        }
        .task {//get the inital comments
            comments = pair.post.comments
            do {
                let freshComments = try await postvm.fetchComments(post: pair.post)
                comments = freshComments
            } catch {
                print("Failed to fetch comments: \(error)")
            }
        }
        .navigationTitle("Post")
        .sheet(isPresented:$showingCommentSheet){
            NewCommentSheetView(
                currentPost: pair.post,
                isPresented:$showingCommentSheet
            ) { newComment in
                comments.append(newComment)
            }
        }
    }
}
