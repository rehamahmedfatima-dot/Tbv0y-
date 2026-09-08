"use client";

import { useFormState, useFormStatus } from "react-dom";
import { promoteToLawyerAction, type PromoteToLawyerState } from "@/app/admin/lawyers/actions";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import type { AdminLawyersDictionary } from "@/lib/i18n/translations";

const initialState: PromoteToLawyerState = { error: null, success: false };

function SubmitButton({ label }: { label: string }) {
  const { pending } = useFormStatus();
  return (
    <Button type="submit" loading={pending}>
      {label}
    </Button>
  );
}

export function PromoteToLawyerForm({ t }: { t: AdminLawyersDictionary }) {
  const [state, formAction] = useFormState(promoteToLawyerAction, initialState);

  return (
    <form action={formAction} className="flex flex-wrap items-end gap-3">
      <div className="flex-1 min-w-[220px]">
        <label className="mb-1 block text-sm font-medium">{t.clientEmail}</label>
        <Input name="email" type="email" placeholder="client@example.com" required />
      </div>
      <SubmitButton label={t.makeLawyer} />
      {state.error && <p className="w-full text-sm text-red-600">{state.error}</p>}
      {state.success && (
        <p className="w-full text-sm text-emerald">Account promoted to lawyer.</p>
      )}
    </form>
  );
}
