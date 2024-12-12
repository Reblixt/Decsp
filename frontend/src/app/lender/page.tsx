import CreatePayment from "./section/createPayment"
import CreatePaymentPlan from "./section/createPaymentPlan"
import NewClient from "./section/createUserForm"

export default function Page() {
  return (
    <main className="container mx-auto p-4">
      <div className="bg-white p-4 rounded-lg shadow mb-5">
        <NewClient />
      </div>

      <div className="bg-white p-4 rounded-lg shadow mb-5">
        <CreatePaymentPlan />
      </div>

      <div className="bg-white p-4 rounded-lg shadow">
        <CreatePayment />
      </div>
    </main>
  )
}
