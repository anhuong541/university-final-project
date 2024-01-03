import FollowBar from "@/components/Home/Followbar";
import NewsFeed from "@/components/Home/NewsFeed";

import { NextPage } from "next";
import { useEffect, useState } from "react";
import loadingLottie from "@/lib/loadingLottie.json";
import Lottie from "lottie-react";
import { useAddress } from "@thirdweb-dev/react";

export default function Home() {
  const address = useAddress();
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Set a timeout for 2 seconds
    const timer = setTimeout(() => {
      setIsLoading(false);
    }, 5000);

    // Cleanup the timer when the component is unmounted
    return () => clearTimeout(timer);
  }, []);

  if (isLoading) {
    return (
      <div className="w-full">
        <Lottie
          animationData={loadingLottie}
          loop={true}
          className="w-24 h-24 mx-auto"
        />
      </div>
    );
  }

  return (
    <div className="grid grid-cols-3">
      <NewsFeed />
      <FollowBar />
    </div>
  );
}
