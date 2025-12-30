import SwiftUI
import Combine

struct NewCommentSheetView: View {
    
    @EnvironmentObject var postvm: PostViewModel
    @State var currentPost: Post
    @Binding var isPresented: Bool
    @State private var userComment: String = ""
    var commentLimit = 280
    var onCommentAdded: (Comment) -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("New Comment")
                    .font(.headline)
                
                TextEditor(text: $userComment)
                    .frame(minHeight: 100, maxHeight: 150)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3))
                    )
                    .onReceive(Just(userComment)) { _ in limitText(280)
                        }
                
                Text("Character Left: \(commentLimit - userComment.count)")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented.toggle()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        self.postvm.addComment(comment: userComment, post: currentPost)
                        let localComment = Comment(
                                              username: "You",
                                              profileURL: "https://picsum.photos/200",
                                              comment: userComment
                                          )
                                          onCommentAdded(localComment)
                        userComment = ""
                        isPresented.toggle()
                    }
                    .disabled(userComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    func limitText(_ upper: Int) {
        if userComment.count > upper {
            userComment = String(userComment.prefix(upper))
        }
    }
}



