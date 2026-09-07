import { notFound } from "next/navigation";
import { isLegalLocale, SupportPageContent } from "@/components/legal/legal-pages";

export default async function LocalizedSupportPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  if (!isLegalLocale(locale)) notFound();

  return <SupportPageContent locale={locale} />;
}
