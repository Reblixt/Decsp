
"use client"
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod"
import { useForm } from "react-hook-form"
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useReadContract } from "wagmi";
import { creditScoreAbi, creditScoreAddress } from "@/contracts/creditScore";
import { Address, keccak256, toHex } from "viem";
import { useEffect, useState } from "react";

const formSchema = z.object({
  address: z.string().startsWith("0x", { message: "address must start with 0x" }),
})

export default function CheckLender() {
  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      address: ""
    }
  });

  const [address, setAddress] = useState<Address>("0x4AD84f7014B7b44F723F284a85B1662337971439");
  const [hasRoleLender, setHasRoleLender] = useState<boolean>(false);

  // const account = useAccount();

  const role = keccak256(toHex("LENDER_ROLE"))

  const { data: hasRole, status, error, refetch } = useReadContract({
    address: creditScoreAddress,
    abi: creditScoreAbi,
    functionName: "hasRole",
    args: [role, address as Address],
  })

  console.log("address", address);

  console.log("hasRoleLender", hasRole);



  function onSubmit(values: z.infer<typeof formSchema>) {
    setAddress(values.address as Address);
    refetch();
  }

  if (status === 'error') {
    console.error(error)
  }

  useEffect(() => {
    if (hasRole == true) {
      setHasRoleLender(true);
    } else {
      setHasRoleLender(false);
    }
  }, [hasRole])


  return (
    <div className="border-black rounded border-solid border p-2 mb-2">

      <Form {...form}>
        <form onSubmit={form.handleSubmit(onSubmit)}>
          <FormField control={form.control} name="address" render={({ field }) => (
            <FormItem>
              <FormLabel>Check if address have Lender Role</FormLabel>
              <FormControl>
                <Input placeholder="Address of the lender to check" {...field} />
              </FormControl>
              {/* <FormDescription> */}
              {/* </FormDescription> */}
              <FormMessage />

            </FormItem>
          )}
          />
          {hasRoleLender && <p className="bg-green-400">Address have Lender Role</p>}
          <Button type="submit">Submit</Button>

        </form>

      </Form>


    </div>

  )
}
