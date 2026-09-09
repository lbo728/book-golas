import type { Locale } from "./common";

export const consumerRoutes = {
  login: (locale: Locale) => `/${locale}/login`,
  signup: (locale: Locale) => `/${locale}/signup`,
  forgotPassword: (locale: Locale) => `/${locale}/forgot-password`,
  app: (locale: Locale) => `/${locale}/app`,
  library: (locale: Locale) => `/${locale}/app/library`,
  stats: (locale: Locale) => `/${locale}/app/stats`,
  calendar: (locale: Locale) => `/${locale}/app/calendar`,
  account: (locale: Locale) => `/${locale}/app/account`,
  newBook: (locale: Locale) => `/${locale}/app/books/new`,
  book: (locale: Locale, bookId: string) => `/${locale}/app/books/${bookId}`,
  recall: (locale: Locale) => `/${locale}/app/recall`,
  authCallback: "/auth/callback",
  authResetPassword: "/auth/reset-password",
} as const;
