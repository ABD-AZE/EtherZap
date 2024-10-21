import React, { useState, useEffect } from "react";
import { ethers, keccak256, getBytes , AbiCoder, Signature} from "ethers";
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
import abi from "./abi.json";
import uabi from  './userManager.json';
import Swal from "sweetalert2"; 

const ContractAddress = "0x523A8ad9A2f7636d0Bc47e63cA1a3E9474D05894";
const ipfsBaseUrl = "https://gateway.pinata.cloud/ipfs/";

const Post = () => {
  const [users, setUsers] = useState([]);
  const [posts, setPosts] = useState([]);
  const [postContent, setPostContent] = useState(null);
  const [open, setOpen] = useState(false);
  const [dataFetched, setDataFetched] = useState(false);
  const [address , setAddress] = useState(null);
  const [adUrl, setAdUrl] = useState("");
  const [isAdPlaying, setIsAdPlaying] = useState(false);





  useEffect(() => {
    const provider = new ethers.JsonRpcProvider(
      "https://base-sepolia.g.alchemy.com/v2/9epB18aWeXPPH4GFsiiQhk8CoM1p-L6B"
    );
    const contract = new Contract(ContractAddress, abi, provider);
    

    const fetchData = async () => {
      if (window.ethereum) {
        // Request account access
        const accounts = await window.ethereum.request({ method: "eth_requestAccounts" });
        const userAddress = accounts[0]; // Get the first account
  
        console.log("User Address:", userAddress); // Log the user address
        setAddress(userAddress);
      }
      try {
        
        const userRegisteredEvents = await contract.queryFilter("UserRegistered");
        const postCreatedEvents = await contract.queryFilter("PostCreated");
        const postLikedEvents = await contract.queryFilter("PostLiked");

        // Initialize a map to count likes for each postId
        const likesCount = {};

        postLikedEvents.forEach((event) => {
          const postId = event.args.postId.toString();
          if (likesCount[postId]) {
            likesCount[postId] += 1; // Increment likes count
          } else {
            likesCount[postId] = 1; // Initialize likes count
          }
        });

        const userArray = await Promise.all(
          userRegisteredEvents.map(async (event) => {
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
                profileImage: "QmQv9Z6fU5dR6LhjLZ5ZL3o7DQ6ZCZz8vX5oZz1Zy5Z",
              };
            }
          })
        );

        const postArray = postCreatedEvents.map((event) => {
          const postId = event.args.postId.toString();
          return {
            owner: event.args.author,
            content: event.args.content,
            postId: postId,
            likes: likesCount[postId] || 0, // Set likes count from likesCount map
          };
        });

        setUsers(userArray);
        setPosts(postArray);
        setDataFetched(true);
      } catch (error) {
        console.error("Error fetching user and post data:", error);
      }
    };

    // Fetch data when the component mounts
    if (!dataFetched) {
      fetchData();
    }

    // Real-time event listeners
    const handleUserRegistered = async (user) => {
      try {
        const userData = await contract.users(user);
        const newUser = {
          address: user,
          username: userData[1],
          profileImage: userData[2],
        };
        setUsers((prevUsers) => [...prevUsers, newUser]);
        console.log("New user registered:", newUser);
      } catch (error) {
        console.error("Error handling new user registration:", error);
      }
    };

    const handlePostCreated = (author, content, postId) => {
      const newPost = {
        owner: author,
        content: content,
        postId: postId.toString(), // Ensure postId is a string
        likes: 0, // Initialize likes to 0
      };
      setPosts((prevPosts) => [...prevPosts, newPost]);
      console.log("New post created:", newPost);
    };

    const handlePostLiked = (postId) => {
      setPosts((prevPosts) =>
        prevPosts.map((post) =>
          post.postId === postId.toString()
            ? { ...post, likes: post.likes + 1 } // Increment likes count
            : post
        )
      );
      console.log(`Post liked with ID: ${postId}`);
    };

    // Subscribe to contract events
    contract.on("UserRegistered", handleUserRegistered);
    contract.on("PostCreated", handlePostCreated);
    contract.on("PostLiked", handlePostLiked);

    // Clean up listeners when the component unmounts
    return () => {
      contract.off("UserRegistered", handleUserRegistered);
      contract.off("PostCreated", handlePostCreated);
      contract.off("PostLiked", handlePostLiked);
    };
  }, [dataFetched]);

  const fetchPostContent = async (cid) => {
    try {
      const response = await axios.get(`${ipfsBaseUrl}${cid}`);
      return response.data;
    } catch (error) {
      console.error("Error fetching post content:", error);
      return "Content could not be fetched";
    }
  };

  function getCurrentTimestamp() {
    // Get the current time in seconds since the Unix epoch
    const timestampInSeconds = Math.floor(Date.now() / 1000);
    
    // Convert to BigNumber if needed (for uint256 representation)
    // Note: `ethers` library is commonly used for handling BigNumbers in Ethereum
    const uint256Timestamp = timestampInSeconds;
    
    return uint256Timestamp;
  }

  async function getUserSignIOpHash(){
    const AF = '0xA3239e7354016c79fa873eB211EDA5Cf214Ca13b';
const EP = '0x0000000071727De22E5E9d8BAf0edAc6f37da032';
const PM = '0xBC5ee9e1888037abF7B595bbD7031d50f586F657';
const SALT = 13579111512;
const MY_ADDRESS = '0x6c2c4C594eE5093494e7a5D9D150bB9046486cdF';
const BASE_SEPOLIA_DEFAULT_KEY = 'cea99f985118ba7f869d8778ba7f233d98ded0ea3899e27acc7b8709ded8030c';
const ContractAddress = "0x859Bb215897ED323508155c212fe6B30Cc895da4";
const provider = new ethers.JsonRpcProvider('https://sepolia.base.org');


const PRIVATE_KEY = '0x2678df87e92d502ebe0686d9cba733867d6b4a76cadfae9fb12eeb9fa931b505';


    const EntryPointABI = [{"inputs":[{"internalType":"bool","name":"success","type":"bool"},{"internalType":"bytes","name":"ret","type":"bytes"}],"name":"DelegateAndRevert","type":"error"},{"inputs":[{"internalType":"uint256","name":"opIndex","type":"uint256"},{"internalType":"string","name":"reason","type":"string"}],"name":"FailedOp","type":"error"},{"inputs":[{"internalType":"uint256","name":"opIndex","type":"uint256"},{"internalType":"string","name":"reason","type":"string"},{"internalType":"bytes","name":"inner","type":"bytes"}],"name":"FailedOpWithRevert","type":"error"},{"inputs":[{"internalType":"bytes","name":"returnData","type":"bytes"}],"name":"PostOpReverted","type":"error"},{"inputs":[],"name":"ReentrancyGuardReentrantCall","type":"error"},{"inputs":[{"internalType":"address","name":"sender","type":"address"}],"name":"SenderAddressResult","type":"error"},{"inputs":[{"internalType":"address","name":"aggregator","type":"address"}],"name":"SignatureValidationFailed","type":"error"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"userOpHash","type":"bytes32"},{"indexed":true,"internalType":"address","name":"sender","type":"address"},{"indexed":false,"internalType":"address","name":"factory","type":"address"},{"indexed":false,"internalType":"address","name":"paymaster","type":"address"}],"name":"AccountDeployed","type":"event"},{"anonymous":false,"inputs":[],"name":"BeforeExecution","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":false,"internalType":"uint256","name":"totalDeposit","type":"uint256"}],"name":"Deposited","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"userOpHash","type":"bytes32"},{"indexed":true,"internalType":"address","name":"sender","type":"address"},{"indexed":false,"internalType":"uint256","name":"nonce","type":"uint256"},{"indexed":false,"internalType":"bytes","name":"revertReason","type":"bytes"}],"name":"PostOpRevertReason","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"aggregator","type":"address"}],"name":"SignatureAggregatorChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":false,"internalType":"uint256","name":"totalStaked","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"unstakeDelaySec","type":"uint256"}],"name":"StakeLocked","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":false,"internalType":"uint256","name":"withdrawTime","type":"uint256"}],"name":"StakeUnlocked","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":false,"internalType":"address","name":"withdrawAddress","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"StakeWithdrawn","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"userOpHash","type":"bytes32"},{"indexed":true,"internalType":"address","name":"sender","type":"address"},{"indexed":true,"internalType":"address","name":"paymaster","type":"address"},{"indexed":false,"internalType":"uint256","name":"nonce","type":"uint256"},{"indexed":false,"internalType":"bool","name":"success","type":"bool"},{"indexed":false,"internalType":"uint256","name":"actualGasCost","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"actualGasUsed","type":"uint256"}],"name":"UserOperationEvent","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"userOpHash","type":"bytes32"},{"indexed":true,"internalType":"address","name":"sender","type":"address"},{"indexed":false,"internalType":"uint256","name":"nonce","type":"uint256"}],"name":"UserOperationPrefundTooLow","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"userOpHash","type":"bytes32"},{"indexed":true,"internalType":"address","name":"sender","type":"address"},{"indexed":false,"internalType":"uint256","name":"nonce","type":"uint256"},{"indexed":false,"internalType":"bytes","name":"revertReason","type":"bytes"}],"name":"UserOperationRevertReason","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":false,"internalType":"address","name":"withdrawAddress","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"Withdrawn","type":"event"},{"inputs":[{"internalType":"uint32","name":"unstakeDelaySec","type":"uint32"}],"name":"addStake","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"target","type":"address"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"delegateAndRevert","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"depositTo","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"deposits","outputs":[{"internalType":"uint256","name":"deposit","type":"uint256"},{"internalType":"bool","name":"staked","type":"bool"},{"internalType":"uint112","name":"stake","type":"uint112"},{"internalType":"uint32","name":"unstakeDelaySec","type":"uint32"},{"internalType":"uint48","name":"withdrawTime","type":"uint48"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"getDepositInfo","outputs":[{"components":[{"internalType":"uint256","name":"deposit","type":"uint256"},{"internalType":"bool","name":"staked","type":"bool"},{"internalType":"uint112","name":"stake","type":"uint112"},{"internalType":"uint32","name":"unstakeDelaySec","type":"uint32"},{"internalType":"uint48","name":"withdrawTime","type":"uint48"}],"internalType":"struct IStakeManager.DepositInfo","name":"info","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"uint192","name":"key","type":"uint192"}],"name":"getNonce","outputs":[{"internalType":"uint256","name":"nonce","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes","name":"initCode","type":"bytes"}],"name":"getSenderAddress","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"components":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"uint256","name":"nonce","type":"uint256"},{"internalType":"bytes","name":"initCode","type":"bytes"},{"internalType":"bytes","name":"callData","type":"bytes"},{"internalType":"bytes32","name":"accountGasLimits","type":"bytes32"},{"internalType":"uint256","name":"preVerificationGas","type":"uint256"},{"internalType":"bytes32","name":"gasFees","type":"bytes32"},{"internalType":"bytes","name":"paymasterAndData","type":"bytes"},{"internalType":"bytes","name":"signature","type":"bytes"}],"internalType":"struct PackedUserOperation","name":"userOp","type":"tuple"}],"name":"getUserOpHash","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"components":[{"components":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"uint256","name":"nonce","type":"uint256"},{"internalType":"bytes","name":"initCode","type":"bytes"},{"internalType":"bytes","name":"callData","type":"bytes"},{"internalType":"bytes32","name":"accountGasLimits","type":"bytes32"},{"internalType":"uint256","name":"preVerificationGas","type":"uint256"},{"internalType":"bytes32","name":"gasFees","type":"bytes32"},{"internalType":"bytes","name":"paymasterAndData","type":"bytes"},{"internalType":"bytes","name":"signature","type":"bytes"}],"internalType":"struct PackedUserOperation[]","name":"userOps","type":"tuple[]"},{"internalType":"contract IAggregator","name":"aggregator","type":"address"},{"internalType":"bytes","name":"signature","type":"bytes"}],"internalType":"struct IEntryPoint.UserOpsPerAggregator[]","name":"opsPerAggregator","type":"tuple[]"},{"internalType":"address payable","name":"beneficiary","type":"address"}],"name":"handleAggregatedOps","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"components":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"uint256","name":"nonce","type":"uint256"},{"internalType":"bytes","name":"initCode","type":"bytes"},{"internalType":"bytes","name":"callData","type":"bytes"},{"internalType":"bytes32","name":"accountGasLimits","type":"bytes32"},{"internalType":"uint256","name":"preVerificationGas","type":"uint256"},{"internalType":"bytes32","name":"gasFees","type":"bytes32"},{"internalType":"bytes","name":"paymasterAndData","type":"bytes"},{"internalType":"bytes","name":"signature","type":"bytes"}],"internalType":"struct PackedUserOperation[]","name":"ops","type":"tuple[]"},{"internalType":"address payable","name":"beneficiary","type":"address"}],"name":"handleOps","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint192","name":"key","type":"uint192"}],"name":"incrementNonce","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes","name":"callData","type":"bytes"},{"components":[{"components":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"uint256","name":"nonce","type":"uint256"},{"internalType":"uint256","name":"verificationGasLimit","type":"uint256"},{"internalType":"uint256","name":"callGasLimit","type":"uint256"},{"internalType":"uint256","name":"paymasterVerificationGasLimit","type":"uint256"},{"internalType":"uint256","name":"paymasterPostOpGasLimit","type":"uint256"},{"internalType":"uint256","name":"preVerificationGas","type":"uint256"},{"internalType":"address","name":"paymaster","type":"address"},{"internalType":"uint256","name":"maxFeePerGas","type":"uint256"},{"internalType":"uint256","name":"maxPriorityFeePerGas","type":"uint256"}],"internalType":"struct EntryPoint.MemoryUserOp","name":"mUserOp","type":"tuple"},{"internalType":"bytes32","name":"userOpHash","type":"bytes32"},{"internalType":"uint256","name":"prefund","type":"uint256"},{"internalType":"uint256","name":"contextOffset","type":"uint256"},{"internalType":"uint256","name":"preOpGas","type":"uint256"}],"internalType":"struct EntryPoint.UserOpInfo","name":"opInfo","type":"tuple"},{"internalType":"bytes","name":"context","type":"bytes"}],"name":"innerHandleOp","outputs":[{"internalType":"uint256","name":"actualGasCost","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"uint192","name":"","type":"uint192"}],"name":"nonceSequenceNumber","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes4","name":"interfaceId","type":"bytes4"}],"name":"supportsInterface","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"unlockStake","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address payable","name":"withdrawAddress","type":"address"}],"name":"withdrawStake","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address payable","name":"withdrawAddress","type":"address"},{"internalType":"uint256","name":"withdrawAmount","type":"uint256"}],"name":"withdrawTo","outputs":[],"stateMutability":"nonpayable","type":"function"},{"stateMutability":"payable","type":"receive"}]
    const ZapAccountABI = [{"type":"constructor","inputs":[{"name":"anEntryPoint","type":"address","internalType":"contract IEntryPoint"}],"stateMutability":"nonpayable"},{"type":"function","name":"entryPoint","inputs":[],"outputs":[{"name":"","type":"address","internalType":"contract IEntryPoint"}],"stateMutability":"view"},{"type":"function","name":"execute","inputs":[{"name":"dest","type":"address","internalType":"address"},{"name":"value","type":"uint256","internalType":"uint256"},{"name":"func","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"executeUserOp","inputs":[{"name":"userOp","type":"tuple","internalType":"struct PackedUserOperation","components":[{"name":"sender","type":"address","internalType":"address"},{"name":"nonce","type":"uint256","internalType":"uint256"},{"name":"initCode","type":"bytes","internalType":"bytes"},{"name":"callData","type":"bytes","internalType":"bytes"},{"name":"accountGasLimits","type":"bytes32","internalType":"bytes32"},{"name":"preVerificationGas","type":"uint256","internalType":"uint256"},{"name":"gasFees","type":"bytes32","internalType":"bytes32"},{"name":"paymasterAndData","type":"bytes","internalType":"bytes"},{"name":"signature","type":"bytes","internalType":"bytes"}]},{"name":"userOpHash","type":"bytes32","internalType":"bytes32"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"owner","inputs":[],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"view"},{"type":"function","name":"validateUserOp","inputs":[{"name":"userOp","type":"tuple","internalType":"struct PackedUserOperation","components":[{"name":"sender","type":"address","internalType":"address"},{"name":"nonce","type":"uint256","internalType":"uint256"},{"name":"initCode","type":"bytes","internalType":"bytes"},{"name":"callData","type":"bytes","internalType":"bytes"},{"name":"accountGasLimits","type":"bytes32","internalType":"bytes32"},{"name":"preVerificationGas","type":"uint256","internalType":"uint256"},{"name":"gasFees","type":"bytes32","internalType":"bytes32"},{"name":"paymasterAndData","type":"bytes","internalType":"bytes"},{"name":"signature","type":"bytes","internalType":"bytes"}]},{"name":"userOpHash","type":"bytes32","internalType":"bytes32"},{"name":"missingAccountFunds","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"validationData","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"error","name":"ECDSAInvalidSignature","inputs":[]},{"type":"error","name":"ECDSAInvalidSignatureLength","inputs":[{"name":"length","type":"uint256","internalType":"uint256"}]},{"type":"error","name":"ECDSAInvalidSignatureS","inputs":[{"name":"s","type":"bytes32","internalType":"bytes32"}]}]
    // Connect to the network
    const wallet = new ethers.Wallet('0x2678df87e92d502ebe0686d9cba733867d6b4a76cadfae9fb12eeb9fa931b505', provider);

    const ep = new ethers.Contract(EP, EntryPointABI, wallet);

    const verificationGasLimit = 1000000;
    const callGasLimit = 100000;
    const maxPriorityFeePerGas = 619488;
    const maxFeePerGas = 619488;

    const sender = "0xE17d3c87B0903E9D05BbB3D07c2626Bb841b17d6"
    console.log('Sender:', sender);

    //const callData = generateCallData(ContractAddress, 0, 0);
    const validUntil = Math.floor(Date.now() / 1000) + 1000;
    const validAfter = Math.floor(Date.now() / 1000);

    //const ic = generateInitCode(AF, MY_ADDRESS, SALT);
    const dest = "0x523A8ad9A2f7636d0Bc47e63cA1a3E9474D05894";
    const  value=0;
    const userOp = {
        sender: sender,
        nonce: await ep.getNonce(sender, 0),
        initCode: '0x',
        callData:await generateCallData(dest,value,0),
        accountGasLimits: "0x000000000000000000000000000f424000000000000000000000000000002710",
        preVerificationGas: 1000000,
        gasFees:"0x000000000000000000000000000973e0000000000000000000000000000973e0",
        paymasterAndData: '0xbc5ee9e1888037abf7b595bbd7031d50f586f657000000000000000000000000000f4240000000000000000000000000000f4240',
        signature: '0x'
    };


    //const pmData = await generatePaymasterAndData(userOp, validUntil, validAfter);
    //userOp.paymasterAndData = pmData;

    const userOpHash = await ep.getUserOpHash(userOp);
    // func call
    userOp.signature= await Sign(userOpHash) //PRIVATE_KEY.signMessage(ethers.getBytes(userOpHash));
    async function generateCallData(dest, value, id) {
      const data = await generateCallDataForLikedPost(id);
     const iface = new ethers.Interface([' function execute(address dest, uint256 value, bytes data) external']);
     return iface.encodeFunctionData('execute', [dest, value, data]);
  }
  
  // async function generatePaymasterAndData(userOp, validUntil, validAfter) {
  
  //      const PMData = ethers.concat([
  //         ethers.utils.arrayify(PM),
  //         ethers.utils.arrayify(ethers.utils.defaultAbiCoder.encode(["uint128"], [verificationGasLimit])),
  //         ethers.utils.arrayify(ethers.utils.defaultAbiCoder.encode(["uint128"], [verificationGasLimit]))
  //     ]);
  
  //     return PMData;
  // }
  
  async function generateCallDataForLikedPost(postId) {
      const iface = new ethers.Interface([' function likePost(uint256 postId) public']);
      return iface.encodeFunctionData('likePost', [postId]);
   }
  async function Sign(userOpHash) {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const signature = await signer.signMessage(getBytes(userOpHash))
      const {r,s,v} =Signature.from(signature)
      const vBytes = ethers.getBytes(ethers.toBeHex(v));
      const sig = ethers.concat([r ,s, vBytes])
      const sighex  = getBytes(sig);
      return sighex
  }


  
}

const fetchAdvertisment = async () => {
  try {
      const contractAddress = "0xb76374Ca7313c9D770FC3901F9c4d831F877D521";
      const provider = new ethers.JsonRpcProvider(
          "https://base-sepolia.g.alchemy.com/v2/9epB18aWeXPPH4GFsiiQhk8CoM1p-L6B"
      );
      const privateKey = "fce83e6f7b4fb5574e0b1fb4ee253cdd5afb6ab2d07fccf1e01003de0ed0fe83"; // Ensure you secure your private key
      const wallet = new ethers.Wallet(privateKey, provider);
      const contract = new ethers.Contract(contractAddress, uabi, wallet);

      const nonce = await contract.nonces(wallet.address);
      const adDuration = 11; // Duration of the advertisement in seconds
      const adWatched = await contract.startVideoAd(0, adDuration, nonce);

      const currentTimestamp = getCurrentTimestamp();
      const Noncenormal = parseInt(nonce.toString(), 10);

      // Create a message hash
      const messageHash = keccak256(
          AbiCoder.defaultAbiCoder().encode(
              ['address', 'uint256', 'uint256', 'uint256'],
              [wallet.address, currentTimestamp, 0, Noncenormal]
          )
      );

      // Sign the message hash
      try {
          const ad = await contract.getAd(0);
          const adUrl = ad[4]; // Load ad URL from the ad data
          setAdUrl(adUrl); // Set the ad URL to state
          setIsAdPlaying(true); // Start playing the ad

          // Sign the advertisement
          const signedAd = await wallet.signMessage(getBytes(messageHash));
          console.log("Signed Advertisement:", signedAd);
          
          // Play the ad (ensure that `setIsAdPlaying` triggers the video display)
          setIsAdPlaying(true);
          setAdUrl(adUrl); // Assume `adUrl` is the URL for the video
          
          // Set a timeout to run the subsequent functions after the video finishes
          setTimeout(async () => {
            setIsAdPlaying(false); // Stop displaying the ad
            setAdUrl(""); // Clear the ad URL after closing
          
            // Ensure these operations run only after the ad has played completely
            getUserSignIOpHash();
          
            try {
              const scriptModule = await import('./script.js');
              console.log('script.js has been loaded and executed.');
            } catch (error) {
              console.error('Failed to load script.js:', error);
            }
          
            // Verify the signed advertisement
            const verifiedAd = await contract.verifyAdWatch(
              wallet.address,
              currentTimestamp,
              0,
              Noncenormal,
              signedAd
            );
          
          }, adDuration * 1000); // Convert `adDuration` from seconds to milliseconds

          // Automatically close the ad after the specified duration
         
         

      } catch (error) {
          console.error("Error during transaction signing or verification:", error);
          console.trace(); // Print stack trace for debugging
      }
  } catch (error) {
      console.error("Error watching ad:", error);
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
    }).then((result) => {
      if (result.isConfirmed) {
        fetchAdvertisment(id);
    } else {
        proceedWithTransaction(id);
      }
    });
  };
  
  // Separate function to proceed with the transaction
  const proceedWithTransaction = async (id) => {
    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const contract = new Contract(Contractaddress, uabi, signer);
      const like = await contract.likePost(id);
      Swal.fire('Transaction Successful', 'You have successfully liked the post.', 'success');
      console.log("Post liked:", like);
    } catch (error) {
      Swal.fire('Error', 'Transaction failed. Please try again.', 'error');
      console.error("Transaction error:", error);
    }
  };

  const commentPost = async (postId) => {
    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const contract = new Contract(ContractAddress, abi, signer);
      const tx = await contract.addComment(postId, "Hello World");
      await tx.wait();
      console.log("Comment added:", postId);
    } catch (error) {
      console.error("Error adding comment:", error);
    }
  };

  const sharePost = async (postId) => {
    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const contract = new Contract(ContractAddress, abi, signer);
      const tx = await contract.sharePost(postId);
      await tx.wait();
      console.log("Post shared:", postId);
    } catch (error) {
      console.error("Error sharing post:", error);
    }
  };

  const AdModal = ({ adUrl, onClose }) => {
    return (
        <div className="fixed top-0 left-0 w-full h-full bg-black bg-opacity-75 flex items-center justify-center z-50">
            <div className="relative w-full h-full flex items-center justify-center">
                <iframe 
                    src={adUrl} 
                    title="Advertisement" 
                    className="w-full h-full" 
                    allowFullScreen 
                    allow="autoplay; fullscreen"
                    frameBorder="0"
                    style={{ pointerEvents: 'none' }} // Prevent interaction
                />
                <button 
                    className="absolute top-4 right-4 text-white" 
                    onClick={onClose}
                    style={{ display: 'none' }} // Hide close button
                >
                    Close
                </button>
            </div>
        </div>
    );
};


  if (!users.length || !posts.length) return <div>Loading...</div>;

  return (
    <>
    <div>
      {posts.map((post, idx) => {
        const user = users.find((user) => user.address === post.owner);
        return (
          <div key={post.postId} className="postWrapper">
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
                animate={{ scale: open ? 2 : 1 }}
                onClick={async () => {
                  setOpen(!open);
                  const content = await fetchPostContent(post.content);
                  setPostContent(content);
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
            <div className="footer" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '10px 15px', borderTop: '1px solid #e0e0e0' }}>
              <div className="leftActions" style={{ display: 'flex', gap: '10px' }}>
                <div className="likeAction" onClick={() => likePost(post.postId)}>
                  <HiOutlineHeart />
                  <span>{post.likes}</span>
                </div>
                <div className="commentAction" onClick={() => commentPost(post.postId)}>
                  <HiOutlineChatBubbleOvalLeftEllipsis />
                </div>
                <div className="shareAction" onClick={() => sharePost(post.postId)}>
                  <HiOutlineShare />
                </div>
              </div>
              <div className="bookmarkAction">
                <HiOutlineBookmark />
              </div>
            </div>
          </div>
        );
      })}
      </div>
      {isAdPlaying && (
            <AdModal adUrl={adUrl} onClose={() => setIsAdPlaying(false)} />
        )}
    </>
  );
};

export default Post;