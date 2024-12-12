import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { Address } from "viem"

export default function GetActiveLenders({ lenders }: { lenders: Address[] }) {

  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>Index</TableHead>
          <TableHead>Lender address</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {lenders.map((lender, i) => {
          return (
            <TableRow key={lender}>
              <TableCell>{i}</TableCell>
              <TableCell>{lender}</TableCell>
            </TableRow>
          )
        })}
      </TableBody>
    </Table>
  )

}
