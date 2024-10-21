const { ethers, Signature } = require("ethers");
const correctsig = "0xb90161937f60cdff0634ae31af6db4b274249b43681162b1fa0ceb45e0a58de705b6596e3026118a7e954c8efd2ca17fb8f5fafa607b3ed26cb4e5cfcdd5a9e21b"
const correctdigest = "0x5af1f3b58dcf64ce6b99d8e6058222f71cfb002fd34ac4039237fd464cafa844"
// Assuming userOpHash is already computed
const userOpHash = "0x0419e055fc065adc705143c9835e4bddb19cf0c61f282c685fc609b4ada152da"; // Replace with the actual userOpHash
// Private key for signing (replace with the actual private key)
const BASE_SEPOLIA_DEFAULT_KEY = "0xcea99f985118ba7f869d8778ba7f233d98ded0ea3899e27acc7b8709ded8030c";
// Create a wallet instance
const wallet = new ethers.Wallet(BASE_SEPOLIA_DEFAULT_KEY);
async function signDigest() {
    const signature = await wallet.signMessage(ethers.utils.arrayify(userOpHash));
    const {r,s,v} = ethers.utils.splitSignature(signature);
    const sig = ethers.utils.concat([r, s, v]);
    const sigHex = ethers.utils.hexlify(sig);
    console.log("Signature (r, s, v) in hex:", sigHex);
}

signDigest().catch(console.error);