import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import { Card } from "@/components/ui/card";
import { LinkButton } from "@/components/ui/link-button";
import { getLocale } from "@/lib/i18n/locale";
import { getDictionary } from "@/lib/i18n/translations";

export const dynamic = "force-dynamic";

export default async function AdminDashboardPage() {
  const locale = getLocale();
  const t = getDictionary(locale);
  const supabase = createClient();

  const {
    data: { user }
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: myProfile } = await supabase
    .from("profiles")
    .select("role, full_name")
    .eq("id", user.id)
    .single();

  if (myProfile?.role !== "admin") {
    redirect("/client/dashboard");
  }

  const [
    { count: lawyerCount },
    { count: clientCount },
    { count: caseCount },
    { count: openCaseCount },
    { count: appointmentCount },
    { data: recentCases }
  ] = await Promise.all([
    supabase.from("profiles").select("id", { count: "exact", head: true }).eq("role", "lawyer"),
    supabase.from("profiles").select("id", { count: "exact", head: true }).eq("role", "client"),
    supabase.from("cases").select("id", { count: "exact", head: true }),
    supabase.from("cases").select("id", { count: "exact", head: true }).neq("status", "closed"),
    supabase.from("appointments").select("id", { count: "exact", head: true }),
    supabase
      .from("cases")
      .select("id, case_number, title, status, lawyer_id, client_id")
      .order("created_at", { ascending: false })
      .limit(10)
  ]);

  return (
    <main className="mx-auto max-w-6xl px-6 py-10">
      <h1 className="text-2xl font-semibold text-navy dark:text-white">
        {t.adminDashboard.title} — {myProfile.full_name}
      </h1>
      <p className="mt-1 text-sm text-black/60 dark:text-white/60">{t.adminDashboard.subtitle}</p>

      <section className="mt-8 grid grid-cols-2 gap-4 md:grid-cols-5">
        <Card className="text-center">
          <p className="text-2xl font-bold text-navy dark:text-white">{lawyerCount ?? 0}</p>
          <p className="mt-1 text-xs text-black/60 dark:text-white/60">
            {t.adminDashboard.lawyers}
          </p>
        </Card>
        <Card className="text-center">
          <p className="text-2xl font-bold text-navy dark:text-white">{clientCount ?? 0}</p>
          <p className="mt-1 text-xs text-black/60 dark:text-white/60">
            {t.adminDashboard.clients}
          </p>
        </Card>
        <Card className="text-center">
          <p className="text-2xl font-bold text-gold">{openCaseCount ?? 0}</p>
          <p className="mt-1 text-xs text-black/60 dark:text-white/60">
            {t.adminDashboard.openCases}
          </p>
        </Card>
        <Card className="text-center">
          <p className="text-2xl font-bold text-emerald">{caseCount ?? 0}</p>
          <p className="mt-1 text-xs text-black/60 dark:text-white/60">
            {t.adminDashboard.totalCases}
          </p>
        </Card>
        <Card className="text-center">
          <p className="text-2xl font-bold text-navy dark:text-white">
            {appointmentCount ?? 0}
          </p>
          <p className="mt-1 text-xs text-black/60 dark:text-white/60">
            {t.adminDashboard.appointments}
          </p>
        </Card>
      </section>

      <section className="mt-10 flex flex-wrap gap-4">
        <LinkButton href="/admin/lawyers" variant="secondary">
          {t.adminDashboard.manageLawyers}
        </LinkButton>
        <LinkButton href="/admin/clients" variant="ghost" className="border border-black/10 dark:border-white/10">
          {t.adminDashboard.viewClients}
        </LinkButton>
      </section>

      <section className="mt-10">
        <h2 className="mb-4 text-lg font-semibold text-navy dark:text-white">
          {t.adminDashboard.recentCasesTitle}
        </h2>
        {recentCases && recentCases.length > 0 ? (
          <div className="space-y-2">
            {recentCases.map((c) => (
              <Card key={c.id} className="flex items-center justify-between py-3">
                <div>
                  <p className="font-medium text-navy dark:text-white">{c.title}</p>
                  <p className="text-xs text-black/50 dark:text-white/50">#{c.case_number}</p>
                </div>
                <span className="rounded-full bg-navy/5 px-3 py-1 text-xs font-medium text-navy dark:bg-white/10 dark:text-white">
                  {t.status[c.status]}
                </span>
              </Card>
            ))}
          </div>
        ) : (
          <Card>
            <p className="text-sm text-black/60 dark:text-white/60">
              {t.adminDashboard.noCasesYet}
            </p>
          </Card>
        )}
      </section>
    </main>
  );
}
