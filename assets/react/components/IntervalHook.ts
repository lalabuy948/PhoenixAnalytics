import { useState } from "react";
import { useBetween } from "use-between";

const useIntervalState = () => {
  const [interval, setInterval] = useState("day");

  return {
    interval,
    setInterval,
  };
};

export const useSharedIntervalState = () => useBetween(useIntervalState);
