// ================================================================
// AMLPost300 — Supabase Client
// Multi-tenant, post-isolated, storage-routed, plan-gated
// POST_SLUG = "amlpost300"
// ================================================================
(function () {
  const SUPABASE_URL     = 'https://udohkokiatruhmavujql.supabase.co';
  const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVkb2hrb2tpYXRydWhtYXZ1anFsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA5OTExODYsImV4cCI6MjA2NjU2NzE4Nn0.EeGZgj_9ckmvJGMz5aq5RVGb9CDvPTSy8dMeqM8B6UA';
  const POST_SLUG        = 'amlpost300';
  const STORAGE_BUCKET   = 'amlpost300';

  const script = document.createElement('script');
  script.src = 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.min.js';

  script.onload = async function () {
    const client = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    window._sbClient = client;

    // ── 1. Load post config ──────────────────────────────────
    let post = null, plan = null;
    try {
      const { data, error } = await client
        .from('posts').select('*').eq('post_slug', POST_SLUG).single();
      if (!error && data) post = data;
    } catch(e) { console.warn('[Legion] Could not load post config:', e.message); }

    // ── 2. Load plan config ──────────────────────────────────
    if (post) {
      try {
        const { data } = await client
          .from('post_plans').select('*').eq('post_id', post.id).single();
        if (data) plan = data;
      } catch(e) { /* plan table may not exist yet */ }
    }

    // ── 3. Globals ───────────────────────────────────────────
    window.POST_ID      = post?.id   ?? null;
    window.POST_CONFIG  = post        ?? null;
    window.POST_PLAN    = plan        ?? null;
    window.POST_SLUG    = POST_SLUG;
    window.STORAGE_BUCKET = STORAGE_BUCKET;
    window.supabase     = client;  // raw client always available

    // ── 4. Feature flag check ────────────────────────────────
    // Usage: if (!featureEnabled('bingo_enabled')) { ... }
    window.featureEnabled = function(flag) {
      if (!window.POST_PLAN) return true; // default open if no plan loaded
      return window.POST_PLAN[flag] !== false;
    };

    // ── 5. Post-scoped SELECT helper ─────────────────────────
    // Usage: await pq('events').gte('event_date', today).order('event_date')
    window.pq = function(table) {
      let q = client.from(table).select('*');
      if (window.POST_ID) q = q.eq('post_id', window.POST_ID);
      return q;
    };

    // ── 6. Post-scoped INSERT helper ─────────────────────────
    // Usage: await pi('events', { title: '...', event_date: '...' })
    window.pi = async function(table, payload) {
      if (window.POST_ID) payload.post_id = window.POST_ID;
      const { data, error } = await client.from(table).insert(payload).select();
      if (error) throw error;
      return data;
    };

    // ── 7. Post-scoped UPDATE helper ─────────────────────────
    // Enforces post_id on every UPDATE so Post300 can't touch Post579
    // Usage: await pu('events', id, { title: '...' })
    window.pu = async function(table, id, payload) {
      payload.updated_at = new Date().toISOString();
      let q = client.from(table).update(payload).eq('id', id);
      if (window.POST_ID) q = q.eq('post_id', window.POST_ID);
      const { data, error } = await q.select();
      if (error) throw error;
      return data;
    };

    // ── 8. Post-scoped DELETE helper ─────────────────────────
    // Enforces post_id on every DELETE so Post300 can't delete Post579
    // Usage: await pd('events', id)
    window.pd = async function(table, id) {
      let q = client.from(table).delete().eq('id', id);
      if (window.POST_ID) q = q.eq('post_id', window.POST_ID);
      const { error } = await q;
      if (error) throw error;
    };

    // ── 9. Storage upload helper ─────────────────────────────
    // Uploads ONLY into the amlpost300 bucket/folder
    // Usage: const url = await uploadFile(file, 'gallery')
    window.uploadFile = async function(file, folder) {
      const ext  = file.name.split('.').pop();
      const path = `${POST_SLUG}/${folder}/${Date.now()}-${Math.random().toString(36).slice(2)}.${ext}`;
      const { data, error } = await client.storage
        .from(STORAGE_BUCKET)
        .upload(path, file, { upsert: false, contentType: file.type });
      if (error) throw error;
      const { data: urlData } = client.storage
        .from(STORAGE_BUCKET)
        .getPublicUrl(data.path);
      return { url: urlData.publicUrl, path: data.path };
    };

    // ── 10. Apply theme colors ───────────────────────────────
    if (post?.theme_secondary) {
      document.documentElement.style.setProperty('--accent', post.theme_secondary);
    }

    document.dispatchEvent(new Event('supabase:ready'));
  };

  document.head.appendChild(script);
})();

// ================================================================
// GLOBAL UTILITY FUNCTIONS (available on all pages)
// ================================================================
function toDate(v) { return (!v || v === '') ? null : v; }
function toNum(v)  { return (v === '' || v == null || isNaN(Number(v))) ? null : Number(v); }
function toStr(v)  { return (!v || String(v).trim() === '') ? null : String(v).trim(); }
function toBool(v) { return v === true || v === 'true'; }

function today() { return new Date().toISOString().split('T')[0]; }

function formatDate(d) {
  if (!d) return '—';
  return new Date(d + 'T00:00:00').toLocaleDateString('en-US',
    { weekday: 'short', month: 'short', day: 'numeric', year: 'numeric' });
}
function formatShortDate(d) {
  if (!d) return '—';
  return new Date(d + 'T00:00:00').toLocaleDateString('en-US',
    { month: 'short', day: 'numeric' });
}
function fmtCurrency(n) {
  if (n == null) return '—';
  return '$' + Number(n).toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}
