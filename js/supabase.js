// ================================================================
// Supabase Multi-Tenant Client — American Legion Post 300
// All queries auto-filtered by post_id
// ================================================================
(function () {
  const SUPABASE_URL = 'https://udohkokiatruhmavujql.supabase.co';
  const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVkb2hrb2tpYXRydWhtYXZ1anFsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA5OTExODYsImV4cCI6MjA2NjU2NzE4Nn0.EeGZgj_9ckmvJGMz5aq5RVGb9CDvPTSy8dMeqM8B6UA';

  // Which post is this site for
  const POST_SLUG = 'amlpost300';

  const script = document.createElement('script');
  script.src = 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.min.js';
  script.onload = async function () {
    window._sbClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

    // Load post config once and cache it
    const { data: post, error } = await window._sbClient
      .from('posts')
      .select('*')
      .eq('post_slug', POST_SLUG)
      .single();

    if (error || !post) {
      // posts table may not exist yet — fallback to raw client
      console.warn('[Legion] posts table not found, using raw client');
      window.supabase = window._sbClient;
      window.POST_ID = null;
      window.POST_CONFIG = null;
      document.dispatchEvent(new Event('supabase:ready'));
      return;
    }

    window.POST_ID = post.id;
    window.POST_CONFIG = post;

    // Apply dynamic theming if available
    if (post.theme_secondary) {
      document.documentElement.style.setProperty('--accent', post.theme_secondary);
    }

    // Expose a scoped query helper
    // Usage: await postQuery('events').select('*').order('event_date')
    window.postQuery = function(table) {
      return window._sbClient.from(table).select('*').eq('post_id', post.id);
    };

    // Expose raw client too
    window.supabase = window._sbClient;

    document.dispatchEvent(new Event('supabase:ready'));
  };
  document.head.appendChild(script);
})();

// ================================================================
// GLOBAL HELPERS — used across all pages
// ================================================================
function toDate(v) { return (!v || v === '') ? null : v; }
function toNum(v) { return (v === '' || v === null || v === undefined || isNaN(Number(v))) ? null : Number(v); }
function toStr(v) { return (!v || String(v).trim() === '') ? null : String(v).trim(); }

function formatDate(d) {
  if (!d) return '—';
  const dt = new Date(d + 'T00:00:00');
  return dt.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric', year: 'numeric' });
}
function formatShortDate(d) {
  if (!d) return '—';
  return new Date(d + 'T00:00:00').toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}
function today() { return new Date().toISOString().split('T')[0]; }

// Attach post_id to any insert payload automatically
function withPost(payload) {
  if (window.POST_ID) payload.post_id = window.POST_ID;
  return payload;
}
