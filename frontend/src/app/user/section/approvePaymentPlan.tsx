"use client"
import { Form, FormControl, FormDescription, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod"
import { useForm } from "react-hook-form"
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useWriteContract } from "wagmi";
import { creditScoreAbi, creditScoreAddress } from "@/contracts/creditScore";
import { Address } from "viem";

const formSchema = z.object({
  address: z.any(),
})

export default function ApprovePaymentPlan() {
  const { writeContract, data, status, error } = useWriteContract()

  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      address: 0,
    }
  });

  function onSubmit(values: z.infer<typeof formSchema>) {
    writeContract({
      abi: creditScoreAbi,
      address: creditScoreAddress,
      functionName: "approveNewPaymentPlan",
      args: [BigInt(values.address)],
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
              <FormLabel>Approve payment plan</FormLabel>
              <FormControl>
                <Input placeholder="Id to Paymentplan" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
          />
          <Button type="submit">Submit</Button>

        </form>

      </Form>
      {status === 'success' && !error && <p>Success</p>}
      {status === 'error' && <p>Error</p>}

    </div>

  )
}
