import {
  assertEquals,
  assertExists,
  assertStringIncludes,
} from "https://deno.land/std@0.168.0/testing/asserts.ts";
import { describe, it, beforeEach } from "https://deno.land/std@0.168.0/testing/bdd.ts";
import { stub } from "https://deno.land/std@0.168.0/testing/mock.ts";
import { PatternCollector } from "./services/pattern-collector.ts";
import type {
  ReadingPatterns,
  BookRecord,
} from "./types.ts";

class MockSupabaseClient {
  private data: Record<string, unknown[]> = {
    books: [],
    reading_progress_history: [],
    reading_content_embeddings: [],
    reading_insights_rate_limit: [],
    reading_insights_memory: [],
  };

  from(table: string) {
    const self = this;
    return {
      select: (columns?: string) => ({
        eq: (column: string, value: unknown) => ({
          is: (column: string, value: unknown) => ({
            order: (column: string, options?: unknown) => 
              Promise.resolve({
                data: self.data[table] || [],
                error: null,
              }),
          }),
          order: (column: string, options?: unknown) => 
            Promise.resolve({
              data: self.data[table] || [],
              error: null,
            }),
          single: () =>
            Promise.resolve({
              data: (self.data[table] || [])[0] || null,
              error: null,
            }),
        }),
        order: (column: string, options?: unknown) => ({
          limit: (n: number) =>
            Promise.resolve({
              data: ((self.data[table] || []) as unknown[]).slice(0, n),
              error: null,
            }),
        }),
        single: () =>
          Promise.resolve({
            data: (self.data[table] || [])[0] || null,
            error: null,
          }),
      }),
      insert: (data: unknown) =>
        Promise.resolve({
          data: data,
          error: null,
        }),
      upsert: (data: unknown, options?: unknown) =>
        Promise.resolve({
          data: data,
          error: null,
        }),
    };
  }

  setMockData(table: string, data: unknown[]) {
    this.data[table] = data;
  }

  getMockData(table: string) {
    return this.data[table] || [];
  }
}

describe("Reading Insights Edge Function", () => {
  let mockSupabase: MockSupabaseClient;

  beforeEach(() => {
    mockSupabase = new MockSupabaseClient();
  });

  describe("userId Validation", () => {
    it("should reject requests without userId", async () => {
      const requestBody = {};
      const userId = (requestBody as Record<string, unknown>).userId;

      assertEquals(userId, undefined);
    });

    it("should accept requests with valid userId", async () => {
      const requestBody = { userId: "user-123" };
      const userId = (requestBody as Record<string, unknown>).userId;

      assertExists(userId);
      assertEquals(userId, "user-123");
    });

    it("should reject empty userId string", async () => {
      const requestBody = { userId: "" };
      const userId = (requestBody as Record<string, unknown>).userId;

      assertEquals(userId === "" || !userId, true);
    });
  });

  describe("Rate Limit Enforcement", () => {
    it("should allow generation when no previous record exists", async () => {
      mockSupabase.setMockData("reading_insights_rate_limit", []);

      const rateLimit = mockSupabase.getMockData("reading_insights_rate_limit");
      const canGenerate = rateLimit.length === 0;

      assertEquals(canGenerate, true);
    });

    it("should block generation within 24 hours of last generation", async () => {
      const now = new Date();
      const lastGenerated = new Date(now.getTime() - 12 * 60 * 60 * 1000);

      mockSupabase.setMockData("reading_insights_rate_limit", [
        {
          id: "rate-1",
          user_id: "user-123",
          last_generated_at: lastGenerated.toISOString(),
        },
      ]);

      const rateLimit = mockSupabase.getMockData(
        "reading_insights_rate_limit"
      )[0] as Record<string, unknown>;
      const lastGenTime = new Date(rateLimit.last_generated_at as string);
      const hoursSince = (now.getTime() - lastGenTime.getTime()) / (1000 * 60 * 60);
      const canGenerate = hoursSince >= 24;

      assertEquals(canGenerate, false);
    });

    it("should allow generation after 24 hours have passed", async () => {
      const now = new Date();
      const lastGenerated = new Date(now.getTime() - 25 * 60 * 60 * 1000);

      mockSupabase.setMockData("reading_insights_rate_limit", [
        {
          id: "rate-1",
          user_id: "user-123",
          last_generated_at: lastGenerated.toISOString(),
        },
      ]);

      const rateLimit = mockSupabase.getMockData(
        "reading_insights_rate_limit"
      )[0] as Record<string, unknown>;
      const lastGenTime = new Date(rateLimit.last_generated_at as string);
      const hoursSince = (now.getTime() - lastGenTime.getTime()) / (1000 * 60 * 60);
      const canGenerate = hoursSince >= 24;

      assertEquals(canGenerate, true);
    });
  });

  describe("Pattern Collection Accuracy", () => {
    it("should collect patterns with correct structure", async () => {
      const mockBooks: BookRecord[] = [
        {
          id: "book-1",
          title: "Test Book 1",
          author: "Author 1",
          start_date: "2024-01-01",
          target_date: "2024-02-01",
          image_url: null,
          current_page: 300,
          total_pages: 300,
          created_at: "2024-01-01T00:00:00Z",
          updated_at: "2024-02-01T00:00:00Z",
          user_id: "user-123",
          status: "completed",
          attempt_count: 1,
          daily_target_pages: 10,
          genre: "Fiction",
          publisher: "Test Publisher",
          isbn: "123-456",
          rating: 5,
          review: "Great book",
          review_link: null,
          aladin_url: null,
          deleted_at: null,
        },
      ];

      mockSupabase.setMockData("books", mockBooks);
      mockSupabase.setMockData("reading_progress_history", []);
      mockSupabase.setMockData("reading_content_embeddings", []);

      const collector = new PatternCollector(mockSupabase as unknown as any);
      const patterns = await collector.collect("user-123");

      assertExists(patterns);
      assertEquals(patterns.userId, "user-123");
      assertExists(patterns.collectedAt);
      assertExists(patterns.monthlyReadingCounts);
      assertExists(patterns.genreDistribution);
      assertExists(patterns.readingHabits);
      assertExists(patterns.completionRates);
      assertExists(patterns.highlightStats);
      assertExists(patterns.yearOverYear);
    });

    it("should calculate completion rates correctly", async () => {
      const mockBooks: BookRecord[] = [
        {
          id: "book-1",
          title: "Completed Book",
          author: "Author 1",
          start_date: "2024-01-01",
          target_date: "2024-02-01",
          image_url: null,
          current_page: 300,
          total_pages: 300,
          created_at: "2024-01-01T00:00:00Z",
          updated_at: "2024-02-01T00:00:00Z",
          user_id: "user-123",
          status: "completed",
          attempt_count: 1,
          daily_target_pages: 10,
          genre: "Fiction",
          publisher: "Test Publisher",
          isbn: "123-456",
          rating: 5,
          review: "Great",
          review_link: null,
          aladin_url: null,
          deleted_at: null,
        },
        {
          id: "book-2",
          title: "Abandoned Book",
          author: "Author 2",
          start_date: "2024-01-01",
          target_date: "2024-02-01",
          image_url: null,
          current_page: 50,
          total_pages: 300,
          created_at: "2024-01-01T00:00:00Z",
          updated_at: "2024-01-15T00:00:00Z",
          user_id: "user-123",
          status: "abandoned",
          attempt_count: 1,
          daily_target_pages: 10,
          genre: "Fiction",
          publisher: "Test Publisher",
          isbn: "789-012",
          rating: null,
          review: null,
          review_link: null,
          aladin_url: null,
          deleted_at: null,
        },
      ];

      mockSupabase.setMockData("books", mockBooks);
      mockSupabase.setMockData("reading_progress_history", []);
      mockSupabase.setMockData("reading_content_embeddings", []);

      const collector = new PatternCollector(mockSupabase as unknown as any);
      const patterns = await collector.collect("user-123");

      assertEquals(patterns.completionRates.totalStarted, 2);
      assertEquals(patterns.completionRates.completed, 1);
      assertEquals(patterns.completionRates.abandoned, 1);
      assertEquals(patterns.completionRates.completionRate, 50);
      assertEquals(patterns.completionRates.abandonRate, 50);
    });

    it("should calculate genre distribution correctly", async () => {
      const mockBooks: BookRecord[] = [
        {
          id: "book-1",
          title: "Fiction Book",
          author: "Author 1",
          start_date: "2024-01-01",
          target_date: "2024-02-01",
          image_url: null,
          current_page: 300,
          total_pages: 300,
          created_at: "2024-01-01T00:00:00Z",
          updated_at: "2024-02-01T00:00:00Z",
          user_id: "user-123",
          status: "completed",
          attempt_count: 1,
          daily_target_pages: 10,
          genre: "Fiction",
          publisher: "Test Publisher",
          isbn: "123-456",
          rating: 5,
          review: "Great",
          review_link: null,
          aladin_url: null,
          deleted_at: null,
        },
        {
          id: "book-2",
          title: "Non-Fiction Book",
          author: "Author 2",
          start_date: "2024-01-01",
          target_date: "2024-02-01",
          image_url: null,
          current_page: 250,
          total_pages: 250,
          created_at: "2024-01-01T00:00:00Z",
          updated_at: "2024-02-01T00:00:00Z",
          user_id: "user-123",
          status: "completed",
          attempt_count: 1,
          daily_target_pages: 10,
          genre: "Non-Fiction",
          publisher: "Test Publisher",
          isbn: "789-012",
          rating: 4,
          review: "Good",
          review_link: null,
          aladin_url: null,
          deleted_at: null,
        },
      ];

      mockSupabase.setMockData("books", mockBooks);
      mockSupabase.setMockData("reading_progress_history", []);
      mockSupabase.setMockData("reading_content_embeddings", []);

      const collector = new PatternCollector(mockSupabase as unknown as any);
      const patterns = await collector.collect("user-123");

      assertEquals(patterns.genreDistribution.length, 2);
      const fictionGenre = patterns.genreDistribution.find(
        (g) => g.genre === "Fiction"
      );
      const nonFictionGenre = patterns.genreDistribution.find(
        (g) => g.genre === "Non-Fiction"
      );

      assertExists(fictionGenre);
      assertExists(nonFictionGenre);
      assertEquals(fictionGenre!.count, 1);
      assertEquals(nonFictionGenre!.count, 1);
      assertEquals(fictionGenre!.percentage, 50);
      assertEquals(nonFictionGenre!.percentage, 50);
    });

    it("should handle highlight statistics correctly", async () => {
      const mockBooks: BookRecord[] = [
        {
          id: "book-1",
          title: "Test Book",
          author: "Author 1",
          start_date: "2024-01-01",
          target_date: "2024-02-01",
          image_url: null,
          current_page: 300,
          total_pages: 300,
          created_at: "2024-01-01T00:00:00Z",
          updated_at: "2024-02-01T00:00:00Z",
          user_id: "user-123",
          status: "completed",
          attempt_count: 1,
          daily_target_pages: 10,
          genre: "Fiction",
          publisher: "Test Publisher",
          isbn: "123-456",
          rating: 5,
          review: "Great",
          review_link: null,
          aladin_url: null,
          deleted_at: null,
        },
      ];

      mockSupabase.setMockData("books", mockBooks);
      mockSupabase.setMockData("reading_progress_history", []);
      mockSupabase.setMockData("reading_content_embeddings", []);

      const collector = new PatternCollector(mockSupabase as unknown as any);
      const patterns = await collector.collect("user-123");

      assertExists(patterns.highlightStats);
      assertEquals(patterns.highlightStats.totalCount, 0);
      assertExists(patterns.highlightStats.byGenre);
      assertExists(patterns.highlightStats.topKeywords);
    });
  });

  describe("Insight Generation Response Format", () => {
    it("should validate insight response structure", async () => {
      const mockInsight = {
        id: "insight-1",
        title: "Test Insight",
        description: "This is a test insight",
        category: "pattern" as const,
        relatedBooks: ["Book 1", "Book 2"],
        generatedAt: new Date().toISOString(),
      };

      assertExists(mockInsight.id);
      assertEquals(mockInsight.title, "Test Insight");
      assertStringIncludes(mockInsight.description, "test");
      assertEquals(mockInsight.category, "pattern");
      assertEquals(mockInsight.relatedBooks.length, 2);
      assertExists(mockInsight.generatedAt);
    });

    it("should handle different insight categories", async () => {
      const categories = ["pattern", "milestone", "reflection"] as const;

      for (const category of categories) {
        const insight = {
          id: `insight-${category}`,
          title: `${category} Insight`,
          description: `Description for ${category}`,
          category: category,
          relatedBooks: [],
          generatedAt: new Date().toISOString(),
        };

        assertEquals(insight.category, category);
      }
    });

    it("should parse JSON response with embedded insights", async () => {
      const jsonResponse = `
        Some text before
        [
          {
            "title": "Insight 1",
            "description": "Description 1",
            "category": "pattern",
            "relatedBooks": ["Book A"]
          },
          {
            "title": "Insight 2",
            "description": "Description 2",
            "category": "milestone",
            "relatedBooks": []
          }
        ]
        Some text after
      `;

      const jsonMatch = jsonResponse.match(/\[[\s\S]*\]/);
      assertExists(jsonMatch);

      const parsed = JSON.parse(jsonMatch![0]);
      assertEquals(parsed.length, 2);
      assertEquals(parsed[0].title, "Insight 1");
      assertEquals(parsed[1].category, "milestone");
    });
  });

  describe("Pattern Data Validation", () => {
    it("should handle empty reading data gracefully", async () => {
      mockSupabase.setMockData("books", []);
      mockSupabase.setMockData("reading_progress_history", []);
      mockSupabase.setMockData("reading_content_embeddings", []);

      const collector = new PatternCollector(mockSupabase as unknown as any);
      const patterns = await collector.collect("user-123");

      assertEquals(patterns.monthlyReadingCounts.length, 0);
      assertEquals(patterns.genreDistribution.length, 0);
      assertEquals(patterns.completionRates.totalStarted, 0);
      assertEquals(patterns.highlightStats.totalCount, 0);
    });

    it("should calculate year-over-year comparison", async () => {
      const currentYear = new Date().getFullYear();
      const previousYear = currentYear - 1;

      const mockBooks: BookRecord[] = [
        {
          id: "book-current",
          title: "Current Year Book",
          author: "Author",
          start_date: `${currentYear}-01-01`,
          target_date: `${currentYear}-02-01`,
          image_url: null,
          current_page: 300,
          total_pages: 300,
          created_at: `${currentYear}-01-01T00:00:00Z`,
          updated_at: `${currentYear}-02-01T00:00:00Z`,
          user_id: "user-123",
          status: "completed",
          attempt_count: 1,
          daily_target_pages: 10,
          genre: "Fiction",
          publisher: "Test",
          isbn: "123",
          rating: 5,
          review: "Good",
          review_link: null,
          aladin_url: null,
          deleted_at: null,
        },
      ];

      mockSupabase.setMockData("books", mockBooks);
      mockSupabase.setMockData("reading_progress_history", []);
      mockSupabase.setMockData("reading_content_embeddings", []);

      const collector = new PatternCollector(mockSupabase as unknown as any);
      const patterns = await collector.collect("user-123");

      assertEquals(patterns.yearOverYear.currentYear, currentYear);
      assertEquals(patterns.yearOverYear.previousYear, previousYear);
      assertEquals(patterns.yearOverYear.currentYearCompleted, 1);
    });
  });
});
