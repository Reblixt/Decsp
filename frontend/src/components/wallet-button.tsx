"use client";
import { usePrivy } from "@privy-io/react-auth";
import { Button } from "./ui/button";
import { useAccount, useSwitchChain } from "wagmi";
import { config } from "@/config/wagmi-config";
import { useState } from "react";

export default function WalletBtton() {
  const { login, logout, authenticated } = usePrivy();
  const [chainId, setChainId] = useState<31337 | 137 | 80002>(31337);

  const account = useAccount();

  const { switchChain, status } = useSwitchChain({
    config: config,
  });

  console.log("status", status);
  // console.log("data", data);
  console.log("chainId", chainId);




  return (
    <>
      <Button onClick={() => switchChain({ chainId: chainId })}>switchChain</Button>
      <select onChange={(e) => setChainId(Number(e.target.value) as 31337 | 137 | 80002)}>
        <option value={31337}>Anvil</option>
        <option value={137}>Polygon</option>
        <option value={80002}>Polygon Amoy</option>
      </select>
      {authenticated ? (
        <div>
          <Button onClick={logout}>
            Disconnect Wallet
          </Button>
          <p>{account.address?.slice(0, 5)}...{account.address?.slice(-4)}</p>
        </div>
      ) : (
        <Button onClick={login}>
          Connect Wallet
        </Button>
      )}

    </>
  );
}
