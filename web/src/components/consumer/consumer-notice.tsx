import type { ReactNode } from "react";
import {
  ConsumerCard,
  ConsumerEmptyState,
  ConsumerErrorState,
} from "@/components/consumer/blab-primitives";

type ConsumerNoticeProps = {
  title: string;
  description: string;
  action?: ReactNode;
  tone?: "empty" | "error";
};

export function ConsumerNotice({
  title,
  description,
  action,
  tone = "empty",
}: ConsumerNoticeProps) {
  const State = tone === "error" ? ConsumerErrorState : ConsumerEmptyState;

  return (
    <ConsumerCard
      className="text-center"
      role="status"
    >
      <State title={title} message={description} icon="📚" />
      {action ? <div className="mt-6 flex justify-center">{action}</div> : null}
    </ConsumerCard>
  );
}
