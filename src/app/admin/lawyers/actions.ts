"use server";

import { createClient } from "@/lib/supabase/server";
import { promoteToLawyerSchema } from "@/lib/validation/admin";
import { revalidatePath } from "next/cache";

export type PromoteToLawyerState = { error: string | null; success: boolean };

export async function promoteToLawyerAction(
  _prevState: PromoteToLawyerState,
  formData: FormData
): Promise<PromoteToLawyerState> {
  const supabase = createClient();

  const {
    data: { user }
  } = await supabase.auth.getUser();
  if (!user) return { error: "You must be signed in.", success: false };

  // Double-check the caller is actually an admin — RLS also enforces this
  // at the database level, but we fail fast here with a clear message.
  const { data: callerProfile } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.id)
    .single();
  if (callerProfile?.role !== "admin") {
    return { error: "Only admins can change roles.", success: false };
  }

  const parsed = promoteToLawyerSchema.safeParse({ email: formData.get("email") });
  if (!parsed.success) {
    return { error: parsed.error.issues[0]?.message ?? "Invalid input.", success: false };
  }

  const { data: targetProfile, error: findError } = await supabase
    .from("profiles")
    .select("id, role")
    .eq("email", parsed.data.email)
    .single();

  if (findError || !targetProfile) {
    return { error: "No account found with that email.", success: false };
  }
  if (targetProfile.role === "lawyer" || targetProfile.role === "admin") {
    return { error: "This account is already a lawyer or admin.", success: false };
  }

  const { error: updateError } = await supabase
    .from("profiles")
    .update({ role: "lawyer" })
    .eq("id", targetProfile.id);

  if (updateError) {
    return { error: updateError.message, success: false };
  }

  revalidatePath("/admin/lawyers");
  return { error: null, success: true };
}
