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
})

export default function ApproveLender({ className }: { className?: string }) {
  const { writeContract, data, status, error } = useWriteContract()

  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      address: "",
    }
  });

  function onSubmit(values: z.infer<typeof formSchema>) {
    writeContract({
      abi: creditScoreAbi,
      address: creditScoreAddress,
      functionName: "approveLender",
      args: [values.address as Address],
    })
  }

  if (status === 'error') {
    console.error(error)
  }
  console.log(data);
  console.log(error);


  return (
    <div className={className}>

      <Form {...form}>
        <form onSubmit={form.handleSubmit(onSubmit)}>
          <FormField control={form.control} name="address" render={({ field }) => (
            <FormItem>
              <FormLabel>Approve Lender</FormLabel>
              <FormControl>
                <Input placeholder="Address to Lender" {...field} />
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
