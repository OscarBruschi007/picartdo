import Stripe from "https://esm.sh/stripe@17.7.0?target=deno";
import { corsHeaders } from "../_shared/cors.ts";
import { adminClient } from "../_shared/supabase.ts";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
  apiVersion: "2024-12-18.acacia",
});

Deno.serve(async (req) => {
  const signature = req.headers.get("stripe-signature");
  if (!signature) {
    return new Response("Missing signature", { status: 400 });
  }

  const body = await req.text();
  let event: Stripe.Event;

  try {
    event = stripe.webhooks.constructEvent(
      body,
      signature,
      Deno.env.get("STRIPE_WEBHOOK_SECRET")!
    );
  } catch {
    return new Response("Invalid signature", { status: 400 });
  }

  const admin = adminClient();

  switch (event.type) {
    case "payment_intent.succeeded":
    case "checkout.session.completed": {
      const obj = event.data.object as Stripe.PaymentIntent | Stripe.Checkout.Session;
      const orderId =
        "metadata" in obj && obj.metadata?.order_id
          ? obj.metadata.order_id
          : null;

      if (!orderId) break;

      await admin
        .from("orders")
        .update({ status: "paid", updated_at: new Date().toISOString() })
        .eq("id", orderId);

      const { data: order } = await admin
        .from("orders")
        .select("listing_id")
        .eq("id", orderId)
        .single();

      if (order?.listing_id) {
        await admin
          .from("listings")
          .update({ status: "sold", updated_at: new Date().toISOString() })
          .eq("id", order.listing_id);
      }
      break;
    }
    case "payment_intent.payment_failed": {
      const pi = event.data.object as Stripe.PaymentIntent;
      const orderId = pi.metadata?.order_id;
      if (orderId) {
        await admin
          .from("orders")
          .update({ status: "failed", updated_at: new Date().toISOString() })
          .eq("id", orderId);
      }
      break;
    }
    case "charge.dispute.created": {
      const dispute = event.data.object as Stripe.Dispute;
      const piId = dispute.payment_intent as string;
      if (piId) {
        await admin
          .from("orders")
          .update({ status: "disputed", updated_at: new Date().toISOString() })
          .eq("stripe_payment_intent_id", piId);
      }
      break;
    }
    case "charge.refunded": {
      const charge = event.data.object as Stripe.Charge;
      const piId = charge.payment_intent as string;
      if (piId) {
        const { data: order } = await admin
          .from("orders")
          .select("listing_id")
          .eq("stripe_payment_intent_id", piId)
          .single();

        await admin
          .from("orders")
          .update({ status: "refunded", updated_at: new Date().toISOString() })
          .eq("stripe_payment_intent_id", piId);

        if (order?.listing_id) {
          await admin
            .from("listings")
            .update({ status: "active" })
            .eq("id", order.listing_id);
        }
      }
      break;
    }
  }

  return new Response(JSON.stringify({ received: true }), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
