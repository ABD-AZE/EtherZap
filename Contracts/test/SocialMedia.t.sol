// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "../src/SocialMedia.sol"; // Adjust the import path according to your structure

contract EnhancedSocialMediaTest is Test {
    EnhancedSocialMedia socialMedia;
    address user1;
    address user2;

    function setUp() public {
        socialMedia = new EnhancedSocialMedia();
        user1 = address(0x1);
        user2 = address(0x2);
    }

    function testUserRegistration() public {
        vm.startPrank(user1); // Simulate user1's actions
        socialMedia.registerUser("user1", "QmHash1");
        EnhancedSocialMedia.User memory user = socialMedia.getUser(user1);
        assertEq(user.username, "user1");
        assertEq(user.profileCID, "QmHash1");
        assertTrue(user.exists);
        vm.stopPrank();
    }

    function testDuplicateUserRegistration() public {
        vm.startPrank(user1);
        socialMedia.registerUser("user1", "QmHash1");
        
        vm.expectRevert("User already registered");
        socialMedia.registerUser("user1", "QmHash1");
        vm.stopPrank();
    }

    function testCreatePost() public {
        vm.startPrank(user1);
        socialMedia.registerUser("user1", "QmHash1");
        socialMedia.createPost("This is a post");
        EnhancedSocialMedia.Post memory post = socialMedia.getPost(0);
        assertEq(post.content, "This is a post");
        assertEq(post.author, user1);
        assertEq(post.likeCount, 0);
        assertEq(post.shareCount, 0);
        vm.stopPrank();
    }

    function testCreateEmptyPost() public {
        vm.startPrank(user1);
        socialMedia.registerUser("user1", "QmHash1");

        vm.expectRevert(EnhancedSocialMedia.EmptyContent.selector);
        socialMedia.createPost("");
        vm.stopPrank();
    }

    function testLikePost() public {
        vm.startPrank(user1);
        socialMedia.registerUser("user1", "QmHash1");
        socialMedia.createPost("This is a post");
        vm.stopPrank();

        vm.startPrank(user2);
        socialMedia.registerUser("user2", "QmHash2");
        socialMedia.likePost(0);
        EnhancedSocialMedia.Post memory post = socialMedia.getPost(0);
        assertEq(post.likeCount, 1);
        vm.stopPrank();
    }

    function testLikeSamePostTwice() public {
        vm.startPrank(user1);
        socialMedia.registerUser("user1", "QmHash1");
        socialMedia.createPost("This is a post");
        vm.stopPrank();

        vm.startPrank(user2);
        socialMedia.registerUser("user2", "QmHash2");
        socialMedia.likePost(0);

        vm.expectRevert("Post already liked");
        socialMedia.likePost(0);
        vm.stopPrank();
    }

    function testSharePost() public {
        vm.startPrank(user1);
        socialMedia.registerUser("user1", "QmHash1");
        socialMedia.createPost("This is a post");
        vm.stopPrank();

        vm.startPrank(user2);
        socialMedia.registerUser("user2", "QmHash2");
        socialMedia.sharePost(0);
        EnhancedSocialMedia.Post memory post = socialMedia.getPost(0);
        assertEq(post.shareCount, 1);
        vm.stopPrank();
    }

    function testAddComment() public {
        vm.startPrank(user1);
        socialMedia.registerUser("user1", "QmHash1");
        socialMedia.createPost("This is a post");
        vm.stopPrank();

        vm.startPrank(user2);
        socialMedia.registerUser("user2", "QmHash2");
        socialMedia.addComment(0, "This is a comment");

        EnhancedSocialMedia.Comment[] memory comments = socialMedia.getComments(0);
        assertEq(comments.length, 1);
        assertEq(comments[0].content, "This is a comment");
        assertEq(comments[0].commenter, user2);
        vm.stopPrank();
    }

    function testAddEmptyComment() public {
        vm.startPrank(user2);
        socialMedia.registerUser("user2", "QmHash2");

        vm.expectRevert("Comment cannot be empty");
        socialMedia.addComment(0, "");
        vm.stopPrank();
    }
}
