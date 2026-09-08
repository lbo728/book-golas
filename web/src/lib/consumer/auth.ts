export type AuthMode = "sign-in" | "sign-up" | "reset-password";

type AuthResponse = {
  error: { message: string } | null;
};

export type PasswordAuthClient = {
  signInWithPassword: (credentials: {
    email: string;
    password: string;
  }) => Promise<AuthResponse>;
};

export type SignOutAuthClient = {
  signOut: () => Promise<AuthResponse>;
};

export function getPasswordMinLength(
  mode: AuthMode,
  isRecovery: boolean,
): 8 | undefined {
  if (mode === "sign-in") return undefined;
  if (mode === "sign-up") return 8;
  return isRecovery ? 8 : undefined;
}

export type PasswordValidationError = "short" | "mismatch";

export function getPasswordValidationError(
  mode: AuthMode,
  isRecovery: boolean,
  password: string,
  confirmation: string,
): PasswordValidationError | null {
  const minimum = getPasswordMinLength(mode, isRecovery);
  if (minimum !== undefined && password.length < minimum) return "short";
  if (mode === "reset-password" && isRecovery && minimum !== undefined && confirmation.length < minimum) {
    return "short";
  }
  if (mode === "reset-password" && isRecovery && password !== confirmation) return "mismatch";
  return null;
}

export function signInWithPassword(
  auth: PasswordAuthClient,
  email: string,
  password: string,
) {
  return auth.signInWithPassword({ email, password });
}

export async function signOutUser(auth: SignOutAuthClient): Promise<boolean> {
  try {
    const { error } = await auth.signOut();
    return !error;
  } catch {
    return false;
  }
}
