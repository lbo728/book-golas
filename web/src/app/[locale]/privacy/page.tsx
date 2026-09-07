import { notFound } from "next/navigation";
import { isLegalLocale, PrivacyPageContent } from "@/components/legal/legal-pages";

export default async function LocalizedPrivacyPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  if (!isLegalLocale(locale)) notFound();

  return <PrivacyPageContent locale={locale} />;
}
