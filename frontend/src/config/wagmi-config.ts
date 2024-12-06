import { http } from "viem";
import { createConfig } from "@privy-io/wagmi";

import { anvil, polygon, polygonAmoy } from "viem/chains";

export const config = createConfig({
  chains: [anvil, polygon, polygonAmoy],
  transports: {
    [anvil.id]: http("http://127.0.0.1:8545"),
    [polygon.id]: http("https://polygon-mainnet.g.alchemy.com/v2/" + getApi()),
    [polygonAmoy.id]: http("https://polygon-amoy.g.alchemy.com/v2/" + getApi()),
  },
});

function getApi() {
  return process.env.NEXT_PUBLIC_ALCHEMY_API;
}
