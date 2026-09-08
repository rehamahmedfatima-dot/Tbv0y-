import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import { Card, CardHeader, CardTitle } from "@/components/ui/card";
import { PromoteToLawyerForm } from "@/components/dashboard/PromoteToLawyerForm";
import { getLocale } from "@/lib/i18n/locale";
import { getDictionary } from "@/lib/i18n/translations";

export const dynamic = "force-dynamic";

export default async function AdminLawyersPage() {
  const locale = getLocale();
  const t = getDictionary(locale);
  const supabase = createClient();

  const {
    data: { user }
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: myProfile } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.id)
    .single();
  if (myProfile?.role !== "admin") redirect("/client/dashboard");

  const { data: lawyers } = await supabase
    .from("profiles")
    .select("id, full_name, email, created_at")
    .eq("role", "lawyer")
    .order("full_name");

  return (
    <main className="mx-auto max-w-4xl px-6 py-10">
      <h1 className="mb-6 text-2xl font-semibold text-navy dark:text-white">
        {t.adminLawyers.title}
      </h1>

      <Card>
        <CardHeader>
          <CardTitle>{t.adminLawyers.promoteTitle}</CardTitle>
        </CardHeader>
        <p className="mb-4 text-sm text-black/60 dark:text-white/60">
          {t.adminLawyers.promoteDesc}
        </p>
        <PromoteToLawyerForm t={t.adminLawyers} />
      </Card>

      <section className="mt-8">
        <h2 className="mb-4 text-lg font-semibold text-navy dark:text-white">
          {t.adminLawyers.currentLawyers} ({lawyers?.length ?? 0})
        </h2>
        {lawyers && lawyers.length > 0 ? (
          <div className="space-y-2">
            {lawyers.map((l) => (
              <Card key={l.id} className="flex items-center justify-between py-3">
                <div>
                  <p className="font-medium text-navy dark:text-white">{l.full_name}</p>
                  <p className="text-xs text-black/50 dark:text-white/50">{l.email}</p>
                </div>
                <span className="text-xs text-black/40 dark:text-white/40">
                  {t.adminLawyers.joined}{" "}
                  {new Date(l.created_at).toLocaleDateString(locale === "ar" ? "ar-EG" : "en-US")}
                </span>
              </Card>
            ))}
          </div>
        ) : (
          <Card>
            <p className="text-sm text-black/60 dark:text-white/60">
              {t.adminLawyers.noLawyersYet}
            </p>
          </Card>
        )}
      </section>
    </main>
  );
}
