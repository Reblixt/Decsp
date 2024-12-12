import CreatePaymentPlan from "./section/createPaymentPlan"
import NewClient from "./section/createUserForm"

export default function Page() {
  return (
    <main className="container mx-auto p-4">
      <NewClient />
      <CreatePaymentPlan />
    </main>
  )
}
