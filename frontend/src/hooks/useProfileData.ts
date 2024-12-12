import { creditScoreAbi, creditScoreAddress } from "@/contracts/creditScore";
import { useMemo } from "react";
import { Address } from "viem";
import { useReadContract, useWalletClient } from "wagmi";

export const useProfileData = () => {
  const { data: client } = useWalletClient();
  const { data, status, error } = useReadContract({
    abi: creditScoreAbi,
    address: creditScoreAddress,
    functionName: "getMyProfile",
    account: client?.account,
  });

  const profileData = useMemo(() => {
    if (!data)
      return {
        active: false,
        lenders: [] as Address[],
        paymentPlans: [] as bigint[],
        numberOfCreditScores: 0,
        numberOfLoans: 0,
      };

    return {
      active: data[0],
      lenders: data[1] as Address[],
      paymentPlans: data[2] as bigint[],
      numberOfCreditScores: data[3],
      numberOfLoans: data[4],
    };
  }, [data]);
  if (status === "error") {
    console.log(error);
  }

  return { profileData, status, error, client };
};
