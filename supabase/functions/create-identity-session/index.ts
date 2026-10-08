import Stripe from "https://esm.sh/stripe@17.7.0?target=deno";
import { handleCors, corsHeaders } from "../_shared/cors.ts";
import { adminClient, userClient } from "../_shared/supabase.ts";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
  apiVersion: "2024-12-18.acacia",
});

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

    const { purpose } = await req.json().catch(() => ({ purpose: "artist" }));
    const isArtist = purpose === "artist";

    const session = await stripe.identity.verificationSessions.create({
      type: "document",
      metadata: {
        supabase_user_id: user.id,
        purpose: isArtist ? "artist_verification" : "buyer_high_value",
      },
      options: {
        document: { require_matching_selfie: true },
      },
      return_url: isArtist
        ? "picartdo://identity-return?purpose=artist"
        : "picartdo://identity-return?purpose=buyer",
    });

    await admin
      .from("users")
      .update({ stripe_identity_session_id: session.id })
      .eq("id", user.id);

    return new Response(
      JSON.stringify({
        session_id: session.id,
        url: session.url,
        client_secret: session.client_secret,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
