import { notFound } from "next/navigation";
import { isLegalLocale, TermsPageContent } from "@/components/legal/legal-pages";

export default async function LocalizedTermsPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  if (!isLegalLocale(locale)) notFound();

  return <TermsPageContent locale={locale} />;
}
