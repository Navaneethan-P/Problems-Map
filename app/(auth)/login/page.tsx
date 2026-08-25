"use client";

import { useTransition } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { LoginSchema, type LoginInput } from "@/schemas";
import { login } from "../actions";
import { toast } from "sonner";
import Link from "next/link";
import { MapPin } from "lucide-react";

import { Button } from "@/components/ui/button";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";

export default function LoginPage() {
  const [isPending, startTransition] = useTransition();

  const form = useForm<LoginInput>({
    resolver: zodResolver(LoginSchema),
    defaultValues: {
      email: "",
      password: "",
    },
  });

  function onSubmit(data: LoginInput) {
    startTransition(async () => {
      const result = await login(data);
      if (result?.error) {
        toast.error(result.error);
      } else {
        toast.success("Successfully logged in");
      }
    });
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-50 p-4">
      <div className="w-full max-w-md space-y-8">
        <div className="flex flex-col items-center justify-center text-center">
          <div className="bg-brand-500 p-3 rounded-2xl mb-4 text-white">
            <MapPin className="w-8 h-8" />
          </div>
          <h1 className="text-3xl font-bold tracking-tight text-slate-900">
            Problems Map
          </h1>
          <p className="text-slate-500 mt-2">
            Civic Issue Reporting & Accountability
          </p>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Welcome back</CardTitle>
            <CardDescription>
              Sign in to your account to continue
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Form {...form}>
              <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
                <FormField
                  control={form.control}
                  name="email"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Email</FormLabel>
                      <FormControl>
                        <Input
                          placeholder="name@example.com"
                          type="email"
                          disabled={isPending}
                          {...field}
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="password"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Password</FormLabel>
                      <FormControl>
                        <Input
                          placeholder="••••••••"
                          type="password"
                          disabled={isPending}
                          {...field}
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <Button type="submit" className="w-full" disabled={isPending}>
                  {isPending ? "Signing in..." : "Sign in"}
                </Button>
              </form>
            </Form>
          </CardContent>
          <CardFooter className="flex flex-col space-y-4">
            <div className="text-sm text-center text-slate-500">
              Don't have an account?{" "}
              <Link
                href="/register"
                className="font-semibold text-brand-600 hover:text-brand-500 transition-colors"
              >
                Sign up
              </Link>
            </div>
            
            {/* Demo credentials helper */}
            {process.env.NEXT_PUBLIC_DEMO_MODE === "true" && (
              <div className="w-full mt-4 p-4 bg-slate-100 rounded-lg text-xs space-y-2 border">
                <p className="font-bold text-slate-700">Demo Accounts:</p>
                <div className="grid grid-cols-2 gap-2 text-slate-600">
                  <div>
                    <span className="font-semibold">Citizen:</span><br/>
                    citizen@demo.com<br/>password123
                  </div>
                  <div>
                    <span className="font-semibold">Officer:</span><br/>
                    officer@demo.com<br/>password123
                  </div>
                </div>
              </div>
            )}
          </CardFooter>
        </Card>
      </div>
    </div>
  );
}
