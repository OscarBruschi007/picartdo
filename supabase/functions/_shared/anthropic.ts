// Server-side Claude access. The API key lives only in the function's secrets
// (`supabase secrets set ANTHROPIC_API_KEY=...`), never in the app.

export const MODELS = {
  // Conversation and multi-step tool use.
  agent: "claude-sonnet-5",
  // Vision autofill for listings.
  vision: "claude-sonnet-5",
  // Cheap, fast classification and memory extraction.
  fast: "claude-haiku-4-5-20251001",
} as const;

export type ContentBlock =
  | { type: "text"; text: string }
  | { type: "image"; source: { type: "base64"; media_type: string; data: string } }
  | { type: "tool_use"; id: string; name: string; input: Record<string, unknown> }
  | { type: "tool_result"; tool_use_id: string; content: string; is_error?: boolean };

export interface ClaudeMessage {
  role: "user" | "assistant";
  content: string | ContentBlock[];
}

export interface ClaudeTool {
  name: string;
  description: string;
  input_schema: Record<string, unknown>;
}

export interface ClaudeResponse {
  content: ContentBlock[];
  stop_reason: string;
  usage: { input_tokens: number; output_tokens: number };
}

export class ClaudeError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}

export async function callClaude(params: {
  model: string;
  system?: string;
  messages: ClaudeMessage[];
  tools?: ClaudeTool[];
  maxTokens?: number;
}): Promise<ClaudeResponse> {
  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!apiKey) throw new ClaudeError(500, "ANTHROPIC_API_KEY is not set");

  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-api-key": apiKey,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: params.model,
      max_tokens: params.maxTokens ?? 1024,
      system: params.system,
      messages: params.messages,
      tools: params.tools,
    }),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new ClaudeError(res.status, body.slice(0, 300));
  }
  return await res.json();
}

export function textOf(response: ClaudeResponse): string {
  return response.content
    .filter((b): b is { type: "text"; text: string } => b.type === "text")
    .map((b) => b.text)
    .join("\n")
    .trim();
}
