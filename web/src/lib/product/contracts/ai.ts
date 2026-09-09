import { z } from "zod";
import { BookIdSchema, IsoDateSchema, RecordIdSchema } from "./common";

export const recallSourceTypeValues = ["highlight", "note", "photo_ocr"] as const;
export const RecallSourceSchema = z
  .object({
    type: z.enum(recallSourceTypeValues),
    content: z.string(),
    pageNumber: z.number().int().min(1).nullable(),
    sourceId: RecordIdSchema.nullable(),
    createdAt: IsoDateSchema.nullable(),
    bookId: BookIdSchema.nullable(),
    bookTitle: z.string().trim().min(1).max(500).nullable(),
  })
  .strict();

export const RecallSearchResultSchema = z
  .object({
    answer: z.string(),
    sources: z.array(RecallSourceSchema),
    sourcesByBook: z.record(z.string().uuid(), z.array(RecallSourceSchema)).optional(),
  })
  .strict();

export const RecallSearchHistorySchema = z
  .object({
    id: RecordIdSchema,
    query: z.string().trim().min(1).max(500),
    answer: z.string(),
    sources: z.array(RecallSourceSchema),
    createdAt: IsoDateSchema,
  })
  .strict();

export const insightCategoryValues = ["pattern", "milestone", "reflection"] as const;
export const InsightSchema = z
  .object({
    id: RecordIdSchema,
    title: z.string().trim().min(1).max(200),
    description: z.string(),
    category: z.enum(insightCategoryValues),
    relatedBooks: z.array(BookIdSchema),
    generatedAt: IsoDateSchema,
  })
  .strict();

export const BookRecommendationSchema = z
  .object({
    title: z.string().trim().min(1).max(500),
    author: z.string().trim().min(1).max(500),
    reason: z.string().trim().min(1).max(2000),
    keywords: z.array(z.string().trim().min(1).max(80)),
    imageUrl: z.string().trim().min(1).nullable(),
  })
  .strict();

export const RecommendationStatsSchema = z
  .object({
    totalBooksCompleted: z.number().int().min(0),
    averageRating: z.number().min(0).max(5),
    favoriteGenres: z.array(z.string().trim().min(1).max(120)),
    averageCompletionDays: z.number().int().min(0),
    booksAnalyzed: z.number().int().min(0),
  })
  .strict();

export const RecommendationResultSchema = z
  .object({
    success: z.boolean(),
    recommendations: z.array(BookRecommendationSchema),
    stats: RecommendationStatsSchema.nullable(),
    error: z.string().nullable(),
  })
  .strict();

export type RecallSource = z.infer<typeof RecallSourceSchema>;
export type RecallSearchResult = z.infer<typeof RecallSearchResultSchema>;
export type RecallSearchHistory = z.infer<typeof RecallSearchHistorySchema>;
export type Insight = z.infer<typeof InsightSchema>;
export type BookRecommendation = z.infer<typeof BookRecommendationSchema>;
export type RecommendationResult = z.infer<typeof RecommendationResultSchema>;
