"use client";
import { usePrivy } from "@privy-io/react-auth";
import { Button } from "./ui/button";
import { useSwitchChain } from "wagmi";
import { config } from "@/config/wagmi-config";
import { useState } from "react";

export default function WalletBtton() {
  const { login, logout, authenticated } = usePrivy();
  const [chainId, setChainId] = useState<31337 | 137 | 80002>(31337);

  const { switchChain, status } = useSwitchChain({
    config: config,
  });

  console.log("status", status);
  // console.log("data", data);
  console.log("chainId", chainId);



  return (
    <>
      <Button onClick={() => switchChain({ chainId: chainId })}>switchChain</Button>
      <select onChange={(e) => setChainId(Number(e.target.value))}>
        <option value={31337}>Anvil</option>
        <option value={137}>Polygon</option>
        <option value={80002}>Polygon Amoy</option>
      </select>
      {authenticated ? (
        <Button onClick={logout}>
          Disconnect Wallet
        </Button>
      ) : (
        <Button onClick={login}>
          Connect Wallet
        </Button>
      )}

    </>
  );
}
