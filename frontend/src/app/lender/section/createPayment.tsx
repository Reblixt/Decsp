"use client"
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod"
import { useForm } from "react-hook-form"
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useWriteContract } from "wagmi";
import { creditScoreAbi, creditScoreAddress } from "@/contracts/creditScore";

const formSchema = z.object({
  amount: z.any(),
  id: z.any(),
})

export default function CreatePayment() {
  const { writeContract, data, status, error } = useWriteContract()

  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      amount: 0,
      id: 0,
    }
  });

  function onSubmit(values: z.infer<typeof formSchema>) {
    writeContract({
      abi: creditScoreAbi,
      address: creditScoreAddress,
      functionName: "payment",
      args: [BigInt(values.amount), BigInt(values.id)],
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
          <FormField control={form.control} name="amount" render={({ field }) => (
            <FormItem>
              <FormLabel>Amount to pay</FormLabel>
              <FormControl>
                <Input placeholder="Amount to pay" type="number" {...field} />
              </FormControl>
              <FormMessage />

            </FormItem>
          )}
          />
          <FormField control={form.control} name="id" render={({ field }) => (
            <FormItem>
              <FormLabel>Payment plan Id</FormLabel>
              <FormControl>
                <Input placeholder="Payment plan Id" type="number" {...field} />
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
