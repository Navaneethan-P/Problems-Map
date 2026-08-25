"use server";

import { createClient } from "@/lib/supabase/server";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { LoginSchema, RegisterSchema } from "@/schemas";
import type { LoginInput, RegisterInput } from "@/schemas";

export async function login(data: LoginInput) {
  const result = LoginSchema.safeParse(data);
  if (!result.success) {
    return { error: "Invalid input data" };
  }

  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithPassword({
    email: result.data.email,
    password: result.data.password,
  });

  if (error) {
    return { error: error.message };
  }

  revalidatePath("/", "layout");
  redirect("/citizen/dashboard");
}

export async function register(data: RegisterInput) {
  const result = RegisterSchema.safeParse(data);
  if (!result.success) {
    return { error: "Invalid input data" };
  }

  const supabase = await createClient();

  // Create the user in Auth
  const { data: authData, error: authError } = await supabase.auth.signUp({
    email: result.data.email,
    password: result.data.password,
    options: {
      data: {
        full_name: result.data.full_name,
      },
    },
  });

  if (authError) {
    return { error: authError.message };
  }

  if (authData.user) {
    // Check if we need to insert profile explicitly or if trigger does it
    // Usually Supabase handles this via trigger, but we'll do an explicit update just in case
    await supabase
      .from("profiles")
      .update({ full_name: result.data.full_name })
      .eq("id", authData.user.id);
  }

  revalidatePath("/", "layout");
  redirect("/citizen/dashboard");
}

export async function logout() {
  const supabase = await createClient();
  await supabase.auth.signOut();
  revalidatePath("/", "layout");
  redirect("/login");
}
