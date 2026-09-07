export const consumerLocales = ["ko", "en"] as const;

export type ConsumerLocale = (typeof consumerLocales)[number];

export function isConsumerLocale(value: string): value is ConsumerLocale {
  return consumerLocales.includes(value as ConsumerLocale);
}

export function getConsumerPath(
  locale: ConsumerLocale | string,
  path: string,
): string {
  const normalizedPath = path.startsWith("/") ? path : `/${path}`;
  return `/${locale}${normalizedPath}`;
}

function hasUnsafePathSegments(value: string): boolean {
  if (value.includes("\\")) return true;

  try {
    let currentPath = value.split(/[?#]/, 1)[0];
    let currentCandidate = value;

    for (let depth = 0; depth < 8; depth += 1) {
      const decodedPath = decodeURIComponent(currentPath);
      const decodedCandidate = decodeURIComponent(currentCandidate);

      const pathHasUnsafeSegments = decodedPath
        .split("/")
        .slice(2)
        .some((segment) => segment.length === 0 || segment === "." || segment === "..");
      const candidateHasTraversalSegments = decodedCandidate
        .split("/")
        .slice(2)
        .some((segment) => segment === "." || segment === "..");

      if (pathHasUnsafeSegments || candidateHasTraversalSegments) return true;
      if (decodedPath === currentPath && decodedCandidate === currentCandidate) return false;
      currentPath = decodedPath;
      currentCandidate = decodedCandidate;
    }

    return true;
  } catch {
    return true;
  }
}

export function getSafeNextPath(
  locale: ConsumerLocale | string,
  candidate: string | undefined,
): string {
  const fallback = getConsumerPath(locale, "/home");

  if (!candidate || candidate.startsWith("//") || hasUnsafePathSegments(candidate)) return fallback;
  if (!candidate.startsWith(`/${locale}/`)) return fallback;

  return candidate;
}
