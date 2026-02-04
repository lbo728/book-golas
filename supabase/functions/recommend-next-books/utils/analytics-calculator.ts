import type { BookReadingAnalytics, ProgressRecord } from "../types.ts";

export function calculateDailyGoalAchievementRate(
  dailyTargetPages: number | null,
  progressRecords: ProgressRecord[]
): number {
  if (!dailyTargetPages || !progressRecords || progressRecords.length === 0) {
    return 100;
  }

  const dailyAchievements = progressRecords.map((record, idx) => {
    if (idx === 0) return 100;
    const pagesRead = record.page - progressRecords[idx - 1].page;
    return Math.min((pagesRead / dailyTargetPages) * 100, 150);
  });

  return Math.round(
    dailyAchievements.reduce((sum, v) => sum + v, 0) / dailyAchievements.length
  );
}

export function calculateAggregateStats(books: BookReadingAnalytics[]) {
  const totalCompleted = books.length;

  const booksWithRating = books.filter((b) => b.rating !== null);
  const avgRating =
    booksWithRating.length > 0
      ? booksWithRating.reduce((sum, b) => sum + (b.rating || 0), 0) /
        booksWithRating.length
      : 0;

  const genreCounts = books
    .filter((b) => b.genre)
    .reduce((acc, b) => {
      const genre = b.genre!;
      acc[genre] = (acc[genre] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);

  const favoriteGenres = Object.entries(genreCounts)
    .map(([genre, count]) => ({ genre, count }))
    .sort((a, b) => b.count - a.count)
    .slice(0, 3);

  const avgCompletionDays =
    totalCompleted > 0
      ? Math.round(
          books.reduce((sum, b) => sum + b.daysToComplete, 0) / totalCompleted
        )
      : 0;

  const highEngagementBookCount = books.filter(
    (b) => b.totalEngagement >= 10
  ).length;

  return {
    totalBooksCompleted: totalCompleted,
    averageRating: Math.round(avgRating * 10) / 10,
    favoriteGenres,
    averageCompletionDays: avgCompletionDays,
    highEngagementBookCount,
  };
}
