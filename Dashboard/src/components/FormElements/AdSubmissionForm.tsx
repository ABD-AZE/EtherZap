import React, { useState } from 'react';

// Extend the Window interface to include the ethereum property
declare global {
  interface Window {
    ethereum?: any;
  }
}
import { ethers } from 'ethers';
import { parseEther } from 'ethers';

import { Ad } from '@/types/form'; // Adjust the path as necessary

const ContractAddress = "0x27b6E69a6ad26fad001A8e94b837628452241489"; // Replace with your contract address
const abi = [{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"adId","type":"uint256"},{"indexed":true,"internalType":"address","name":"sponsor","type":"address"},{"indexed":false,"internalType":"enum AdMarketPlace.AdType","name":"adType","type":"uint8"},{"indexed":false,"internalType":"string","name":"contentId","type":"string"},{"indexed":false,"internalType":"uint256","name":"quantity","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"price","type":"uint256"}],"name":"AdCreated","type":"event"},{"inputs":[],"name":"COST_PER_AD","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"adCount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"ads","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"address","name":"sponsor","type":"address"},{"internalType":"enum AdMarketPlace.AdType","name":"adType","type":"uint8"},{"internalType":"string","name":"contentId","type":"string"},{"internalType":"uint256","name":"quantity","type":"uint256"},{"internalType":"uint256","name":"price","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"enum AdMarketPlace.AdType","name":"adType","type":"uint8"},{"internalType":"uint256","name":"quantity","type":"uint256"},{"internalType":"string","name":"contentId","type":"string"}],"name":"submitAd","outputs":[],"stateMutability":"payable","type":"function"}];

const COST_PER_AD = 0.01; // Cost per ad in ether

interface AdSubmissionFormProps {
  onSubmit: (ad: Ad) => void;
}

const AdSubmissionForm: React.FC<AdSubmissionFormProps> = ({ onSubmit }) => {
  const [adType, setAdType] = useState<'Video' | 'Banner'>('Video');
  const [contentId, setContentId] = useState('');
  const [quantity, setQuantity] = useState<number>(1);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      // Check if MetaMask is installed
      if (!window.ethereum) {
        alert('MetaMask is not installed. Please install it to use this app.');
        return;
      }

      // Request account access if needed
      await window.ethereum.request({ method: 'eth_requestAccounts' });

      // Get the Ethereum provider and signer
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const contract = new ethers.Contract(ContractAddress, abi, signer);

      // Convert adType to enum (0 for Video, 1 for Banner)
      const adTypeValue = adType === 'Video' ? 0 : 1;

      // Calculate total cost based on quantity
      const totalCost = parseEther((quantity * COST_PER_AD).toString());

      // Call the smart contract function to submit the ad
      const tx = await contract.submitAd(adTypeValue, quantity, contentId, {
        value: totalCost, // Send the total cost
      });

      // Wait for the transaction to be mined
      await tx.wait();

      // Create the new ad object
      const newAd: Ad = {
        id: Date.now(), // Temporary ID; replace with actual logic if needed
        sponsor: await signer.getAddress(), // Get the address of the ad sponsor
        adType,
        contentId,
        quantity,
        price: COST_PER_AD, // Set the cost per ad
        isActive: true,
        viewCount: 0
      };

      onSubmit(newAd); // Call the onSubmit prop to handle the new ad

      // Reset form fields after submission
      setContentId('');
      setQuantity(1);
    } catch (error) {
      console.error("Error submitting ad:", error);
      alert("An error occurred while submitting the ad. Please check the console for more details.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="rounded-[10px] border border-stroke bg-white shadow-1 dark:border-dark-3 dark:bg-gray-dark dark:shadow-card">
      <form onSubmit={handleSubmit} className="p-6.5 flex flex-col gap-4">
        <label>
          Ad Type:
          <select
            value={adType}
            onChange={(e) => setAdType(e.target.value as 'Video' | 'Banner')}
            className="w-full rounded-[7px] border-[1.5px] border-stroke px-3 py-2"
          >
            <option value="Video">Video</option>
            <option value="Banner">Banner</option>
          </select>
        </label>

        <label>
          Content ID:
          <input
            type="text"
            value={contentId}
            onChange={(e) => setContentId(e.target.value)}
            className="w-full rounded-[7px] border-[1.5px] border-stroke px-3 py-2"
            placeholder="Enter Content ID"
            required
          />
        </label>

        <label>
          Quantity:
          <input
            type="number"
            value={quantity}
            onChange={(e) => setQuantity(Number(e.target.value))}
            className="w-full rounded-[7px] border-[1.5px] border-stroke px-3 py-2"
            min="1"
            required
          />
        </label>

        <button
          type="submit"
          className="mt-4 flex justify-center rounded-[7px] bg-primary p-2 text-white hover:bg-opacity-90"
          disabled={loading}
        >
          {loading ? 'Submitting...' : 'Submit Ad'}
        </button>
      </form>
    </div>
  );
};

export default AdSubmissionForm;

