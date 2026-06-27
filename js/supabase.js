// Supabase client — American Legion Post 300 (William J. Bordelon Post)
// !! REPLACE WITH YOUR NEW POST 300 SUPABASE URL & ANON KEY AFTER CREATING THE PROJECT !!
(function () {
  const SUPABASE_URL = 'YOUR_POST300_SUPABASE_URL';
  const SUPABASE_ANON_KEY = 'YOUR_POST300_SUPABASE_ANON_KEY';

  const script = document.createElement('script');
  script.src = 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.min.js';
  script.onload = function () {
    window.supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    document.dispatchEvent(new Event('supabase:ready'));
  };
  document.head.appendChild(script);
})();

// Helpers
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
  const dt = new Date(d + 'T00:00:00');
  return dt.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}
function today() { return new Date().toISOString().split('T')[0]; }
