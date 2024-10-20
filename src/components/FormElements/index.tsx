"use client";
import Breadcrumb from "@/components/Breadcrumbs/Breadcrumb";
import React, { useState } from 'react';
import { Ad } from "@/types/form";
import AdSubmissionForm from "./AdSubmissionForm";
import AdsTable from "./AdsTable";


const FormElements = () => {
  const [ads, setAds] = useState<Ad[]>([]);

  const handleAdSubmit = (ad: Ad) => {
    setAds((prevAds) => [...prevAds, ad]);
   
  };

  return (
    <>
      <Breadcrumb pageName="Upload Ad" />

      <div className="grid grid-cols-1 gap-9 sm:grid-cols-2">
        <div className="flex flex-col gap-9">
          {/* Ad Submission Form and Ads Table */}
          <div className="rounded-[10px] border border-stroke bg-white shadow-1 dark:border-dark-3 dark:bg-gray-dark dark:shadow-card">
            <div className="border-b border-stroke px-6.5 py-4 dark:border-dark-3">
              <h3 className="font-medium text-dark dark:text-white">Submit Ad</h3>
            </div>
            <AdSubmissionForm onSubmit={handleAdSubmit} />
            <AdsTable ads={ads} />
          </div>

          
        </div>

      </div>
    </>
  );
};

export default FormElements;
