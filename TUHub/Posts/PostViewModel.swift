import Foundation
import FirebaseFirestore

@MainActor
class PostViewModel : ObservableObject{
    
    @Published var posts =  [PostReferencePair]()
    private var db = Firestore.firestore()
    @Published var isLoading = false
    @Published var clubFollowList: [String] = []
    
    func getPair(_ reference: DocumentReference) -> PostReferencePair? {
        
        return posts.first { post in post.reference.path == reference.path }
    }
    
    //Fetches posts from "posts" collection
    func fetchData() async{
        isLoading = true
        do{
            let querySnapshot = try await db.collection("posts").getDocuments()
            var newPosts = [PostReferencePair]()
            for document in querySnapshot.documents {
                if let post = try? document.data(as: Post.self) {
                    newPosts.append((document.reference, post))
                }
            }
            
            await MainActor.run {
                self.posts = newPosts
                isLoading = false
            }
        }catch{
            print("Error fetching documents: \(error)")
        }
    }
    
    
    //To retrive list of clubs from a user.
    func getUserClubs( userID: String) {
        let query = db.collection("users").whereField("email", isEqualTo: userID)
        query.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                return
            }
            
            guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                print("No user found")
                return
            }
            
            let document = documents.first!
            
            if let orgs = document.get("studentOrganization") as? [String] {
                self.clubFollowList = orgs
            } else {
                print("Something went wrong retrieving club array")
            }
        }
        
    }
    
    func addUserClubs(userID: String, clubName: String){
        db.collection("users").whereField("email", isEqualTo: userID).getDocuments { (snapshot, error) in
            guard let document = snapshot?.documents.first else {
                print("No user found with this email")
                return
            }
            
            document.reference.updateData([
                "studentOrganization": FieldValue.arrayUnion([clubName])
            ]) { err in
                if let err = err {
                    print("Error adding club to user list \(err)")
                } else {
                    print("New club added to user list")
                }
            }
            
            self.clubFollowList.append(clubName)
        }
    }
    
    func removeUserClubs(userID: String, clubName: String){
        db.collection("users").whereField("email", isEqualTo: userID).getDocuments { (snapshot, error) in
            guard let document = snapshot?.documents.first else {
                print("No user found with this email")
                return
            }
            
            document.reference.updateData([
                "studentOrganization": FieldValue.arrayRemove([clubName])
            ]) { err in
                if let err = err {
                    print("Error adding club to user list \(err)")
                } else {
                    print("New club added to user list")
                }
            }
            if let index = self.clubFollowList.firstIndex(of: clubName) {
                self.clubFollowList.remove(at: index)
            }
            
        }
    }
    
    func updateLike(userID: String){
        let increment = FieldValue.increment(Int64(1))
        db.collection("posts").whereField("id", isEqualTo: userID).getDocuments { (snapshot, error) in
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                return
            }
            
            let document = documents.first!
            
            document.reference.updateData([
                "numLikes": increment
            ]) { err in
                if let err = err {
                    print("error updating likes for \(userID): \(err)")
                } else {
                    print("\(userID) was liked")
                }
            }
        }
    }
    
    func updateDislike(userID: String){
        let increment = FieldValue.increment(Int64(-1))
        db.collection("posts").whereField("id", isEqualTo: userID).getDocuments { (snapshot, error) in
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                return
            }
            
            let document = documents.first!
            
            document.reference.updateData([
                "numLikes": increment
            ]) { err in
                if let err = err {
                    print("error updating likes for \(userID): \(err)")
                } else {
                    print("\(userID) was liked")
                }
            }
        }
    }
    
    func addComment(comment:String,post:Post){
        db.collection("users").whereField("email", isEqualTo: CurrentUserStore.email).getDocuments { (snapshot, error) in
            
            guard let document = snapshot?.documents.first,
                  let userName = document.get("name") as? String else {
                print("Failed to load username")
                return
            }
            
            let newComment: [String: Any] = [
                "comment": comment,
                "profileURL": "https://picsum.photos/200",
                "username": userName
            ]
            
            self.db.collection("posts").whereField("id",isEqualTo: post.id).getDocuments(){(snapshot, error) in
                
                guard let document = snapshot?.documents.first else {
                    print("No user found with this email")
                    return
                }
                
                document.reference.updateData(["comments": FieldValue.arrayUnion([newComment])]) { err in
                    if let err = err {
                        print("Error adding comment to comment list\(err)")
                    } else {
                        print("New Comment Added")
                    }
                }
            }
        }
    }
    
    //Adds example posts to the databas, the post information was generated using ChatGPT 
    func fetchComments(post: Post) async throws -> [Comment] {
        let snapshot = try await db.collection("posts")
            .whereField("id", isEqualTo: post.id)
            .getDocuments()
        
        guard let document = snapshot.documents.first else {
            print("Error: No post found with ID \(post.id)")
            return []
        }
        let fetchedPost = try document.data(as: Post.self)
        return fetchedPost.comments
    }
    //It added posts to the "posts" collection in our database
    func addPosts(post:Post) async{
        do {
            try await db.collection("posts").document(post.id).setData([
                
                "id": post.id,
                "title": post.title,
                "imageURL": post.imageURL,
                "clubName": post.clubName,
                "description": post.description,
                "datePosted": post.datePosted,
                "numLikes": post.numLikes,
                "numDislikes": post.numDislikes,
                "tags": post.tags,
                "comments": post.comments.map { comment in
                    [
                        "username": comment.username,
                        "profileURL": comment.profileURL,
                        "comment": comment.comment
                    ]
                }
            ])
            print("Document successfully written!")
        } catch {
            print("Error writing document: \(error)")
        }
    }
    
    /**
     This function fills the database with dummy data. The prompt was generated with GPT 5 using the prompt
     "Give me Dummy data based on the following model : <copy paste Post Model>"
     */
      func seedSamplePosts() async {
          let now = Date()
          
          let profileAlex = "https://picsum.photos/seed/profile-alex/200/200"
          let profileJordan = "https://picsum.photos/seed/profile-jordan/200/200"
          let profileSam = "https://picsum.photos/seed/profile-sam/200/200"
          let profileTaylor = "https://picsum.photos/seed/profile-taylor/200/200"
          let profilePriya = "https://picsum.photos/seed/profile-priya/200/200"
          let profileMiguel = "https://picsum.photos/seed/profile-miguel/200/200"
          let profileChen = "https://picsum.photos/seed/profile-chen/200/200"
          let profileLeah = "https://picsum.photos/seed/profile-leah/200/200"
          
          func comments(_ items: [(String, String, String)]) -> [Comment] {
              return items.map { (name, url, text) in
                  Comment(username: name, profileURL: url, comment: text)
              }
          }
          
          let posts: [Post] = [
              Post(
                  id: UUID().uuidString,
                  title: "Intro to Value Investing Workshop",
                  imageURL: "https://picsum.photos/seed/tu-investment-1/800/600",
                  clubName: "Towson University Investment Group",
                  description: "Learn the basics of value investing, financial statements, and how to research companies before you buy.",
                  datePosted: now.addingTimeInterval(-86400 * 5),
                  numLikes: 47,
                  numDislikes: 2,
                  tags: ["Business Administration", "Finance", "Investing"],
                  comments: comments([
                      ("Alex Rivera", profileAlex, "This is perfect for beginners, highly recommend."),
                      ("Priya Shah", profilePriya, "Bringing my roommate who wants to start investing."),
                      ("Miguel Alvarez", profileMiguel, "Will there be example portfolios?")
                  ])
              ),
              Post(
                  id: UUID().uuidString,
                  title: "Live Market Discussion & Pizza Night",
                  imageURL: "https://picsum.photos/seed/tu-investment-2/800/600",
                  clubName: "Towson University Investment Group",
                  description: "Watch the market close together, talk about the day’s big moves, and enjoy free pizza.",
                  datePosted: now.addingTimeInterval(-86400 * 2),
                  numLikes: 39,
                  numDislikes: 1,
                  tags: ["Business Administration", "Trading", "Networking"],
                  comments: comments([
                      ("Jordan Kim", profileJordan, "I love the casual format of these meetups."),
                      ("Sam Lee", profileSam, "Do I need any prior experience to join?"),
                      ("Leah Brown", profileLeah, "Saving the date!")
                  ])
              ),
              Post(
                  id: UUID().uuidString,
                  title: "Startup Idea Brainstorm Session",
                  imageURL: "https://picsum.photos/seed/entre-club-1/800/600",
                  clubName: "Entrepreneurship Club",
                  description: "Bring an idea or just curiosity. We’ll break into groups and help each other refine startup concepts.",
                  datePosted: now.addingTimeInterval(-86400 * 7),
                  numLikes: 54,
                  numDislikes: 3,
                  tags: ["Business Administration", "Startups"],
                  comments: comments([
                      ("Taylor Morris", profileTaylor, "I only have a rough idea, is that okay?"),
                      ("Alex Rivera", profileAlex, "Yes, rough ideas are welcome!"),
                      ("Chen Wu", profileChen, "Love that this is open to all majors.")
                  ])
              ),
              Post(
                  id: UUID().uuidString,
                  title: "Founder Stories: Student Startups Panel",
                  imageURL: "https://picsum.photos/seed/entre-club-2/800/600",
                  clubName: "Entrepreneurship Club",
                  description: "Hear from Towson students who launched real products while still in school.",
                  datePosted: now.addingTimeInterval(-86400 * 4),
                  numLikes: 61,
                  numDislikes: 2,
                  tags: ["Business Administration", "Panel", "Networking"],
                  comments: comments([
                      ("Priya Shah", profilePriya, "I love hearing about real student journeys."),
                      ("Sam Lee", profileSam, "Will this be recorded? I have class at that time.")
                  ])
              ),
              Post(
                  id: UUID().uuidString,
                  title: "Pitch Deck Critique Night",
                  imageURL: "https://picsum.photos/seed/entre-club-3/800/600",
                  clubName: "Entrepreneurship Club",
                  description: "Get feedback on your pitch deck slides before competitions and investor meetings.",
                  datePosted: now.addingTimeInterval(-86400),
                  numLikes: 33,
                  numDislikes: 1,
                  tags: ["Business Administration", "Pitching"],
                  comments: comments([
                      ("Miguel Alvarez", profileMiguel, "Finally a reason to finish my slides."),
                      ("Leah Brown", profileLeah, "Open to solo founders too?")
                  ])
              ),

              Post(
                  id: UUID().uuidString,
                  title: "Careers in Psychology Q&A",
                  imageURL: "https://picsum.photos/seed/psych-club-1/800/600",
                  clubName: "Psychology Club",
                  description: "Curious about clinical, counseling, research, or school psychology? Ask our guest panel anything.",
                  datePosted: now.addingTimeInterval(-86400 * 6),
                  numLikes: 42,
                  numDislikes: 1,
                  tags: ["Psychology", "Careers"],
                  comments: comments([
                      ("Jordan Kim", profileJordan, "I’m pre-clinical and this is exactly what I need."),
                      ("Alex Rivera", profileAlex, "Will they talk about grad school funding?")
                  ])
              ),
              Post(
                  id: UUID().uuidString,
                  title: "Stress & Finals: Coping Skills Workshop",
                  imageURL: "https://picsum.photos/seed/psych-club-2/800/600",
                  clubName: "Psychology Club",
                  description: "Learn simple CBT-based tools for anxiety, focus, and sleep during exam week.",
                  datePosted: now.addingTimeInterval(-86400 * 3),
                  numLikes: 58,
                  numDislikes: 3,
                  tags: ["Psychology", "Wellness"],
                  comments: comments([
                      ("Leah Brown", profileLeah, "We need this every semester."),
                      ("Sam Lee", profileSam, "Is this open to non-psych majors?"),
                      ("Priya Shah", profilePriya, "Sharing with my roommates now.")
                  ])
              ),

              Post(
                  id: UUID().uuidString,
                  title: "Psi Chi Research Poster Night",
                  imageURL: "https://picsum.photos/seed/psichi-1/800/600",
                  clubName: "Psi Chi",
                  description: "Members present their research posters and talk about how they joined a lab.",
                  datePosted: now.addingTimeInterval(-86400 * 8),
                  numLikes: 29,
                  numDislikes: 1,
                  tags: ["Psychology", "Honors", "Research"],
                  comments: comments([
                      ("Chen Wu", profileChen, "Great way to see what labs are doing."),
                      ("Jordan Kim", profileJordan, "Is there a dress code?")
                  ])
              ),

              Post(
                  id: UUID().uuidString,
                  title: "Surviving First Clinical: Tips from Seniors",
                  imageURL: "https://picsum.photos/seed/sna-1/800/600",
                  clubName: "Student Nurses Association",
                  description: "Upperclassmen share their honest advice on clinicals, care plans, and time management.",
                  datePosted: now.addingTimeInterval(-86400 * 9),
                  numLikes: 63,
                  numDislikes: 2,
                  tags: ["Nursing", "Clinical"],
                  comments: comments([
                      ("Taylor Morris", profileTaylor, "Please talk about night-before prep too."),
                      ("Alex Rivera", profileAlex, "Is this recorded for those in evening clinicals?")
                  ])
              ),
              Post(
                  id: UUID().uuidString,
                  title: "Community Health Screening Volunteer Sign-Up",
                  imageURL: "https://picsum.photos/seed/sna-2/800/600",
                  clubName: "Student Nurses Association",
                  description: "Help with blood pressure screenings and health education at a local community event.",
                  datePosted: now.addingTimeInterval(-86400 * 4),
                  numLikes: 37,
                  numDislikes: 1,
                  tags: ["Nursing", "Volunteer"],
                  comments: comments([
                      ("Priya Shah", profilePriya, "Does this count for clinical hours?"),
                      ("Miguel Alvarez", profileMiguel, "Transportation provided?")
                  ])
              ),
 
              Post(
                  id: UUID().uuidString,
                  title: "Sigma Theta Tau Induction Information Session",
                  imageURL: "https://picsum.photos/seed/sigma-theta-1/800/600",
                  clubName: "Sigma Theta Tau",
                  description: "Learn about GPA requirements, application timelines, and leadership opportunities.",
                  datePosted: now.addingTimeInterval(-86400 * 10),
                  numLikes: 24,
                  numDislikes: 1,
                  tags: ["Nursing", "Honors"],
                  comments: comments([
                      ("Leah Brown", profileLeah, "Do transfer credits count toward eligibility?"),
                      ("Sam Lee", profileSam, "Thanks for hosting this before applications open.")
                  ])
              ),

              Post(
                  id: UUID().uuidString,
                  title: "Film Screening: Social Movements & Change",
                  imageURL: "https://picsum.photos/seed/saso-1/800/600",
                  clubName: "Sociology & Anthropology Student Organization",
                  description: "Watch a short documentary on global social movements and discuss it afterward.",
                  datePosted: now.addingTimeInterval(-86400 * 6),
                  numLikes: 22,
                  numDislikes: 1,
                  tags: ["Social Sciences", "Discussion"],
                  comments: comments([
                      ("Jordan Kim", profileJordan, "Will there be a sign-in sheet for majors?"),
                      ("Chen Wu", profileChen, "Excited to hear different perspectives.")
                  ])
              ),

              Post(
                  id: UUID().uuidString,
                  title: "Model UN Practice Committee",
                  imageURL: "https://picsum.photos/seed/mun-1/800/600",
                  clubName: "Model United Nations",
                  description: "Practice parliamentary procedure, speeches, and caucusing before our next conference.",
                  datePosted: now.addingTimeInterval(-86400 * 5),
                  numLikes: 31,
                  numDislikes: 2,
                  tags: ["Social Sciences", "Debate", "International"],
                  comments: comments([
                      ("Taylor Morris", profileTaylor, "Is this beginner-friendly? I’ve never done MUN."),
                      ("Sam Lee", profileSam, "Can we borrow school blazers for conferences?")
                  ])
              ),
              Post(
                  id: UUID().uuidString,
                  title: "Conference Travel Interest Meeting",
                  imageURL: "https://picsum.photos/seed/mun-2/800/600",
                  clubName: "Model United Nations",
                  description: "Learn about our upcoming travel conference, costs, and fundraising options.",
                  datePosted: now.addingTimeInterval(-86400 * 2),
                  numLikes: 27,
                  numDislikes: 1,
                  tags: ["Social Sciences", "Travel"],
                  comments: comments([
                      ("Priya Shah", profilePriya, "Do we need passports for this one?"),
                      ("Miguel Alvarez", profileMiguel, "I’m interested in representing Latin American countries.")
                  ])
              ),

              Post(
                  id: UUID().uuidString,
                  title: "Biology Lab Open House",
                  imageURL: "https://picsum.photos/seed/bio-club-1/800/600",
                  clubName: "Biology Club",
                  description: "Tour teaching and research labs, meet faculty, and learn how to get into a lab.",
                  datePosted: now.addingTimeInterval(-86400 * 7),
                  numLikes: 40,
                  numDislikes: 1,
                  tags: ["Biology", "Research"],
                  comments: comments([
                      ("Alex Rivera", profileAlex, "Do we need to sign up in advance?"),
                      ("Leah Brown", profileLeah, "Are pre-med students welcome too?")
                  ])
              ),
              Post(
                  id: UUID().uuidString,
                  title: "Field Trip to Local Nature Center",
                  imageURL: "https://picsum.photos/seed/bio-club-2/800/600",
                  clubName: "Biology Club",
                  description: "Weekend hike focused on local plant and animal biodiversity.",
                  datePosted: now.addingTimeInterval(-86400 * 3),
                  numLikes: 28,
                  numDislikes: 1,
                  tags: ["Biology", "Outdoors"],
                  comments: comments([
                      ("Sam Lee", profileSam, "Is transportation provided from campus?"),
                      ("Chen Wu", profileChen, "I’ll bring my camera!")
                  ])
              ),

              Post(
                  id: UUID().uuidString,
                  title: "Personal Statement Writing Workshop",
                  imageURL: "https://picsum.photos/seed/premed-1/800/600",
                  clubName: "Pre-Med/Pre-Health Society",
                  description: "Break down what makes a strong personal statement and review real examples.",
                  datePosted: now.addingTimeInterval(-86400 * 8),
                  numLikes: 52,
                  numDislikes: 2,
                  tags: ["Pre-Med", "Applications"],
                  comments: comments([
                      ("Priya Shah", profilePriya, "Can we bring drafts for feedback?"),
                      ("Jordan Kim", profileJordan, "Will you cover DO vs MD prompts too?")
                  ])
              ),
              Post(
                  id: UUID().uuidString,
                  title: "Shadowing & Clinical Experience Panel",
                  imageURL: "https://picsum.photos/seed/premed-2/800/600",
                  clubName: "Pre-Med/Pre-Health Society",
                  description: "Hear how students found scribing, EMT, and hospital volunteering positions.",
                  datePosted: now.addingTimeInterval(-86400 * 4),
                  numLikes: 46,
                  numDislikes: 1,
                  tags: ["Pre-Med", "Clinical"],
                  comments: comments([
                      ("Miguel Alvarez", profileMiguel, "I’m trying to find my first shadowing opportunity."),
                      ("Leah Brown", profileLeah, "Thank you for doing this right before application season.")
                  ])
              ),

              Post(
                  id: UUID().uuidString,
                  title: "Capture the Flag Night",
                  imageURL: "https://picsum.photos/seed/cyber-ctf-1/800/600",
                  clubName: "Cyber Defense Club",
                  description: "Beginner-friendly CTF with web, forensics, and basic reverse engineering challenges.",
                  datePosted: now.addingTimeInterval(-86400 * 6),
                  numLikes: 65,
                  numDislikes: 3,
                  tags: ["Information Technology", "Security", "CTF"],
                  comments: comments([
                      ("Sam Lee", profileSam, "First time doing CTF—hope there’s a walkthrough."),
                      ("Alex Rivera", profileAlex, "Can we work in pairs?")
                  ])
              ),
              Post(
                  id: UUID().uuidString,
                  title: "Intro to Blue Team Tools",
                  imageURL: "https://picsum.photos/seed/cyber-blue-1/800/600",
                  clubName: "Cyber Defense Club",
                  description: "Live demo of SIEM dashboards, alerts, and incident playbooks.",
                  datePosted: now.addingTimeInterval(-86400 * 2),
                  numLikes: 41,
                  numDislikes: 1,
                  tags: ["Information Technology", "Security"],
                  comments: comments([
                      ("Jordan Kim", profileJordan, "I’m more blue team than red, love this."),
                      ("Chen Wu", profileChen, "Will we get practice log data to play with?")
                  ])
              ),

              Post(
                  id: UUID().uuidString,
                  title: "ACM-W Mentorship Kickoff",
                  imageURL: "https://picsum.photos/seed/acmw-1/800/600",
                  clubName: "ACM-W",
                  description: "Kickoff for our mentorship program connecting new students with upperclassmen in computing.",
                  datePosted: now.addingTimeInterval(-86400 * 7),
                  numLikes: 49,
                  numDislikes: 2,
                  tags: ["Computer Science", "Mentorship", "Diversity"],
                  comments: comments([
                      ("Leah Brown", profileLeah, "Can non-CS majors in IT join too?"),
                      ("Priya Shah", profilePriya, "I’d love to be a mentor this year.")
                  ])
              ),

              Post(
                  id: UUID().uuidString,
                  title: "Coding Interview Prep Night",
                  imageURL: "https://picsum.photos/seed/acm-interview-1/800/600",
                  clubName: "Association for Computing Machinery",
                  description: "Practice data structures and algorithms problems in small groups.",
                  datePosted: now.addingTimeInterval(-86400 * 5),
                  numLikes: 70,
                  numDislikes: 4,
                  tags: ["Computer Science", "Interview Prep"],
                  comments: comments([
                      ("Sam Lee", profileSam, "Will you cover Big-O and common patterns?"),
                      ("Miguel Alvarez", profileMiguel, "Perfect timing for internship season.")
                  ])
              ),
              Post(
                  id: UUID().uuidString,
                  title: "Intro to iOS with SwiftUI",
                  imageURL: "https://picsum.photos/seed/acm-ios-1/800/600",
                  clubName: "Association for Computing Machinery",
                  description: "Hands-on intro to Swift and SwiftUI. Bring a Mac if you have one.",
                  datePosted: now.addingTimeInterval(-86400 * 3),
                  numLikes: 55,
                  numDislikes: 2,
                  tags: ["Computer Science", "Swift", "iOS"],
                  comments: comments([
                      ("Alex Rivera", profileAlex, "Do we need Xcode pre-installed?"),
                      ("Jordan Kim", profileJordan, "Can beginners with no app experience join?")
                  ])
              ),

              Post(
                  id: UUID().uuidString,
                  title: "UPE Induction & Lightning Talks",
                  imageURL: "https://picsum.photos/seed/upe-1/800/600",
                  clubName: "Upsilon Pi Epsilon",
                  description: "Celebrate new inductees and hear 5-minute talks about student research projects.",
                  datePosted: now.addingTimeInterval(-86400 * 9),
                  numLikes: 26,
                  numDislikes: 1,
                  tags: ["Computer Science", "Honors", "Research"],
                  comments: comments([
                      ("Chen Wu", profileChen, "Can non-members attend the talks?"),
                      ("Leah Brown", profileLeah, "Excited to cheer on my friends.")
                  ])
              ),

              Post(
                  id: UUID().uuidString,
                  title: "TUTV Open Studio Tour",
                  imageURL: "https://picsum.photos/seed/tutv-1/800/600",
                  clubName: "TUTV",
                  description: "See how student shows are filmed and learn how to get involved on and off camera.",
                  datePosted: now.addingTimeInterval(-86400 * 6),
                  numLikes: 36,
                  numDislikes: 1,
                  tags: ["Digital Communication and Media", "Production"],
                  comments: comments([
                      ("Sam Lee", profileSam, "Do we need prior video experience?"),
                      ("Priya Shah", profilePriya, "I’m mostly interested in editing!")
                  ])
              ),
              Post(
                  id: UUID().uuidString,
                  title: "Casting Call for New Student Hosts",
                  imageURL: "https://picsum.photos/seed/tutv-2/800/600",
                  clubName: "TUTV",
                  description: "Looking for energetic students to host new segments next semester.",
                  datePosted: now.addingTimeInterval(-86400 * 2),
                  numLikes: 29,
                  numDislikes: 1,
                  tags: ["Digital Communication and Media", "Auditions"],
                  comments: comments([
                      ("Jordan Kim", profileJordan, "Are scripts provided or improvised?"),
                      ("Miguel Alvarez", profileMiguel, "I might audition just for fun.")
                  ])
              ),

              Post(
                  id: UUID().uuidString,
                  title: "Towerlight Writer & Photographer Interest Meeting",
                  imageURL: "https://picsum.photos/seed/towerlight-1/800/600",
                  clubName: "The Towerlight",
                  description: "Learn how to pitch stories, take photos, and join Towson’s student newspaper.",
                  datePosted: now.addingTimeInterval(-86400 * 7),
                  numLikes: 43,
                  numDislikes: 2,
                  tags: ["Digital Communication and Media", "Journalism"],
                  comments: comments([
                      ("Alex Rivera", profileAlex, "I’m interested in covering campus events."),
                      ("Leah Brown", profileLeah, "Can commuters contribute too?")
                  ])
              ),
              Post(
                  id: UUID().uuidString,
                  title: "Opinion Section Pitch Night",
                  imageURL: "https://picsum.photos/seed/towerlight-2/800/600",
                  clubName: "The Towerlight",
                  description: "Bring one op-ed idea about campus, local news, or sports and get feedback from editors.",
                  datePosted: now.addingTimeInterval(-86400 * 3),
                  numLikes: 31,
                  numDislikes: 1,
                  tags: ["Digital Communication and Media", "Opinion"],
                  comments: comments([
                      ("Sam Lee", profileSam, "Do we need to submit drafts ahead of time?"),
                      ("Chen Wu", profileChen, "I’ve been wanting to write about parking issues.")
                  ])
              ),

              Post(
                  id: UUID().uuidString,
                  title: "Math Contest Practice Session",
                  imageURL: "https://picsum.photos/seed/math-club-1/800/600",
                  clubName: "Problem Solving & Math Club",
                  description: "Solve contest-style problems together, from algebra to proofs.",
                  datePosted: now.addingTimeInterval(-86400 * 5),
                  numLikes: 23,
                  numDislikes: 1,
                  tags: ["Mathematics", "Problem Solving"],
                  comments: comments([
                      ("Priya Shah", profilePriya, "Are calculators allowed?"),
                      ("Jordan Kim", profileJordan, "I’m more CS than math but this sounds fun.")
                  ])
              ),

              Post(
                  id: UUID().uuidString,
                  title: "Options Trading Simulation Night",
                  imageURL: "https://picsum.photos/seed/options-club-1/800/600",
                  clubName: "Options & Derivatives Club",
                  description: "Use a paper-trading platform to explore calls, puts, and basic strategies.",
                  datePosted: now.addingTimeInterval(-86400 * 4),
                  numLikes: 34,
                  numDislikes: 2,
                  tags: ["Business Administration", "Finance", "Derivatives"],
                  comments: comments([
                      ("Alex Rivera", profileAlex, "Will you cover risk management too?"),
                      ("Miguel Alvarez", profileMiguel, "Been waiting for this topic all semester.")
                  ])
              ),

              Post(
                  id: UUID().uuidString,
                  title: "Live Trading & News Reaction Session",
                  imageURL: "https://picsum.photos/seed/invest-trading-1/800/600",
                  clubName: "Investment & Trading Club",
                  description: "Watch how markets react to breaking news and talk through potential trades.",
                  datePosted: now.addingTimeInterval(-86400 * 3),
                  numLikes: 38,
                  numDislikes: 2,
                  tags: ["Business Administration", "Trading"],
                  comments: comments([
                      ("Sam Lee", profileSam, "Is the focus on stocks or also crypto?"),
                      ("Leah Brown", profileLeah, "This sounds like a great learning experience.")
                  ])
              )
          ]
          
          for post in posts {
              await addPosts(post: post)
          }
      }
}
