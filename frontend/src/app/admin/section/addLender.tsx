
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
  address: z.string().startsWith("0x", { message: "address must start with 0x" }),
})

export default function AddLender() {
  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      address: "",
    }
  });

  const { writeContract, data, status, error } = useWriteContract()

  function onSubmit(values: z.infer<typeof formSchema>) {
    writeContract({
      abi: creditScoreAbi,
      address: creditScoreAddress,
      functionName: "addLender",
      args: [values.address as Address],
    })
  }

  if (status === 'error') {
    console.error(error)
  }
  console.log(data);

  return (
    <div className="border-black rounded border-solid border p-2 mb-2">

      <Form {...form}>
        <form onSubmit={form.handleSubmit(onSubmit)}>
          <FormField control={form.control} name="address" render={({ field }) => (
            <FormItem>
              <FormLabel>Add new Lender</FormLabel>
              <FormControl>
                <Input placeholder="This is the address of the Lender" {...field} />
              </FormControl>
              {/* <FormDescription> */}
              {/*   This is the address of the Lender */}
              {/* </FormDescription> */}
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
