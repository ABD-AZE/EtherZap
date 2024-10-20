// AdSubmissionForm.tsx
import React, { useState } from 'react';
import { Ad } from '@/types/form'; // Adjust the path as necessary

interface AdSubmissionFormProps {
  onSubmit: (ad: Ad) => void;
}

const AdSubmissionForm: React.FC<AdSubmissionFormProps> = ({ onSubmit }) => {
  const [adType, setAdType] = useState<'Video' | 'Banner'>('Video');
  const [contentId, setContentId] = useState('');
  const [quantity, setQuantity] = useState<number>(1);
  const [price, setPrice] = useState<number>(0.01);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    const newAd: Ad = {
      id: Date.now(), // Temporary ID; replace with actual logic if needed
      sponsor: 'Company Name', // Replace with actual sponsor data
      adType,
      title: 'Ad Title',
      contentId,
      quantity,
      price,
      isActive: true,
      viewCount: 0
    };

    onSubmit(newAd);
    // Reset form fields after submission
    setContentId('');
    setQuantity(1);
    setPrice(0.01);
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

        <label>
          Price:
          <input
            type="number"
            value={price}
            onChange={(e) => setPrice(Number(e.target.value))}
            className="w-full rounded-[7px] border-[1.5px] border-stroke px-3 py-2"
            step="0.01"
            required
          />
        </label>

        <button
          type="submit"
          className="mt-4 flex justify-center rounded-[7px] bg-primary p-2 text-white hover:bg-opacity-90"
        >
          Submit Ad
        </button>
      </form>
    </div>
  );
};

export default AdSubmissionForm;
