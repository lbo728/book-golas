export interface BookReadingAnalytics {
  bookId: string;
  title: string;
  author: string;
  genre: string | null;
  daysToComplete: number;
  averagePagesPerDay: number;
  highlightCount: number;
  noteCount: number;
  photoOcrCount: number;
  totalEngagement: number;
  rating: number | null;
  hasReview: boolean;
  dailyGoalAchievementRate: number;
  attemptCount: number;
  completed: boolean;
}

export interface UserReadingProfile {
  userId: string;
  books: BookReadingAnalytics[];
  stats: {
    totalBooksCompleted: number;
    averageRating: number;
    favoriteGenres: Array<{ genre: string; count: number }>;
    averageCompletionDays: number;
    highEngagementBookCount: number;
  };
  interests: {
    topHighlights: Array<{ content: string; bookTitle: string }>;
    keywords: string[];
  };
}

export interface Recommendation {
  title: string;
  author: string;
  reason: string;
  keywords: string[];
}

export interface RecommendationResponse {
  success: boolean;
  recommendations: Recommendation[];
  profile: {
    stats: UserReadingProfile["stats"];
    booksAnalyzed: number;
  };
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
