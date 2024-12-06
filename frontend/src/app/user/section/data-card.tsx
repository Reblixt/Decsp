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
import { Address } from "viem";
import { useReadContract, useWalletClient } from "wagmi"



const data = [
  { id: 1, name: "John Doe", age: 28, city: "New York" },
  { id: 2, name: "Jane Smith", age: 32, city: "Los Angeles" },
  { id: 3, name: "Bob Johnson", age: 45, city: "Chicago" },
  { id: 4, name: "Alice Brown", age: 22, city: "Houston" },
]

export function DataTable() {
  const { data: client } = useWalletClient();
  const { data: isClientActive } = useReadContract({
    abi: creditScoreAbi,
    address: creditScoreAddress,
    functionName: "isClientActive",
    args: [client?.account as unknown as Address],
  });

  console.log("isClientActive", isClientActive);



  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>ID</TableHead>
          <TableHead>Name</TableHead>
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
  )
}

