import { handleCors, corsHeaders } from "../_shared/cors.ts";
import { adminClient, userClient } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    const authHeader = req.headers.get("Authorization")!;
    const supabase = userClient(authHeader);
    const admin = adminClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body = await req.json();
    const {
      artist_id,
      guest_name,
      guest_email,
      style,
      size,
      timeline,
      budget,
      description,
      reference_note,
    } = body;

    const budgetNum = parseFloat(budget) || 0;

    const { data, error } = await admin
      .from("commission_requests")
      .insert({
        buyer_id: user.id,
        artist_id,
        guest_name,
        guest_email: guest_email ?? user.email,
        style,
        size,
        timeline,
        budget_min: budgetNum,
        budget_max: budgetNum,
        description,
        reference_note,
        status: "pending",
      })
      .select()
      .single();

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ commission: data }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
