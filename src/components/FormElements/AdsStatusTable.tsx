import React from 'react';
import { Ad } from '@/types/form';

interface AdStatusTableProps {
  ads: Ad[];
}

const AdStatusTable: React.FC<AdStatusTableProps> = ({ ads }) => {
  return (
    <div className="rounded-[10px] border border-stroke bg-white shadow-1 dark:border-dark-3 dark:bg-gray-dark dark:shadow-card mt-4">
      <div className="border-b border-stroke px-6.5 py-4 dark:border-dark-3">
        <h3 className="font-medium text-dark dark:text-white">Ad Status Table</h3>
      </div>
      <table className="min-w-full divide-y divide-gray-200 dark:divide-dark-3">
        <thead className="bg-gray-50 dark:bg-dark-3">
          <tr>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">ID</th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
          </tr>
        </thead>
        <tbody className="bg-white divide-y divide-gray-200 dark:bg-dark-2 dark:divide-dark-3">
          {ads.map((ad) => (
            <tr key={ad.id}>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">{ad.id}</td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">{ad.isActive ? 'Active' : 'Inactive'}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default AdStatusTable;
