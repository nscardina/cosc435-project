import SwiftUI

struct FeedView: View {    
    @EnvironmentObject private var postViewModel: PostViewModel
    @EnvironmentObject private var collectionViewModel: CollectionViewModel

    @State var viewForYou: Bool = false
    @State var viewAll: Bool = true
    var forYouPosts: [PostReferencePair] {
        return postViewModel.posts.filter { post in
            postViewModel.clubFollowList.contains(post.post.clubName)
        }
    }
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                HStack(spacing: 20) {
                    Button(action: {
                        viewForYou = true
                        viewAll = false
                    }) {
                        Text("For You")
                            .font(.system(size: 18, weight: viewForYou ? .bold : .medium))
                            .foregroundColor(viewForYou ? .primary : .gray)
                    }
                    
                    Text("|").foregroundColor(.gray)
                    Button(action: {
                        viewAll = true
                        viewForYou = false
                    }) {
                        Text("All")
                            .font(.system(size: 18, weight: viewAll ? .bold : .medium))
                            .foregroundColor(viewAll ? .primary : .gray)
                    }
                }
                .padding(.top, 10)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.9))
                
                if postViewModel.isLoading {
                    ProgressView("Loading")
                        .frame(maxHeight: .infinity)
                } else {
                    if viewAll {
                        List(postViewModel.posts, id: \.reference.documentID) { postPair in
                            NavigationLink(destination: PostExpanded(collectionViewModel: collectionViewModel, pair: postPair)) {
                                PostView(post: postPair.post)
                            }
                        }
                        .listStyle(PlainListStyle())
                        .padding(.top, 50)
                    }
                    
                    if viewForYou {
                        if forYouPosts.isEmpty {
                            VStack {
                                Spacer()
                                Text("Try Following More Clubs!")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            .padding(.top, 50)
                        }else {
                            List(forYouPosts, id: \.reference.documentID) { postPair in
                                NavigationLink(destination: PostExpanded(collectionViewModel: collectionViewModel, pair: postPair)) {
                                    PostView(post: postPair.post)
                                }
                            }
                            .listStyle(PlainListStyle())
                            .padding(.top, 50)
                        }
                        
                    }
                }
                
              
            }
            .navigationBarHidden(true)
            .task {
                await postViewModel.fetchData()
                postViewModel.getUserClubs(userID: CurrentUserStore.email?.lowercased() ?? "")
            }
        }
    }
}
