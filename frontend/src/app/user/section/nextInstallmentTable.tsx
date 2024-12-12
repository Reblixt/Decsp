"use client"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { creditScoreAbi, creditScoreAddress } from "@/contracts/creditScore";
import { useProfileData } from "@/hooks/useProfileData";
import { monthsUntil } from "@/lib/monthsUntil";
import { useState } from "react";
import { useReadContract } from "wagmi";


export function NextInstallmentTable() {
  const { profileData } = useProfileData();
  const [planId, setPlanId] = useState(profileData.paymentPlans[0]);
  // const { paymentPlanData } = usePaymentPlanData();
  const { data: nextAmount } = useReadContract({
    address: creditScoreAddress,
    abi: creditScoreAbi,
    functionName: 'getNextInstalmentAmount',
    args: [planId]
  })
  const { data: lender } = useReadContract({
    address: creditScoreAddress,
    abi: creditScoreAbi,
    functionName: 'getLenderFromId',
    args: [planId]
  })

  const { data: nextDate } = useReadContract({
    address: creditScoreAddress,
    abi: creditScoreAbi,
    functionName: 'getNextInstalmentDeadline',
    args: [planId]
  })

  if (!profileData) {
    return <div>Loading...</div>
  }

  function handleChange(e: React.ChangeEvent<HTMLSelectElement>) {
    e.preventDefault()
    setPlanId(BigInt(e.target.value))
  }


  return (
    <>
      <select onChange={(e) => handleChange(e)}>
        {profileData.paymentPlans.map((planId) => (
          <option key={planId} value={Number(planId)}>{planId}</option>
        ))}
      </select>
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Lender</TableHead>
            <TableHead>Next installment amount</TableHead>
            <TableHead>Next Deadline to pay</TableHead>
            <TableHead>Plan ID</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          <TableRow>
            <TableCell>{lender}</TableCell>
            <TableCell>{nextAmount}</TableCell>
            <TableCell>{monthsUntil(Number(nextDate)) * 30} days</TableCell>
            <TableCell>{planId}</TableCell>
          </TableRow>
        </TableBody>
      </Table>
    </>
  )
}

