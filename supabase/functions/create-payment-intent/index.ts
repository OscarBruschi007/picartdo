import Stripe from "https://esm.sh/stripe@17.7.0?target=deno";
import { handleCors, corsHeaders } from "../_shared/cors.ts";
import {
  adminClient,
  userClient,
  PLATFORM_FEE_PERCENT,
  HIGH_VALUE_THRESHOLD,
} from "../_shared/supabase.ts";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
  apiVersion: "2024-12-18.acacia",
});

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

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
      listing_id,
      shipping_address,
      payment_method_id,
      guest_email,
      use_checkout,
    } = body;

    const { data: listing, error: listingError } = await admin
      .from("listings")
      .select("*, users!listings_artist_id_fkey(stripe_account_id, stripe_identity_verified)")
      .eq("id", listing_id)
      .single();

    if (listingError || !listing) {
      return new Response(JSON.stringify({ error: "Listing not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (listing.status !== "active") {
      return new Response(JSON.stringify({ error: "Listing not available" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const amount = Number(listing.price);
    const platformFee = Math.round(amount * PLATFORM_FEE_PERCENT * 100) / 100;
    const sellerAmount = Math.round((amount - platformFee) * 100) / 100;
    const artist = listing.users as {
      stripe_account_id: string | null;
      stripe_identity_verified: boolean;
    };

    if (!artist?.stripe_account_id) {
      return new Response(
        JSON.stringify({ error: "Artist has not completed payout setup" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { data: buyer } = await admin
      .from("users")
      .select("*")
      .eq("id", user.id)
      .single();

    if (amount > HIGH_VALUE_THRESHOLD && !buyer?.stripe_identity_verified) {
      return new Response(
        JSON.stringify({
          error: "identity_required",
          message: "ID verification required for purchases over $500",
        }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    let stripeCustomerId = buyer?.stripe_customer_id;
    if (!stripeCustomerId) {
      const customer = await stripe.customers.create({
        email: user.email ?? guest_email,
        metadata: { supabase_user_id: user.id },
      });
      stripeCustomerId = customer.id;
      await admin
        .from("users")
        .update({ stripe_customer_id: stripeCustomerId })
        .eq("id", user.id);
    }

    const { data: order, error: orderError } = await admin
      .from("orders")
      .insert({
        listing_id,
        buyer_id: user.id,
        seller_id: listing.artist_id,
        guest_email: guest_email ?? null,
        amount,
        platform_fee: platformFee,
        seller_amount: sellerAmount,
        shipping_address,
        status: "pending",
      })
      .select()
      .single();

    if (orderError || !order) {
      return new Response(JSON.stringify({ error: orderError?.message }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const amountCents = Math.round(amount * 100);
    const feeCents = Math.round(platformFee * 100);

    if (use_checkout) {
      const session = await stripe.checkout.sessions.create({
        mode: "payment",
        customer: stripeCustomerId,
        line_items: [
          {
            price_data: {
              currency: listing.currency?.toLowerCase() ?? "usd",
              product_data: { name: listing.title },
              unit_amount: amountCents,
            },
            quantity: 1,
          },
        ],
        payment_intent_data: {
          application_fee_amount: feeCents,
          transfer_data: { destination: artist.stripe_account_id },
          metadata: { order_id: order.id, listing_id },
        },
        success_url: "picartdo://checkout-success?order_id=" + order.id,
        cancel_url: "picartdo://checkout-cancel?order_id=" + order.id,
        metadata: { order_id: order.id },
      });

      await admin
        .from("orders")
        .update({ stripe_checkout_session_id: session.id })
        .eq("id", order.id);

      return new Response(
        JSON.stringify({
          order_id: order.id,
          checkout_url: session.url,
          amount,
          platform_fee: platformFee,
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount: amountCents,
      currency: listing.currency?.toLowerCase() ?? "usd",
      customer: stripeCustomerId,
      payment_method: payment_method_id,
      confirm: !!payment_method_id,
      automatic_payment_methods: payment_method_id ? undefined : { enabled: true },
      application_fee_amount: feeCents,
      transfer_data: { destination: artist.stripe_account_id },
      metadata: { order_id: order.id, listing_id },
    });

    await admin
      .from("orders")
      .update({ stripe_payment_intent_id: paymentIntent.id })
      .eq("id", order.id);

    return new Response(
      JSON.stringify({
        order_id: order.id,
        client_secret: paymentIntent.client_secret,
        payment_intent_id: paymentIntent.id,
        amount,
        platform_fee: platformFee,
        status: paymentIntent.status,
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
