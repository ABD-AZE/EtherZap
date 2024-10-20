export interface Ad {
    id: number;
    sponsor: string;
    adType: 'Video' | 'Banner'; // You can change this to an enum if needed
    contentId: string;
    quantity: number;
    price: number;
    isActive: boolean;    // Indicates if the ad is active or inactive
    viewCount: number;    // Number of views the ad has received
    title: string;
  }