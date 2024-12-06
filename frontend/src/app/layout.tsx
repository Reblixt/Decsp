import "@/app/globals.css"
import { Inter } from 'next/font/google'
import Tanstack from "@/providers/tanstack.provider"
import Wagmi from "@/providers/wagmi.provider"
import PrivyProvider from "@/providers/privy.provider"
import { Header } from "@/components/header"

const inter = Inter({ subsets: ["latin"] })

export const metadata = {
  title: "Decentralized Credit Score",
  description: "A dashboard for managing your decentralized credit score.",
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={inter.className}>
        <PrivyProvider>

          <Tanstack>
            <Wagmi>
              <Header />
              {children}
            </Wagmi>
          </Tanstack>
        </PrivyProvider>
      </body>
    </html>
  )
}

