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

export interface MonthlyReadingCount {
  month: string;
  count: number;
}

export interface GenreDistribution {
  genre: string;
  count: number;
  percentage: number;
}

export interface ReadingHabitPattern {
  hourDistribution: Record<number, number>;
  dayOfWeekDistribution: Record<number, number>;
  peakReadingHour: number | null;
  peakReadingDay: number | null;
}

export interface CompletionRates {
  totalStarted: number;
  completed: number;
  abandoned: number;
  inProgress: number;
  completionRate: number;
  abandonRate: number;
  retrySuccessRate: number;
}

export interface HighlightStats {
  totalCount: number;
  byGenre: Record<string, number>;
  topKeywords: string[];
}

export interface YearOverYearComparison {
  currentYear: number;
  previousYear: number;
  currentYearCompleted: number;
  previousYearCompleted: number;
  changePercentage: number;
  currentYearHighlights: number;
  previousYearHighlights: number;
}

export interface ReadingPatterns {
  userId: string;
  collectedAt: string;
  monthlyReadingCounts: MonthlyReadingCount[];
  genreDistribution: GenreDistribution[];
  readingHabits: ReadingHabitPattern;
  completionRates: CompletionRates;
  highlightStats: HighlightStats;
  yearOverYear: YearOverYearComparison;
}

export interface BookRecord {
  id: string;
  title: string;
  author: string | null;
  start_date: string;
  target_date: string;
  image_url: string | null;
  current_page: number;
  total_pages: number;
  created_at: string;
  updated_at: string;
  user_id: string;
  status: string;
  attempt_count: number;
  daily_target_pages: number | null;
  genre: string | null;
  publisher: string | null;
  isbn: string | null;
  rating: number | null;
  review: string | null;
  review_link: string | null;
  aladin_url: string | null;
  deleted_at: string | null;
}

export interface ProgressRecord {
  id: string;
  user_id: string;
  book_id: string;
  page: number;
  previous_page: number;
  created_at: string;
}

export interface EmbeddingRecord {
  id: string;
  user_id: string;
  book_id: string;
  content_type: "highlight" | "note" | "photo_ocr";
  content_text: string;
  page_number: number | null;
  source_id: string | null;
}
