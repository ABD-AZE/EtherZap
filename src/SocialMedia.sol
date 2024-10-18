// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract EnhancedSocialMedia {
    /////errors/////

    error EmptyContent();
    error PostIsRemovedOrDeleted();
    error CommentIsEmpty();

    struct User {
        address userAddress;
        string username;
        string profileCID; // IPFS hash for profile picture and other data.
        bool exists;
    }

    struct Post {
        uint256 id;
        address author;
        string content; // Post content (can be an IPFS hash)
        uint256 timestamp;
        uint256 likeCount;
        uint256 shareCount;
    }

    struct Comment {
        uint256 id;
        uint256 postId;
        address commenter;
        string content; // Comment content (can also be an IPFS hash)
        uint256 timestamp;
    }
    mapping(address => User) public users;
    mapping(uint256 => Post) public posts;
    mapping(uint256 => Comment[]) public postComments; // Map post ID to array of comments
    mapping(address => uint256[]) public userPosts; // Stores user's post IDs
    mapping(address => mapping(uint256 => bool)) public likedPosts; // User's liked posts mapping
    uint256 public postCount;
    uint256 public commentCount;

    event PostCreated(uint256 indexed postId, address indexed author, string content, uint256 timestamp);
    event PostLiked(uint256 indexed postId, uint256 indexed likeCount);
    event PostShared(uint256 indexed postId, uint256 indexed shareCount);
    event CommentAdded(uint256 indexed postId, uint256 indexed commentId, address indexed commenter, string content, uint256 timestamp);
    event UserRegistered(address indexed user, string indexed username);


    modifier PostShouldExist(uint256 postId) {     
     if (postId > postCount){
        revert PostIsRemovedOrDeleted();
     }
     _;
    }

    modifier UserShouldExist(address userAddress) {
        if (!UserExists(userAddress)){
            revert("User does not exist");
        }
        _;
    }

    function registerUser(string memory username, string memory profileCID) public {
        require(!users[msg.sender].exists, "User already registered");
        users[msg.sender] = User(msg.sender, username, profileCID, true);
        emit UserRegistered(msg.sender, username);
    }

    // Function to create a post
    function createPost(string memory content) UserShouldExist(msg.sender) public {
        if (bytes(content).length == 0){
            revert EmptyContent();
        }

        // Create the post
        posts[postCount] = Post(postCount, msg.sender, content, block.timestamp, 0, 0);
        userPosts[msg.sender].push(postCount);
        postCount++;
        
        emit PostCreated(postCount , msg.sender, content, block.timestamp); 
    }

    // Function to get a post
    function getPost(uint256 postId) public view PostShouldExist(postId) returns (Post memory) {
        return posts[postId];
    }

    // Function to like a post
    function likePost(uint256 postId) PostShouldExist(postId) UserShouldExist(msg.sender) public {
      
        require(!likedPosts[msg.sender][postId], "Post already liked");

        // Increment the like count
        posts[postId].likeCount++;
        likedPosts[msg.sender][postId] = true; // Mark the post as liked by the user
        emit PostLiked(postId, posts[postId].likeCount);
    }

    // Function to share a post
    function sharePost(uint256 postId)  PostShouldExist(postId) UserShouldExist(msg.sender) public {
       
        // Increment the share count
        posts[postId].shareCount++;
        emit PostShared(postId, posts[postId].shareCount);
    }

    // Function to add a comment to a post
    function addComment(uint256 postId, string memory content) UserShouldExist(msg.sender) PostShouldExist(postId) public {
        require(bytes(content).length > 0, "Comment cannot be empty");

        // Create the comment
        postComments[postId].push(Comment(commentCount, postId, msg.sender, content, block.timestamp));
        commentCount++;
        emit CommentAdded(postId, commentCount, msg.sender, content, block.timestamp);
    }

    // Function to get comments for a post
    function getComments(uint256 postId) public view PostShouldExist(postId) returns (Comment[] memory) {
        return postComments[postId];
    }

    // Function to get user's posts
    function getUserPosts(address user) public view  UserShouldExist(user) returns (uint256[] memory) {
        return userPosts[user];
    }

    // Function to check if a user liked a post
    function hasLikedPost(uint256 postId) public view UserShouldExist(msg.sender) returns (bool) {
        return likedPosts[msg.sender][postId];
    }

    function getUser(address userAddress) public view returns (User memory) {
      require(users[userAddress].exists, "User does not exist");
      return users[userAddress];
    }

    function UserExists(address userAddress) public view returns (bool) {
        return users[userAddress].exists;
    }


}
