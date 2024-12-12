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
import { usePaymentPlanData } from "@/hooks/usePaymentPlanData";
import { useProfileData } from "@/hooks/useProfileData";
import { monthsUntil } from "@/lib/monthsUntil";
import { useWriteContract } from "wagmi"


export function DataTable() {
  const { profileData } = useProfileData();
  const { paymentPlanData } = usePaymentPlanData();
  const { writeContract: write } = useWriteContract();

  if (!profileData) {
    return <div>Loading...</div>
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
            {paymentPlanData.map((plan, i) => {
              return (
                <TableRow key={i}>
                  {/* <TableCell>{lenders[i].slice(0, 5)}..{lenders[i].slice(-4)}</TableCell> */}
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
            })}
          </TableBody>
        </Table>
      }
    </>
  )
}

