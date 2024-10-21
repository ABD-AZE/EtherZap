"use client";
import ChartTwo from "../Charts/ChartTwo";
import ChartOne from "@/components/Charts/ChartOne";
import React, { useState } from 'react';
import { Ad } from "@/types/form";
import AdSubmissionForm from "../FormElements/AdSubmissionForm";
import AdsTable from "../FormElements/AdsTable";
import AdStatusTable from "../FormElements/AdsStatusTable";

const ECommerce: React.FC = () => {
  const [ads, setAds] = useState<Ad[]>([]);
  const [videoAdsCount, setVideoAdsCount] = useState<number>(50); // Initial count for Video Ads
  const [bannerAdsCount, setBannerAdsCount] = useState<number>(40); // Initial count for Banner Ads

  const handleAdSubmit = (ad: Ad) => {
    setAds((prevAds) => [...prevAds, ad]);

    // Increment the corresponding ad count based on ad type
    if (ad.adType === 'Video') {
      setVideoAdsCount((prevCount) => prevCount + 1);
    } else {
      setBannerAdsCount((prevCount) => prevCount + 1);
    }
  };

  return (
    <>
      <div className="flex justify-center mt-4">
        <div className="flex flex-col gap-9 w-full max-w-2xl">
          {/* Ad Submission Form and Ads Table */}
          <div className="rounded-[10px] border border-stroke bg-white shadow-1 dark:border-dark-3 dark:bg-gray-dark dark:shadow-card">
            <div className="border-b border-stroke px-6.5 py-4 dark:border-dark-3">
              <h3 className="font-medium text-dark dark:text-white">Submit Ad</h3>
            </div>
            <AdSubmissionForm onSubmit={handleAdSubmit} />
          </div>
        </div>
      </div>
      <div className="mt-4 grid grid-cols-12 gap-4 md:mt-6 md:gap-6 2xl:mt-9 2xl:gap-7.5">
        <ChartOne videoAdsCount={videoAdsCount} bannerAdsCount={bannerAdsCount} />
        <ChartTwo />
        <div className="col-span-12 xl:col-span-8">
          <AdsTable ads={ads} />
          <AdStatusTable ads={ads} />
        </div>
      </div>
    </>
  );
};

export default ECommerce;
