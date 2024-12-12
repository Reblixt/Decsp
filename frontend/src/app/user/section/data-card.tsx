"use client"
import { Button } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { creditScoreAbi, creditScoreAddress } from "@/contracts/creditScore";
import { useEffect, useMemo } from "react";
import { Address } from "viem";
import { useReadContract, useWalletClient, useWriteContract } from "wagmi"


export function DataTable() {
  const { data: client } = useWalletClient();

  const { data: activeData, status, error } = useReadContract({
    abi: creditScoreAbi,
    address: creditScoreAddress,
    functionName: "getMyProfile",
    account: client?.account,
  });

  const { data: paymentPlan, status: pStatus, error: pError } = useReadContract({
    abi: creditScoreAbi,
    address: creditScoreAddress,
    functionName: "getAllMyPaymentPlans",
    account: client?.account,
  })


  const { writeContract: write, status: wStatus, error: wError, isSuccess } = useWriteContract();

  const profileData = useMemo(() => {
    if (!activeData) return {
      active: false,
      lenders: [] as Address[],
      paymentPlans: [] as bigint[],
      numberOfCreditScores: 0,
      numberOfLoans: 0
    };

    return {
      active: activeData[0],
      lenders: activeData[1] as Address[],
      paymentPlans: activeData[2] as bigint[],
      numberOfCreditScores: activeData[3],
      numberOfLoans: activeData[4],
    };
  }, [activeData]);


  const paymentPlanData = useMemo(() => {
    if (!paymentPlan) return [];

    return paymentPlan[0].map((_, index) => ({
      active: paymentPlan[0][index],
      duration: paymentPlan[1][index],
      paidDebt: paymentPlan[2][index],
      unPaidDebt: paymentPlan[3][index],
      totalPaid: paymentPlan[4][index],
      numberOfInstallments: paymentPlan[5][index],
      interestRate: paymentPlan[6][index],
    }));

  }, [paymentPlan])

  useEffect(() => {
    if (profileData.active) {

    }
  }, [profileData]);

  console.log("profileData", profileData);
  console.log("status", status);
  console.log("error", error);

  if (!activeData) {
    return <div>Loading...</div>
  }

  function monthsUntil(timestamp: number): number {
    const now = new Date(); // Dagens datum
    const futureDate = new Date(timestamp * 1000); // Konvertera tidsstämpeln till millisekunder

    const yearsDifference = futureDate.getFullYear() - now.getFullYear();
    const monthsDifference = futureDate.getMonth() - now.getMonth();

    // Total skillnad i månader
    return yearsDifference * 12 + monthsDifference;
  }

  return (
    <>
      {!profileData.active &&
        <div>
          <Button onClick={() => write({
            abi: creditScoreAbi,
            address: creditScoreAddress,
            functionName: "newProfile",
          })}>Create a profile</Button>


        </div>}
      {profileData.active &&
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Loaner</TableHead>
              <TableHead>Active</TableHead>
              <TableHead>Duration in month</TableHead>
              <TableHead>Paid debt</TableHead>
              <TableHead>Unpaid debt</TableHead>
              {/* <TableHead>Total paid debt</TableHead> */}
              <TableHead>Number of installments</TableHead>
              <TableHead>Interest rate</TableHead>
              <TableHead>Plan ID</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {profileData.lenders.map((lender, index) => (

              paymentPlanData.map((plan, i) => {
                return (
                  <TableRow key={i}>
                    <TableCell>{lender.slice(0, 5)}..{lender.slice(-4)}</TableCell>
                    <TableCell>{String(plan.active)}</TableCell>
                    <TableCell>{monthsUntil(Number(plan.duration))} Months</TableCell>
                    <TableCell>{plan.paidDebt} SEK</TableCell>
                    <TableCell>{plan.unPaidDebt} SEK</TableCell>
                    {/* <TableCell>{plan.totalPaid}</TableCell> */}
                    <TableCell>{plan.numberOfInstallments} st</TableCell>
                    <TableCell>{plan.interestRate}%</TableCell>
                    <TableCell>{profileData.paymentPlans[i]}</TableCell>

                  </TableRow>
                )
              })
            ))}
          </TableBody>
        </Table>
      }
    </>
  )
}

