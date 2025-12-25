"use client";

import { useState, useEffect } from "react";
import { supabase } from "@/lib/supabase";
import type { PushTemplate } from "@/lib/supabase";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";

interface UserWithToken {
  user_id: string;
  email: string;
  token_count: number;
}

export default function TestPushPage() {
  const [templates, setTemplates] = useState<PushTemplate[]>([]);
  const [users, setUsers] = useState<UserWithToken[]>([]);
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [result, setResult] = useState<{ success: boolean; message: string } | null>(null);

  // Form state
  const [selectedUser, setSelectedUser] = useState<string>("");
  const [selectedTemplate, setSelectedTemplate] = useState<string>("custom");
  const [customTitle, setCustomTitle] = useState("테스트 푸시 알림");
  const [customBody, setCustomBody] = useState("이것은 테스트 메시지입니다.");

  useEffect(() => {
    fetchData();
  }, []);

  async function fetchData() {
    setLoading(true);

    // Fetch templates
    const { data: templatesData } = await supabase
      .from("push_templates")
      .select("*")
      .eq("is_active", true)
      .order("priority");

    if (templatesData) {
      setTemplates(templatesData);
    }

    // Fetch users with FCM tokens
    const { data: tokensData } = await supabase
      .from("fcm_tokens")
      .select("user_id, token")
      .eq("notification_enabled", true);

    if (tokensData) {
      // Group by user and count tokens
      const userMap = new Map<string, { user_id: string; token_count: number }>();
      tokensData.forEach((row) => {
        const existing = userMap.get(row.user_id);
        if (existing) {
          existing.token_count++;
        } else {
          userMap.set(row.user_id, { user_id: row.user_id, token_count: 1 });
        }
      });

      // Fetch user emails
      const userIds = Array.from(userMap.keys());
      if (userIds.length > 0) {
        const usersWithEmail: UserWithToken[] = [];
        for (const [userId, data] of userMap) {
          usersWithEmail.push({
            user_id: userId,
            email: userId.slice(0, 8) + "...", // Truncate UUID for display
            token_count: data.token_count,
          });
        }
        setUsers(usersWithEmail);
      }
    }

    setLoading(false);
  }

  async function handleSendTest() {
    if (!selectedUser) {
      setResult({ success: false, message: "사용자를 선택해주세요." });
      return;
    }

    setSending(true);
    setResult(null);

    try {
      const selectedTemplateData = templates.find(t => t.type === selectedTemplate);

      const title = selectedTemplate === "custom"
        ? customTitle
        : selectedTemplateData?.title || customTitle;

      const body = selectedTemplate === "custom"
        ? customBody
        : selectedTemplateData?.body_template || customBody;

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/send-test-push`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY}`,
          },
          body: JSON.stringify({
            userId: selectedUser,
            title,
            body,
            pushType: selectedTemplate === "custom" ? "test" : selectedTemplate,
          }),
        }
      );

      const data = await response.json();

      if (response.ok && data.success) {
        setResult({
          success: true,
          message: `발송 성공! ${data.sentCount}개 디바이스에 전송되었습니다.`
        });
      } else {
        setResult({
          success: false,
          message: data.error || "발송에 실패했습니다."
        });
      }
    } catch (error) {
      setResult({
        success: false,
        message: `에러 발생: ${error instanceof Error ? error.message : "알 수 없는 에러"}`
      });
    } finally {
      setSending(false);
    }
  }

  const selectedTemplateData = templates.find(t => t.type === selectedTemplate);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">테스트 발송</h1>
        <p className="text-gray-500">특정 사용자에게 테스트 푸시 알림을 발송합니다.</p>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        {/* 발송 설정 */}
        <Card>
          <CardHeader>
            <CardTitle>발송 설정</CardTitle>
            <CardDescription>테스트 푸시를 보낼 대상과 내용을 설정하세요.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {/* 사용자 선택 */}
            <div className="space-y-2">
              <Label htmlFor="user">대상 사용자</Label>
              <Select value={selectedUser} onValueChange={setSelectedUser}>
                <SelectTrigger>
                  <SelectValue placeholder="사용자 선택..." />
                </SelectTrigger>
                <SelectContent>
                  {users.map((user) => (
                    <SelectItem key={user.user_id} value={user.user_id}>
                      {user.email} ({user.token_count}개 디바이스)
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              <p className="text-xs text-gray-500">
                알림이 활성화된 사용자만 표시됩니다.
              </p>
            </div>

            {/* 템플릿 선택 */}
            <div className="space-y-2">
              <Label htmlFor="template">메시지 템플릿</Label>
              <Select value={selectedTemplate} onValueChange={setSelectedTemplate}>
                <SelectTrigger>
                  <SelectValue placeholder="템플릿 선택..." />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="custom">커스텀 메시지</SelectItem>
                  {templates.map((template) => (
                    <SelectItem key={template.type} value={template.type}>
                      {template.type} - {template.title}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            {/* 커스텀 메시지 입력 */}
            {selectedTemplate === "custom" && (
              <>
                <div className="space-y-2">
                  <Label htmlFor="title">제목</Label>
                  <Input
                    id="title"
                    value={customTitle}
                    onChange={(e) => setCustomTitle(e.target.value)}
                    placeholder="푸시 알림 제목"
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="body">본문</Label>
                  <Input
                    id="body"
                    value={customBody}
                    onChange={(e) => setCustomBody(e.target.value)}
                    placeholder="푸시 알림 본문"
                  />
                </div>
              </>
            )}

            {/* 발송 버튼 */}
            <Button
              onClick={handleSendTest}
              disabled={sending || !selectedUser}
              className="w-full"
            >
              {sending ? "발송 중..." : "테스트 발송"}
            </Button>

            {/* 결과 메시지 */}
            {result && (
              <div className={`p-3 rounded-md ${
                result.success ? "bg-green-50 text-green-800" : "bg-red-50 text-red-800"
              }`}>
                {result.message}
              </div>
            )}
          </CardContent>
        </Card>

        {/* 미리보기 */}
        <Card>
          <CardHeader>
            <CardTitle>미리보기</CardTitle>
            <CardDescription>발송될 푸시 알림 미리보기</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="bg-gray-900 text-white p-4 rounded-xl shadow-lg max-w-sm">
              <div className="flex items-start gap-3">
                <div className="w-10 h-10 bg-blue-500 rounded-lg flex items-center justify-center text-lg">
                  📚
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className="font-semibold text-sm">Bookgolas</span>
                    <span className="text-xs text-gray-400">now</span>
                  </div>
                  <p className="font-medium text-sm mt-1">
                    {selectedTemplate === "custom"
                      ? customTitle
                      : selectedTemplateData?.title || "제목"}
                  </p>
                  <p className="text-sm text-gray-300 mt-0.5 truncate">
                    {selectedTemplate === "custom"
                      ? customBody
                      : selectedTemplateData?.body_template || "본문"}
                  </p>
                </div>
              </div>
            </div>

            <div className="mt-6 space-y-3">
              <h4 className="font-medium text-sm">발송 정보</h4>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span className="text-gray-500">타입</span>
                  <Badge variant="outline">
                    {selectedTemplate === "custom" ? "test" : selectedTemplate}
                  </Badge>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-500">대상</span>
                  <span>{selectedUser ? users.find(u => u.user_id === selectedUser)?.email : "-"}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-500">디바이스</span>
                  <span>{selectedUser ? users.find(u => u.user_id === selectedUser)?.token_count || 0 : 0}개</span>
                </div>
              </div>
            </div>

            {/* 변수 안내 */}
            {selectedTemplate !== "custom" && selectedTemplateData && (
              <div className="mt-6 p-3 bg-yellow-50 rounded-md">
                <p className="text-xs text-yellow-800">
                  <strong>참고:</strong> 템플릿의 변수({"{days}"}, {"{bookTitle}"} 등)는
                  테스트 발송 시 실제 값으로 치환되지 않습니다.
                </p>
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* 사용자 목록 */}
      <Card>
        <CardHeader>
          <CardTitle>FCM 토큰 보유 사용자</CardTitle>
          <CardDescription>
            총 {users.length}명의 사용자가 푸시 알림을 받을 수 있습니다.
          </CardDescription>
        </CardHeader>
        <CardContent>
          {loading ? (
            <p className="text-gray-500">로딩 중...</p>
          ) : users.length === 0 ? (
            <p className="text-gray-500">FCM 토큰이 등록된 사용자가 없습니다.</p>
          ) : (
            <div className="grid gap-2 md:grid-cols-2 lg:grid-cols-3">
              {users.map((user) => (
                <div
                  key={user.user_id}
                  className={`p-3 border rounded-lg cursor-pointer transition-colors ${
                    selectedUser === user.user_id
                      ? "border-blue-500 bg-blue-50"
                      : "hover:bg-gray-50"
                  }`}
                  onClick={() => setSelectedUser(user.user_id)}
                >
                  <div className="font-mono text-sm">{user.user_id.slice(0, 8)}...</div>
                  <div className="text-xs text-gray-500 mt-1">
                    {user.token_count}개 디바이스
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
