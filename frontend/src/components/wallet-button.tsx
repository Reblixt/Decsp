"use client";
import { usePrivy } from "@privy-io/react-auth";
import { Button } from "./ui/button";
import { useSwitchChain } from "wagmi";

export default function WalletBtton() {
  const { login, logout, authenticated } = usePrivy();

  const { chains, switchChain } = useSwitchChain();
  console.log("chain", chains);
  console.log("switchChain", switchChain);

  return (
    <>
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
