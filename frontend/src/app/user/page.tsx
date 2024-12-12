
import ApproveLender from "./section/approveLender"
import ApprovePaymentPlan from "./section/approvePaymentPlan"
import CreditScoreByLender from "./section/creditScoreByLender"
import { DataTable } from "./section/data-card"
import MeanCreditScore from "./section/meanCreditScore"
import { NextInstallmentTable } from "./section/nextInstallmentTable"
export default function Page() {
  return (
    <main className="container mx-auto p-4">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-8">
        <MeanCreditScore />
        <CreditScoreByLender />
      </div>
      <div className="bg-white p-4 rounded-lg shadow">
        <h2 className="text-xl font-semibold mb-4">User Data</h2>
        <DataTable />
      </div>
      <div className="bg-white p-4 rounded-lg shadow mt-4 flex space-x-10">
        <ApproveLender className="flex-row w-96 " />
        <ApprovePaymentPlan className="flex-row" />
      </div>
      <div className="bg-white p-4 rounded-lg shadow mt-4 flex space-x-10">
        <NextInstallmentTable />
      </div>
    </main>
  )
}
