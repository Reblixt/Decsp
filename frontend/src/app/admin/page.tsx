"use client"
import { Address, keccak256, toHex } from "viem";
import AddLender from "./section/addLender";
import { useAccount, useReadContract, useWriteContract } from "wagmi";
import { creditScoreAbi, creditScoreAddress } from "@/contracts/creditScore";
import CheckLender from "./section/checkLender";
import { Button } from "@/components/ui/button";
import RemoveLender from "./section/removeLender";
import UpdateLender from "./section/updateLender";
import GetActiveLenders from "./section/getActiveLenders";

export default function Page() {
  const account = useAccount();

  const role = keccak256(toHex("ADMIN_ROLE"))

  const { data: hasRole, status, error } = useReadContract({
    address: creditScoreAddress,
    abi: creditScoreAbi,
    functionName: "hasRole",
    args: [role, account.address as Address],
  })

  const { data: isPaused, status: pStatus, error: pError } = useReadContract({
    address: creditScoreAddress,
    abi: creditScoreAbi,
    functionName: "paused",
  })

  const { data: lenders, status: lStatus, error: lError, refetch } = useReadContract({
    abi: creditScoreAbi,
    address: creditScoreAddress,
    functionName: "getActiveLenders",
    account: account.address,
  })

  const { writeContract, status: wStatus, error: wError } = useWriteContract();

  if (hasRole === null || isPaused === null) return <div>Loading...</div>

  console.log("hasRole", hasRole);
  console.log("status", status);
  console.log("error", error);
  console.log("account", account.address);
  function handlePauseEvent() {
    if (isPaused) {
      writeContract({
        abi: creditScoreAbi,
        address: creditScoreAddress,
        functionName: "unpause",
      })
    } else {
      writeContract({
        abi: creditScoreAbi,
        address: creditScoreAddress,
        functionName: "pause",
      })
    }

  }

  if (status || pStatus || wStatus || lStatus === 'error') {
    console.log("Could not read hasRole Admin", error)
    console.log("Could not read Paused state", pError)
    console.log("Could not Write pause/unpause to contract", wError)
    console.log("Could not read active lenders", lError)
  }


  return (
    <main className="container mx-auto p-4">
      <h1>Admin Page</h1>
      {hasRole && (
        <div>
          <CheckLender />
          <AddLender />
          <RemoveLender />
          <UpdateLender />
          <Button className="mt-8" onClick={handlePauseEvent}>{isPaused ? "Unpause contract" : "Pause contract"}</Button>
          <Button className="mt-8 ml-8" onClick={() => refetch()}>Refresh lenders list</Button>
          <GetActiveLenders lenders={lenders as Address[]} />
        </div>

      )}
    </main>
  )
}
