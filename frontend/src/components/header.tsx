import Link from "next/link";
import WalletBtton from "./wallet-button";

export function Header() {




  return (
    <header className="flex justify-between items-center p-4 bg-gray-400">
      <h1 className="text-2xl font-bold">Desc.io</h1>
      <div className="border rounded p-1 border-black bg-white ">
        <Link href="/user">
          User
        </Link>
      </div>
      <div className="border rounded p-1 border-black bg-white ">
        <Link href="/lender">
          Lender
        </Link>
      </div>
      <div className="border rounded p-1 border-black bg-white ">
        <Link href="/admin">
          Admin
        </Link>
      </div>
      <WalletBtton />
    </header>
  )
}

