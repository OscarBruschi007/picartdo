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

    const { data: profile } = await admin
      .from("users")
      .select("email, full_name")
      .eq("id", user.id)
      .single();

    let accountId: string;
    const { data: existing } = await admin
      .from("stripe_connect_accounts")
      .select("stripe_account_id")
      .eq("user_id", user.id)
      .single();

    if (existing?.stripe_account_id) {
      accountId = existing.stripe_account_id;
    } else {
      const account = await stripe.accounts.create({
        type: "standard",
        email: profile?.email ?? user.email,
        metadata: { supabase_user_id: user.id },
      });
      accountId = account.id;

      await admin.from("stripe_connect_accounts").upsert({
        user_id: user.id,
        stripe_account_id: accountId,
      });
      await admin
        .from("users")
        .update({ stripe_account_id: accountId })
        .eq("id", user.id);
    }

    const accountLink = await stripe.accountLinks.create({
      account: accountId,
      refresh_url: "picartdo://connect-refresh",
      return_url: "picartdo://connect-return",
      type: "account_onboarding",
    });

    await admin
      .from("stripe_connect_accounts")
      .update({ onboarding_url: accountLink.url })
      .eq("user_id", user.id);

    return new Response(
      JSON.stringify({ url: accountLink.url, account_id: accountId }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
