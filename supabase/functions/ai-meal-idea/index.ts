// ai-meal-idea — Edge Function proxying OpenRouter.
//
// The OpenRouter key lives ONLY in `supabase secrets` server-side; the APK
// calls this function with the publishable anon key and no secrets.
// Deploy: supabase functions deploy ai-meal-idea
// Secret: supabase secrets set OPENROUTER_API_KEY=sk-or-...
//
// Privacy: request body carries only allergen keys, verified-safe ingredient
// names, servings and meal type — never names, events or child data.
// Safety: output is labeled AI-generated; it is NEVER allergy evidence.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const OPENROUTER_API_KEY = Deno.env.get("OPENROUTER_API_KEY") ?? "";
const MODEL = Deno.env.get("OPENROUTER_MODEL") ?? "openrouter/auto";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "method_not_allowed" }), { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }
  if (!OPENROUTER_API_KEY) {
    return new Response(JSON.stringify({ error: "ai_not_configured" }), { status: 503, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }

  let body: { allergens?: string[]; ingredients?: string[]; servings?: number; meal?: string };
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "bad_request" }), { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }

  const allergens = (body.allergens ?? []).slice(0, 20).join(", ") || "none reported";
  const ingredients = (body.ingredients ?? []).slice(0, 60).join(", ");
  const servings = Math.min(Math.max(body.servings ?? 4, 1), 12);
  const meal = body.meal ?? "dinner";

  const upstream = await fetch("https://openrouter.ai/api/v1/chat/completions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${OPENROUTER_API_KEY}`,
      "Content-Type": "application/json",
      "X-Title": "Family Circle",
    },
    body: JSON.stringify({
      model: MODEL,
      max_tokens: 400,
      temperature: 0.7,
      messages: [
        {
          role: "system",
          content:
            "You suggest one family meal idea. Rules: use only the listed verified-safe ingredients; never claim allergy safety; output dish name, 3-4 short steps, and which listed ingredients it uses. Plain text, no markdown.",
        },
        {
          role: "user",
          content: `Hard allergens to avoid: ${allergens}. Verified-safe ingredients available: ${ingredients}. Servings needed: ${servings}. Course: ${meal}. Give one realistic weeknight meal.`,
        },
      ],
    }),
  });

  if (!upstream.ok) {
    return new Response(JSON.stringify({ error: `upstream_${upstream.status}` }), { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }
  const data = await upstream.json();
  const text = data?.choices?.[0]?.message?.content ?? "";
  return new Response(JSON.stringify({ text, model: data?.model ?? MODEL }), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
