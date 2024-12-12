import { creditScoreAbi, creditScoreAddress } from "@/contracts/creditScore";
import { useMemo } from "react";
import { useReadContract, useWalletClient } from "wagmi";

export const usePaymentPlanData = () => {
  const { data: client } = useWalletClient();

  const {
    data: paymentPlan,
    status,
    error,
  } = useReadContract({
    abi: creditScoreAbi,
    address: creditScoreAddress,
    functionName: "getAllMyPaymentPlans",
    account: client?.account,
  });
  const paymentPlanData = useMemo(() => {
    if (!paymentPlan) return [];

    return paymentPlan[0].map((_, index) => ({
      active: paymentPlan[0][index],
      duration: paymentPlan[1][index],
      paidDebt: paymentPlan[2][index],
      unPaidDebt: paymentPlan[3][index],
      totalPaid: paymentPlan[4][index],
      numberOfInstallments: paymentPlan[5][index],
      interestRate: paymentPlan[6][index],
    }));
  }, [paymentPlan]);

  if (status === "error") {
    console.log(error);
  }

  return { paymentPlanData, status, error, client };
};
