import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
import Time "mo:base/Time";

actor PredictionMarket {

    type PostId = Nat;
    type UserId = Principal;

    type Post = {
        id: PostId;
        creator: UserId;
        content: Text;
        yesVotes: Nat;
        noVotes: Nat;
        totalStake: Nat;
        createdAt: Time.Time;
        closed: Bool;
    };

    type Bet = {
        user: UserId;
        amount: Nat;
        isYes: Bool;
    };

    private stable var nextPostId : Nat = 0;
    private var posts = HashMap.HashMap<PostId, Post>(10, Nat.equal, Nat.hash);
    private var bets = HashMap.HashMap<PostId, [Bet]>(10, Nat.equal, Nat.hash);

    
    public shared(msg) func createPost(content : Text) : async Result.Result<PostId, Text> {
        let postId = nextPostId;
        nextPostId += 1;

        let newPost : Post = {
            id = postId;
            creator = msg.caller;
            content = content;
            yesVotes = 0;
            noVotes = 0;
            totalStake = 0;
            createdAt = Time.now();
            closed = false;
        };

        posts.put(postId, newPost);
        bets.put(postId, []);

        #ok(postId)
    };

  
    public shared(msg) func placeBet(postId : PostId, amount : Nat, isYes : Bool) : async Result.Result<(), Text> {
        switch (posts.get(postId)) {
            case (null) {
                #err("Post not found")
            };
            case (?post) {
                if (post.closed) {
                    return #err("Post is closed for betting")
                };

                let newBet : Bet = {
                    user = msg.caller;
                    amount = amount;
                    isYes = isYes;
                };

                var postBets = switch (bets.get(postId)) {
                    case (null) { [] };
                    case (?existingBets) { existingBets };
                };

                postBets := Array.append(postBets, [newBet]);
                bets.put(postId, postBets);

                var updatedPost = post;
                updatedPost.totalStake += amount;
                if (isYes) {
                    updatedPost.yesVotes += amount;
                } else {
                    updatedPost.noVotes += amount;
                };

                posts.put(postId, updatedPost);

                #ok()
            };
        }
    };

  
    public query func getPost(postId : PostId) : async Result.Result<Post, Text> {
        switch (posts.get(postId)) {
            case (null) { #err("Post not found") };
            case (?post) { #ok(post) };
        }
    };

    
    public shared(msg) func closePost(postId : PostId) : async Result.Result<(), Text> {
        switch (posts.get(postId)) {
            case (null) { #err("Post not found") };
            case (?post) {
                if (post.creator != msg.caller) {
                    return #err("Only the creator can close the post")
                };
                let closedPost = {
                    post with closed = true
                };
                posts.put(postId, closedPost);
                #ok()
            };
        }
    };
}
