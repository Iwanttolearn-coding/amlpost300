import { getDatabase } from "@netlify/database";
import crypto from "node:crypto";

const POST_SLUG = "amlpost300";
const ADMIN_PASSWORD = process.env.POST300_ADMIN_PASSWORD || process.env.ADMIN_PASSWORD || "";
const TYPES = new Set([
  "announcement", "event", "officer", "gallery", "hall_rental_inquiry", "site_member",
  "bingo_event", "bingo_player", "bingo_game", "bingo_call", "bingo_winner", "staff",
  "bartender_schedule", "inventory", "building_maintenance", "donation", "document",
  "staff_training", "home_content"
]);

const json = (body, status = 200) => Response.json(body, { status });
const hash = (value) => crypto.createHash("sha256").update(String(value)).digest("hex");

async function postId(db) {
  const rows = await db.sql`SELECT id FROM posts WHERE post_slug = ${POST_SLUG} LIMIT 1`;
  if (rows[0]) return rows[0].id;
  const [row] = await db.sql`INSERT INTO posts (post_slug, post_name, is_active) VALUES (${POST_SLUG}, ${"American Legion Post 300"}, TRUE) RETURNING id`;
  return row.id;
}

function cleanRecord(row) {
  return { id: row.id, created_at: row.created_at, updated_at: row.updated_at, ...row.data };
}

async function list(db, type, limit = 200) {
  const pid = await postId(db);
  const rows = await db.sql`
    SELECT id, data, created_at, updated_at
    FROM post_records
    WHERE post_id = ${pid} AND record_type = ${type} AND is_active = TRUE
    ORDER BY created_at DESC
    LIMIT ${Number(limit)}
  `;
  return rows.map(cleanRecord);
}

async function create(db, type, data) {
  const pid = await postId(db);
  const [row] = await db.sql`
    INSERT INTO post_records (post_id, record_type, data)
    VALUES (${pid}, ${type}, ${JSON.stringify(data)})
    RETURNING id, data, created_at, updated_at
  `;
  return cleanRecord(row);
}

async function update(db, type, id, data) {
  const pid = await postId(db);
  const [row] = await db.sql`
    UPDATE post_records
    SET data = data || ${JSON.stringify(data)}::jsonb, updated_at = NOW()
    WHERE post_id = ${pid} AND record_type = ${type} AND id = ${Number(id)}
    RETURNING id, data, created_at, updated_at
  `;
  return row ? cleanRecord(row) : null;
}

async function remove(db, type, id) {
  const pid = await postId(db);
  await db.sql`UPDATE post_records SET is_active = FALSE, updated_at = NOW() WHERE post_id = ${pid} AND record_type = ${type} AND id = ${Number(id)}`;
  return { ok: true };
}

async function findMember(db, email) {
  const pid = await postId(db);
  const rows = await db.sql`
    SELECT id, data, created_at, updated_at FROM post_records
    WHERE post_id = ${pid} AND record_type = 'site_member' AND lower(data->>'email') = lower(${email}) AND is_active = TRUE
    LIMIT 1
  `;
  return rows[0];
}

async function assistant(db, prompt) {
  const text = String(prompt || "").toLowerCase();
  if (text.includes("status")) {
    const [events, members, rentals, inventory, maintenance] = await Promise.all([
      list(db, "event", 20), list(db, "site_member", 200), list(db, "hall_rental_inquiry", 200),
      list(db, "inventory", 200), list(db, "building_maintenance", 200)
    ]);
    return `Status: ${events.length} events, ${members.length} member records, ${rentals.length} rental inquiries, ${inventory.length} inventory items, ${maintenance.length} maintenance tickets.`;
  }
  const eventMatch = prompt.match(/create event\s+(.+?)\s+on\s+(\d{4}-\d{2}-\d{2})/i);
  if (eventMatch) {
    const rec = await create(db, "event", { title: eventMatch[1], event_date: eventMatch[2], event_type: "General", location: "Post 300 Hall" });
    return `Created event: ${rec.title} on ${rec.event_date}.`;
  }
  if (text.includes("inventory")) {
    const items = await list(db, "inventory", 20);
    return items.length ? items.map((i) => `${i.item_name}: ${i.quantity} on hand`).join("; ") : "No inventory items are recorded yet.";
  }
  return "I can create events with 'create event NAME on YYYY-MM-DD', check inventory, or produce a status report.";
}

export default async (req) => {
  const db = getDatabase();
  const url = new URL(req.url);
  const action = url.searchParams.get("action");
  const type = url.searchParams.get("type");

  try {
    if (req.method === "GET") {
      if (!TYPES.has(type)) return json({ error: "Unknown record type" }, 400);
      return json(await list(db, type, url.searchParams.get("limit") || 200));
    }

    const body = await req.json().catch(() => ({}));

    if (action === "admin-login") return json({ ok: Boolean(ADMIN_PASSWORD) && body.password === ADMIN_PASSWORD });
    if (action === "member-signup") {
      const existing = await findMember(db, body.email);
      if (existing) return json({ error: "An account already exists for that email." }, 409);
      const member = await create(db, "site_member", { ...body, password_hash: hash(body.password), password: undefined, membership_status: "pending", role: "member" });
      return json({ id: member.id, membership_status: member.membership_status }, 201);
    }
    if (action === "member-login") {
      const row = await findMember(db, body.email);
      if (!row || row.data.password_hash !== hash(body.password)) return json({ error: "Invalid email or password." }, 401);
      await update(db, "site_member", row.id, { last_login: new Date().toISOString() });
      const member = cleanRecord(row);
      delete member.password_hash;
      return json({ member });
    }
    if (action === "assistant") return json({ reply: await assistant(db, body.prompt || "") });

    if (!TYPES.has(type)) return json({ error: "Unknown record type" }, 400);
    if (req.method === "POST") return json(await create(db, type, body), 201);
    if (req.method === "PUT") return json(await update(db, type, body.id, body));
    if (req.method === "DELETE") return json(await remove(db, type, body.id));
    return json({ error: "Method not allowed" }, 405);
  } catch (error) {
    return json({ error: error.message || "Request failed" }, 500);
  }
};

export const config = { path: "/api/post300" };
