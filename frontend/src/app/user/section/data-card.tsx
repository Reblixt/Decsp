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
import { Address, createWalletClient } from "viem";
import { useAccount, useReadContract, useWalletClient, useWriteContract } from "wagmi"



const data = [
  { id: 1, name: "John Doe", age: 28, city: "New York" },
  { id: 2, name: "Jane Smith", age: 32, city: "Los Angeles" },
  { id: 3, name: "Bob Johnson", age: 45, city: "Chicago" },
  { id: 4, name: "Alice Brown", age: 22, city: "Houston" },
]

export function DataTable() {
  const { data: client } = useWalletClient();
  const { data: activeData, status, error } = useReadContract({
    abi: creditScoreAbi,
    address: creditScoreAddress,
    functionName: "getMyProfile",
    account: client?.account,
  });


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

  // TODO: Add the fetch data from each Lender

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
              <TableHead></TableHead>
              <TableHead>Age</TableHead>
              <TableHead>City</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {data.map((row) => (
              <TableRow key={row.id}>
                <TableCell>{row.id}</TableCell>
                <TableCell>{row.name}</TableCell>
                <TableCell>{row.age}</TableCell>
                <TableCell>{row.city}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      }
    </>
  )
}

