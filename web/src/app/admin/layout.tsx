"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { cn } from "@/lib/utils";
import { supabase } from "@/lib/supabase";
import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";

const navItems = [
  { href: "/admin", label: "대시보드", icon: "📊" },
  { href: "/admin/push-templates", label: "푸시 템플릿", icon: "📝" },
  { href: "/admin/push-logs", label: "발송 로그", icon: "📋" },
  { href: "/admin/test-push", label: "테스트 발송", icon: "🚀" },
];

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const router = useRouter();
  const [userEmail, setUserEmail] = useState<string | null>(null);

  useEffect(() => {
    async function getUser() {
      const { data: { user } } = await supabase.auth.getUser();
      setUserEmail(user?.email || null);
    }
    getUser();
  }, []);

  async function handleLogout() {
    await supabase.auth.signOut();
    router.push("/admin/login");
    router.refresh();
  }

  if (pathname === "/admin/login") {
    return <>{children}</>;
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            <div className="flex">
              <div className="flex-shrink-0 flex items-center">
                <span className="text-xl font-bold">📚 Bookgolas Admin</span>
              </div>
              <div className="hidden sm:ml-8 sm:flex sm:space-x-4">
                {navItems.map((item) => (
                  <Link
                    key={item.href}
                    href={item.href}
                    className={cn(
                      "inline-flex items-center px-3 py-2 text-sm font-medium rounded-md",
                      pathname === item.href
                        ? "bg-gray-100 text-gray-900"
                        : "text-gray-500 hover:text-gray-700 hover:bg-gray-50"
                    )}
                  >
                    <span className="mr-2">{item.icon}</span>
                    {item.label}
                  </Link>
                ))}
              </div>
            </div>
            <div className="flex items-center gap-4">
              {userEmail && (
                <span className="text-sm text-gray-500">{userEmail}</span>
              )}
              <Button variant="outline" size="sm" onClick={handleLogout}>
                로그아웃
              </Button>
            </div>
          </div>
        </div>
      </nav>

      <main className="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
        {children}
      </main>
    </div>
  );
}
