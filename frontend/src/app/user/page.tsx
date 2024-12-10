
import { DataTable } from "./section/data-card"
import { StatCard } from "@/components/stat-card"
import MeanCreditScore from "./section/meanCreditScore"
export default function Page() {
  return (
    <main className="container mx-auto p-4">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-8">
        <StatCard title="Total Users" value={256} />
        <MeanCreditScore />
      </div>
      <div className="bg-white p-4 rounded-lg shadow">
        <h2 className="text-xl font-semibold mb-4">User Data</h2>
        <DataTable />
      </div>
    </main>
  )
}
