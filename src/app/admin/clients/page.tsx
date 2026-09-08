import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import { Card } from "@/components/ui/card";
import { getLocale } from "@/lib/i18n/locale";
import { getDictionary } from "@/lib/i18n/translations";

export const dynamic = "force-dynamic";

export default async function AdminClientsPage() {
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

  const { data: clients } = await supabase
    .from("profiles")
    .select("id, full_name, email, created_at")
    .eq("role", "client")
    .order("created_at", { ascending: false });

  const { data: caseCounts } = await supabase.from("cases").select("client_id");
  const countByClient = new Map<string, number>();
  for (const row of caseCounts ?? []) {
    countByClient.set(row.client_id, (countByClient.get(row.client_id) ?? 0) + 1);
  }

  return (
    <main className="mx-auto max-w-4xl px-6 py-10">
      <h1 className="mb-6 text-2xl font-semibold text-navy dark:text-white">
        {t.adminClients.title} ({clients?.length ?? 0})
      </h1>

      {clients && clients.length > 0 ? (
        <div className="space-y-2">
          {clients.map((c) => (
            <Card key={c.id} className="flex items-center justify-between py-3">
              <div>
                <p className="font-medium text-navy dark:text-white">{c.full_name}</p>
                <p className="text-xs text-black/50 dark:text-white/50">{c.email}</p>
              </div>
              <div className="text-right">
                <p className="text-sm font-medium text-navy dark:text-white">
                  {countByClient.get(c.id) ?? 0} {t.adminClients.casesCount}
                </p>
                <p className="text-xs text-black/40 dark:text-white/40">
                  {t.adminClients.joined}{" "}
                  {new Date(c.created_at).toLocaleDateString(locale === "ar" ? "ar-EG" : "en-US")}
                </p>
              </div>
            </Card>
          ))}
        </div>
      ) : (
        <Card>
          <p className="text-sm text-black/60 dark:text-white/60">
            {t.adminClients.noClientsYet}
          </p>
        </Card>
      )}
    </main>
  );
}
