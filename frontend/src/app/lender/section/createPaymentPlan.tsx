"use client"
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod"
import { useForm } from "react-hook-form"
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useWriteContract } from "wagmi";
import { creditScoreAbi, creditScoreAddress } from "@/contracts/creditScore";
import { Address } from "viem";

const formSchema = z.object({
  address: z.string().startsWith("0x", { message: "address must start with 0x" }),
  amount: z.any(),
  duration: z.any(),
  numberOfPayments: z.any(),
  interestRate: z.any(),
})

export default function CreatePaymentPlan() {
  const { writeContract, data, status, error } = useWriteContract()

  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      address: "",
      amount: 0,
      duration: 0,
      numberOfPayments: 0,
      interestRate: 0,
    }
  });

  function onSubmit(values: z.infer<typeof formSchema>) {
    console.log(values);

    const months: bigint = BigInt(values.duration) * BigInt(30) * BigInt(24) * BigInt(60) * BigInt(60)
    writeContract({
      abi: creditScoreAbi,
      address: creditScoreAddress,
      functionName: "createPaymentPlan",
      args: [values.address as Address, BigInt(values.amount), months, values.numberOfPayments, BigInt(values.interestRate)],
    })
  }

  if (status === 'error') {
    console.error(error)
  }
  console.log(data);
  console.log(error);


  return (
    <div>

      <Form {...form}>
        <form onSubmit={form.handleSubmit(onSubmit)}>
          <FormField control={form.control} name="address" render={({ field }) => (
            <FormItem>
              <FormLabel>Create Payment Plan</FormLabel>
              <FormControl>
                <Input placeholder="address" {...field} />
              </FormControl>
              <FormMessage />

            </FormItem>
          )}
          />
          <FormField control={form.control} name="amount" render={({ field }) => (
            <FormItem>
              <FormLabel>Loan amount</FormLabel>
              <FormControl>
                <Input placeholder="loan amount" type="number" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
          />
          <FormField control={form.control} name="duration" render={({ field }) => (
            <FormItem>
              <FormLabel>Loan duration in months</FormLabel>
              <FormControl>
                <Input placeholder="loan duration in months" type="number" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
          />

          <FormField control={form.control} name="numberOfPayments" render={({ field }) => (
            <FormItem>
              <FormLabel>Number of installments</FormLabel>
              <FormControl>
                <Input placeholder="Number of installments" type="number" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
          />
          <FormField control={form.control} name="interestRate" render={({ field }) => (
            <FormItem>
              <FormLabel>Interest rate</FormLabel>
              <FormControl>
                <Input placeholder="The interest rate" type="number" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
          />
          <Button type="submit">Submit</Button>

        </form>

      </Form>
      {status === 'success' && <p>Success</p>}
      {status === 'error' && <p>Error</p>}

    </div>

  )
}
