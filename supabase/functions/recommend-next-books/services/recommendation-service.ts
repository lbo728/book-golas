import { ChatOpenAI } from "@langchain/openai";
import { PromptTemplate } from "@langchain/core/prompts";
import type {
  UserReadingProfile,
  Recommendation,
  BookReadingAnalytics,
} from "../types.ts";
import { config } from "../config.ts";

export class RecommendationService {
  private llm: ChatOpenAI;
  private promptTemplate: PromptTemplate;

  constructor() {
    this.llm = new ChatOpenAI({
      openAIApiKey: config.openai.apiKey,
      modelName: config.openai.model,
      temperature: config.openai.temperature,
    });

    this.promptTemplate = PromptTemplate.fromTemplate(`
당신은 독서 추천 전문가입니다. 사용자의 **책별 세부 독서 패턴**을 분석하여 다음 읽을 책 {recommendCount}권을 추천해주세요.

## 📊 사용자 프로필
- 완독한 책: {totalBooks}권
- 평균 별점: {avgRating}/5
- 선호 장르: {favoriteGenres}
- 평균 완독 소요: {avgDays}일
- 높은 몰입도 책: {highEngagement}권

## 📚 최근 완독한 책 상세 분석
{booksDetail}

## 💡 사용자가 자주 하이라이트한 내용
{highlightsContext}

## 🎯 자주 등장하는 키워드
{keywords}

## ✅ 추천 기준
1. 장르 선호도: {favoriteGenres}
2. 독서 속도: {avgDays}일 내외
3. 참여도 패턴: 하이라이트/메모가 많았던 책 스타일
4. 일일 목표 달성률 기반 난이도 조절
5. attemptCount=1인 책의 특성 분석
6. 하이라이트 키워드 기반 주제 연관성

## 📤 출력 형식 (JSON만)
[
  {{"title": "책 제목", "author": "저자명", "reason": "추천 이유 (2-3문장)"}},
  ...
]

**중요**: 실제 존재하는 한국 도서만 추천. JSON만 출력.
    `);
  }

  async generate(profile: UserReadingProfile): Promise<Recommendation[]> {
    const booksDetail = this.formatBooksDetail(profile.books);
    const highlightsContext = this.formatHighlights(
      profile.interests.topHighlights
    );

    const formattedPrompt = await this.promptTemplate.format({
      recommendCount: config.recommendation.count,
      totalBooks: profile.stats.totalBooksCompleted,
      avgRating: profile.stats.averageRating,
      favoriteGenres:
        profile.stats.favoriteGenres.map((g) => g.genre).join(", ") || "다양",
      avgDays: profile.stats.averageCompletionDays,
      highEngagement: profile.stats.highEngagementBookCount,
      booksDetail,
      highlightsContext: highlightsContext || "(없음)",
      keywords: profile.interests.keywords.join(", ") || "(없음)",
    });

    const response = await this.llm.invoke(formattedPrompt);
    return this.parseResponse(response.content as string);
  }

  private formatBooksDetail(books: BookReadingAnalytics[]): string {
    return books
      .slice(0, config.recommendation.maxBooksToAnalyze)
      .map(
        (b, idx) => `
${idx + 1}. "${b.title}" (${b.author})
   - 장르: ${b.genre || "미분류"}
   - 완독: ${b.daysToComplete}일 (평균 ${b.averagePagesPerDay}p/일)
   - 참여도: 하이라이트 ${b.highlightCount}, 메모 ${b.noteCount}
   - 평점: ${b.rating ? `${b.rating}/5` : "없음"}
   - 일일 목표 달성률: ${b.dailyGoalAchievementRate}%
   - 시도: ${b.attemptCount}번 ${b.attemptCount === 1 ? "(단번 완독)" : ""}
        `
      )
      .join("\n");
  }

  private formatHighlights(
    highlights: Array<{ content: string; bookTitle: string }>
  ): string {
    return highlights
      .slice(0, 5)
      .map(
        (h, idx) =>
          `${idx + 1}. "${h.content.substring(0, 100)}..." (${h.bookTitle})`
      )
      .join("\n");
  }

  private parseResponse(content: string): Recommendation[] {
    const jsonMatch = content.match(/\[[\s\S]*\]/);
    if (!jsonMatch) {
      throw new Error("LLM response is not in JSON format");
    }
    return JSON.parse(jsonMatch[0]);
  }
}
