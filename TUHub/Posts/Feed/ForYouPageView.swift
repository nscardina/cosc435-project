import SwiftUICore
import SwiftUI
import uuid
struct ForYouPage: View{
    let vm = PostViewModel()
    
    var body: some View {
        Text("View1").onAppear {
            Task{
//                await vm.fetchData()
                await vm.seedSamplePosts()
            }
        }
    }
}

#Preview {
    ForYouPage()
}
