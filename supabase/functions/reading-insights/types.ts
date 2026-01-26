export interface ReadingInsight {
  id: string;
  title: string;
  description: string;
  category: "pattern" | "milestone" | "recommendation" | "reflection";
  relatedBooks: string[];
  generatedAt: string;
}

export interface ReadingInsightResponse {
  success: boolean;
  insights: ReadingInsight[];
  message?: string;
  error?: string;
}
