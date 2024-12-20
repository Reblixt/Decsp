"use client";
import { WagmiProvider } from "@privy-io/wagmi";
import { config } from "@/config/wagmi-config";

interface WagmiProps {
  children: React.ReactNode;
}

export default function Wagmi({ children }: WagmiProps) {
  return <WagmiProvider config={config} >{children}</WagmiProvider>;
}
