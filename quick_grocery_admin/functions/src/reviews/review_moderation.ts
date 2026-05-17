const BLOCKED_WORDS = [
  "spam",
  "scam",
  "fake",
  "idiot",
  "stupid",
  "worst service",
  "fraud",
];

export function containsBlockedContent(text: string): boolean {
  const lower = text.toLowerCase();
  return BLOCKED_WORDS.some((w) => lower.includes(w));
}

export function sanitizeText(text: string, maxLen = 2000): string {
  return text.trim().slice(0, maxLen);
}
