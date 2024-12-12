"use client"
import { StatCard } from "@/components/stat-card";
import { Button } from "@/components/ui/button";
import { creditScoreAbi, creditScoreAddress } from "@/contracts/creditScore";
import { useProfileData } from "@/hooks/useProfileData";
import { useState } from "react";
import { Address } from "viem";
import { useReadContract } from "wagmi";

export default function CreditScoreByLender() {
  const { profileData, client } = useProfileData();
  const [lender, setLender] = useState(profileData.lenders[0] as Address);

  const { data, refetch, error, status } = useReadContract({
    abi: creditScoreAbi,
    address: creditScoreAddress,
    functionName: "getMyCreditScore",
    account: client?.account,
    args: [lender as Address],
  })

  function handleChange(e: React.ChangeEvent<HTMLSelectElement>) {
    // e.preventDefault();
    setLender(e.target.value as Address)
    refetch()
  }
  console.log("lender score", data);
  console.log("lender error", error);
  console.log("lender status", status);


  return (
    <div>
      <StatCard title={`Lender specific credit score ${lender}`} value={Number(data)} />
      <select onChange={(e) => handleChange(e)}>
        {profileData.lenders.map((lender) => (
          <option key={lender}>{lender}</option>
        ))}
      </select>
      <Button onClick={() => refetch()}>Refresh</Button>
      {/* {meanStatus === 'error' && <StatCard title="Error Could not fetch mean credit score" value={404} />} */}
    </div>

  )
}
