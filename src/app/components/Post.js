import React, { useState, useEffect } from "react";
import { ethers } from "ethers";
import { Contract } from "ethers";
import { FaEllipsisH } from "react-icons/fa";
import {
  HiOutlineHeart,
  HiOutlineChatBubbleOvalLeftEllipsis,
  HiOutlineBookmark,
} from "react-icons/hi2";
import { HiOutlineShare } from "react-icons/hi";
import { motion } from "framer-motion";
import axios from "axios"; 
import Swal from "sweetalert2"; 
import abi from './ABI.json';

const Contractaddress = "0x859Bb215897ED323508155c212fe6B30Cc895da4";

const Post = () => {
  const [users, setUsers] = useState([]);
  const [posts, setPosts] = useState([]);
  const ipfsBaseUrl = "https://gateway.pinata.cloud/ipfs/";

  const getUserAndPostData = async () => {
    try {
      const provider = new ethers.JsonRpcProvider("https://base-sepolia.g.alchemy.com/v2/9epB18aWeXPPH4GFsiiQhk8CoM1p-L6B");
      const contract = new Contract(Contractaddress, abi, provider);

      const userRegisteredEvents = await contract.queryFilter("UserRegistered");
      const postCreatedEvents = await contract.queryFilter("PostCreated");

      const userArray = await Promise.all(userRegisteredEvents.map(async (event) => {
        const address = event.args.user;
        try {
          const users = await contract.users(address);
          return {
            address: address,
            username: users[1], 
            profileImage: users[2], 
          };
        } catch (error) {
          console.error("Error fetching user data:", error);
          return {
            address: address,
            username: "Unknown User",
            profileImage: "QmQv9Z6fU5dR6LhjLZ5ZL3o7DQ6ZCZz8vX5oZz1Zy5Z", // Default image CID
          };
        }
      }));

      const postArray = postCreatedEvents.map(event => ({
        owner: event.args.author,
        content: event.args.content,
      }));

      setUsers(userArray);
      setPosts(postArray);
    } catch (error) {
      console.error("Error fetching user and post data:", error);
    }
  };

  useEffect(() => {
    const fetchInitialData = async () => {
      try {
        await getUserAndPostData();
      } catch (error) {
        console.error("Error fetching initial data:", error);
      }
    };

    const onUserRegistered = (user, profileImage) => {
      setUsers((prevUsers) => [
        ...prevUsers,
        {
          address: user,
          username: "New User",
          profileImage,
        },
      ]);
    };

    const onPostCreated = (author, content) => {
      setPosts((prevPosts) => [...prevPosts, { owner: author, content }]);
    };

    const provider = new ethers.JsonRpcProvider("https://base-sepolia.g.alchemy.com/v2/9epB18aWeXPPH4GFsiiQhk8CoM1p-L6B");
    const contract = new Contract(Contractaddress, abi, provider);
    
    contract.on("UserRegistered", onUserRegistered);
    contract.on("PostCreated", onPostCreated);

    fetchInitialData();

    return () => {
      contract.off("UserRegistered", onUserRegistered);
      contract.off("PostCreated", onPostCreated);
    };
  }, []);

  const fetchPostContent = async (cid) => {
    try {
      const response = await axios.get(`${ipfsBaseUrl}${cid}`);
      return response.data;
    } catch (error) {
      console.error("Error fetching post content:", error);
      return "Content could not be fetched";
    }
  };

  const likePost = async (id) => {
    Swal.fire({
      title: 'Like Post',
      text: "Would you like to watch an ad to proceed or pay the transaction fee?",
      icon: 'question',
      showCancelButton: true,
      confirmButtonText: 'Watch Ad',
      cancelButtonText: 'Pay Transaction Fee',
      confirmButtonColor: '#3085d6',
      cancelButtonColor: '#d33',
    }).then(async (result) => {
      if (result.isConfirmed) {
        Swal.fire('Ad Watched', 'Thank you for watching the ad. Post liked!', 'success');
      } else {
        try {
          const provider = new ethers.BrowserProvider(window.ethereum);
          const signer = await provider.getSigner();
          const contract = new Contract(Contractaddress, abi, signer);
          const like = await contract.likePost(id);
          Swal.fire('Transaction Successful', 'You have successfully liked the post.', 'success');
          console.log("Post liked:", like);
        } catch (error) {
          Swal.fire('Error', 'Transaction failed. Please try again.', 'error');
          console.error("Transaction error:", error);
        }
      }
    });
  };

  const commentPost = async (id) => {
    const { value: comment } = await Swal.fire({
      title: 'Add a Comment',
      input: 'text',
      inputPlaceholder: 'Type your comment here...',
      showCancelButton: true,
      confirmButtonText: 'Submit',
      cancelButtonText: 'Cancel',
      customClass: {
        confirmButton: 'swal2-confirm-custom',
        cancelButton: 'swal2-cancel-custom',
      },
    });
  
    if (comment) {
      try {
        const provider = new ethers.BrowserProvider(window.ethereum);
        const signer = await provider.getSigner();
        const contract = new Contract(Contractaddress, abi, signer);
        const response = await contract.addComment(id, comment);
        console.log("Comment added:", response);
        Swal.fire('Success', 'Your comment has been added.', 'success');
      } catch (error) {
        Swal.fire('Error', 'Failed to add comment. Please try again.', 'error');
      }
    }
  };
  
  const sharePost = async (id) => {
    const { value: shareOption } = await Swal.fire({
      title: 'Share Post',
      text: 'How would you like to share this post?',
      input: 'select',
      inputOptions: {
        'Facebook': 'Share on Facebook',
        'Twitter': 'Share on Twitter',
        'LinkedIn': 'Share on LinkedIn',
      },
      inputPlaceholder: 'Select an option',
      showCancelButton: true,
      confirmButtonText: 'Share',
      cancelButtonText: 'Cancel',
      customClass: {
        confirmButton: 'swal2-confirm-custom',
        cancelButton: 'swal2-cancel-custom',
      },
    });
  
    if (shareOption) {
      try {
        const provider = new ethers.BrowserProvider(window.ethereum);
        const signer = await provider.getSigner();
        const contract = new Contract(Contractaddress, abi, signer);
        const response = await contract.sharePost(id);
        console.log("Post shared:", response);
        Swal.fire('Success', 'Your post has been shared.', 'success');
      } catch (error) {
        Swal.fire('Error', 'Failed to share post. Please try again.', 'error');
      }
    }
  };
  

  if (!users.length || !posts.length) return <div>Loading...</div>;

  return (
    <>
      {posts.map((post, idx) => {
        const user = users.find(user => user.address.toLowerCase() === post.owner.toLowerCase());
        return (
          <div key={idx} className="postWrapper">
            <div className="header">
              <div className="left">
                {user ? (
                  <img
                    src={`${ipfsBaseUrl}${user.profileImage}`}
                    alt="Profile"
                    className="profileImg"
                  />
                ) : (
                  <div className="profileImg placeholder">Unknown User</div>
                )}
                <div className="userDetails">
                  <div className="name">{user ? user.username : "Unknown User"}</div>
                </div>
              </div>
              <div className="right">
                <div className="option">
                  <FaEllipsisH />
                </div>
              </div>
            </div>
            <div className="mainPostContent">
              <motion.div
                className="postContent"
                animate={{ scale: 1 }}
                onClick={async () => {
                  const content = await fetchPostContent(post.content);
                  // Handle displaying post content here
                }}
              >
                <div className="imageContainer" style={{ display: "flex", justifyContent: "center", marginTop: "25px" }}>
                  <img 
                    src={`${ipfsBaseUrl}${post.content}`} 
                    alt="Post Content" 
                    className="postImage" 
                    style={{ width: "75%", height: "50%", objectFit: "contain" }} 
                  />
                </div>
              </motion.div>
            </div>
            <div className="postFooter">
              <div className="postActions">
                <div className="left">
                  <div className="likeBtn" onClick={() => likePost(idx)}>
                    <HiOutlineHeart />
                  </div>
                  <div className="commentBtn" onClick={() => commentPost(idx)}>
                    <HiOutlineChatBubbleOvalLeftEllipsis />
                  </div>
                  <div className="shareBtn" onClick={() => sharePost(idx)}>
                    <HiOutlineShare />
                  </div>
                </div>
                <div className="right">
                  <div className="saveBtn">
                    <HiOutlineBookmark />
                  </div>
                </div>
              </div>
            </div>
          </div>
        );
      })}
    </>
  );
};

export default Post;
