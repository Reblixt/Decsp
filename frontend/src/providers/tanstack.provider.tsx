"use client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";

const queryClient = new QueryClient();

interface TanstackProps {
  children: React.ReactNode;
}

export default function Tanstack({ children }: TanstackProps) {
  return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>;
}
