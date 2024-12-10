"use client"
import { StatCard } from "@/components/stat-card";
import { creditScoreAbi, creditScoreAddress } from "@/contracts/creditScore";
import { Address } from "viem";
import { useReadContract, useWalletClient } from "wagmi";

export default function MeanCreditScore() {
  const { data: client } = useWalletClient();
  const { data: meanScore, status: meanStatus, error: meanError } = useReadContract({
    abi: creditScoreAbi,
    address: creditScoreAddress,
    functionName: "getMeanCreditScore",
    account: client?.account,
    args: [client?.account.address as Address],
  })

  function handlemeanScore(meanScore: bigint | undefined): number {
    if (!meanScore) {
      return 0;
    }
    return Number(meanScore);
  }

  return (
    <div>
      {meanStatus === 'success' && <StatCard title="Mean CreditScore" value={handlemeanScore(meanScore)} />}
      {meanStatus === 'error' && <StatCard title="Error Could not fetch mean credit score" value={404} />}
    </div>

  )
}
