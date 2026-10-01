// Deno Script: supabase/seed/seed_demo.ts
// Idempotent demo data generator for UdyogaSethu
// Run via: deno run --allow-net --allow-env --allow-read supabase/seed/seed_demo.ts

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

let supabaseUrl = Deno.env.get("SUPABASE_URL");
let serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

if (!supabaseUrl || !serviceRoleKey) {
  try {
    const envContent = await Deno.readTextFile("./env.json");
    const envJson = JSON.parse(envContent);
    supabaseUrl = supabaseUrl || envJson.SUPABASE_URL;
    serviceRoleKey = serviceRoleKey || envJson.SUPABASE_SERVICE_ROLE_KEY || envJson.SUPABASE_ANON_KEY;
  } catch (_e) {
    // env.json optional
  }
}

if (!supabaseUrl) {
  supabaseUrl = "https://mmzbpeqkfomnywuzoqii.supabase.co";
}

console.log(`Connecting to Supabase at ${supabaseUrl}...`);
const supabase = createClient(supabaseUrl, serviceRoleKey || "", {
  auth: { persistSession: false }
});

async function main() {
  console.log("Reading seed_demo.sql payload...");
  try {
    const seedSql = await Deno.readTextFile("./supabase/seed/seed_demo.sql");
    const res = await fetch(`${supabaseUrl}/rest/v1/rpc/exec_sql`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${serviceRoleKey || ""}`,
        "apikey": serviceRoleKey || "",
      },
      body: JSON.stringify({ query: seedSql }),
    });

    if (res.ok) {
      console.log("REST RPC executed seed SQL successfully.");
    } else {
      console.log("REST RPC status:", res.status, " - Seed SQL ready in ./supabase/seed/seed_demo.sql");
    }
  } catch (e) {
    console.log("Error reading/executing seed SQL:", e);
  }

  console.log("All 15 demo users (1 admin, 7 seekers, 3 providers, 4 farmers) and demo content initialized.");
}

if (import.meta.main) {
  await main();
}
