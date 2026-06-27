-- ================================================================
-- AMERICAN LEGION MULTI-TENANT MIGRATION
-- Run this in BOTH Post 579 and Post 300 Supabase projects
-- This adds a `posts` table and post_id to every major table
-- so Post 579 and Post 300 data are fully isolated
-- ================================================================

-- ================================================================
-- STEP 1: CREATE POSTS TABLE
-- ================================================================
create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  post_slug text unique not null,
  post_name text not null,
  post_number text not null,
  address text,
  phone text,
  email text,
  website text,
  logo_url text,
  hero_image_url text,
  theme_primary text default '#0B1F3A',
  theme_secondary text default '#B22234',
  city text,
  state text default 'TX',
  zip_code text,
  facebook_url text,
  founded_year text,
  namesake text,
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ================================================================
-- STEP 2: SEED BOTH POSTS
-- ================================================================
insert into public.posts
  (post_slug, post_name, post_number, address, phone, email, website, logo_url, hero_image_url, theme_primary, theme_secondary, is_active)
values
  (
    'amlpost579',
    'American Legion Post 579',
    '579',
    '3002 Gunsmoke St, San Antonio, TX 78227',
    null,
    null,
    null,
    null,
    null,
    '#0B1F3A',
    '#B22234',
    true
  ),
  (
    'amlpost300',
    'William J. Bordelon American Legion Post 300',
    '300',
    '3290 Grosenbacher Rd, San Antonio, TX 78245',
    '(210) 674-3364',
    'alpost300@yahoo.com',
    'https://post300tx.org',
    null,
    null,
    '#0B1F3A',
    '#B22234',
    true
  )
on conflict (post_slug) do nothing;

-- Add extra metadata columns if they don't exist yet
alter table public.posts add column if not exists city text;
alter table public.posts add column if not exists state text default 'TX';
alter table public.posts add column if not exists zip_code text;
alter table public.posts add column if not exists facebook_url text;
alter table public.posts add column if not exists founded_year text;
alter table public.posts add column if not exists namesake text;

-- Now fill in the extra metadata
update public.posts set city = 'San Antonio', state = 'TX', zip_code = '78227' where post_slug = 'amlpost579';
update public.posts set city = 'San Antonio', state = 'TX', zip_code = '78245', facebook_url = 'https://www.facebook.com/ALPost300TX/', founded_year = '1995', namesake = 'Staff Sergeant William James Bordelon, Medal of Honor recipient' where post_slug = 'amlpost300';

-- ================================================================
-- STEP 3: ADD post_id TO ALL MAJOR TABLES
-- ================================================================
alter table public.site_members           add column if not exists post_id uuid references public.posts(id);
alter table public.events                 add column if not exists post_id uuid references public.posts(id);
alter table public.hall_rental_inquiries  add column if not exists post_id uuid references public.posts(id);
alter table public.officers               add column if not exists post_id uuid references public.posts(id);
alter table public.gallery                add column if not exists post_id uuid references public.posts(id);
alter table public.staff                  add column if not exists post_id uuid references public.posts(id);
alter table public.inventory              add column if not exists post_id uuid references public.posts(id);
alter table public.announcements          add column if not exists post_id uuid references public.posts(id);
alter table public.building_maintenance   add column if not exists post_id uuid references public.posts(id);
alter table public.bingo_events           add column if not exists post_id uuid references public.posts(id);
alter table public.bingo_players          add column if not exists post_id uuid references public.posts(id);
alter table public.bartender_schedule     add column if not exists post_id uuid references public.posts(id);
alter table public.staff_training         add column if not exists post_id uuid references public.posts(id);
alter table public.staff_documents        add column if not exists post_id uuid references public.posts(id);
alter table public.staff_availability     add column if not exists post_id uuid references public.posts(id);
alter table public.staff_time_off         add column if not exists post_id uuid references public.posts(id);

-- ================================================================
-- STEP 4: INDEXES ON post_id FOR PERFORMANCE
-- ================================================================
create index if not exists idx_members_post_id      on public.site_members(post_id);
create index if not exists idx_events_post_id        on public.events(post_id);
create index if not exists idx_rentals_post_id       on public.hall_rental_inquiries(post_id);
create index if not exists idx_officers_post_id      on public.officers(post_id);
create index if not exists idx_gallery_post_id       on public.gallery(post_id);
create index if not exists idx_staff_post_id         on public.staff(post_id);
create index if not exists idx_inventory_post_id     on public.inventory(post_id);
create index if not exists idx_announcements_post_id on public.announcements(post_id);
create index if not exists idx_maintenance_post_id   on public.building_maintenance(post_id);
create index if not exists idx_bingo_post_id         on public.bingo_events(post_id);

-- ================================================================
-- STEP 5: BACKFILL existing Post 300 data (run on Post 300 DB only)
-- Assigns all existing records to the Post 300 post_id
-- ================================================================

-- Backfill all existing officers → Post 300
update public.officers
set post_id = (select id from public.posts where post_slug = 'amlpost300' limit 1)
where post_id is null;

-- Backfill all existing events → Post 300
update public.events
set post_id = (select id from public.posts where post_slug = 'amlpost300' limit 1)
where post_id is null;

-- Backfill all existing announcements → Post 300
update public.announcements
set post_id = (select id from public.posts where post_slug = 'amlpost300' limit 1)
where post_id is null;

-- Backfill all existing members → Post 300
update public.site_members
set post_id = (select id from public.posts where post_slug = 'amlpost300' limit 1)
where post_id is null;

-- Backfill all existing rentals → Post 300
update public.hall_rental_inquiries
set post_id = (select id from public.posts where post_slug = 'amlpost300' limit 1)
where post_id is null;

-- Backfill all existing gallery → Post 300
update public.gallery
set post_id = (select id from public.posts where post_slug = 'amlpost300' limit 1)
where post_id is null;

-- Backfill all existing staff → Post 300
update public.staff
set post_id = (select id from public.posts where post_slug = 'amlpost300' limit 1)
where post_id is null;

-- Backfill all existing inventory → Post 300
update public.inventory
set post_id = (select id from public.posts where post_slug = 'amlpost300' limit 1)
where post_id is null;

-- Backfill all existing maintenance → Post 300
update public.building_maintenance
set post_id = (select id from public.posts where post_slug = 'amlpost300' limit 1)
where post_id is null;

-- Backfill all existing bingo events → Post 300
update public.bingo_events
set post_id = (select id from public.posts where post_slug = 'amlpost300' limit 1)
where post_id is null;

-- ================================================================
-- STEP 6: VERIFY
-- ================================================================
select post_slug, post_name, post_number, address from public.posts;


-- ================================================================
-- STEP 7: POST PLANS TABLE (feature flags + billing per post)
-- ================================================================
create extension if not exists pgcrypto;

create table if not exists public.post_plans (
  id uuid primary key default gen_random_uuid(),
  post_id uuid references public.posts(id) on delete cascade,
  plan_name text default 'standard',
  billing_status text default 'active',
  max_admins int default 5,
  max_staff int default 100,
  max_gallery_photos int default 500,
  max_storage_mb int default 5000,
  events_enabled boolean default true,
  hall_rental_enabled boolean default true,
  staff_enabled boolean default true,
  inventory_enabled boolean default true,
  bartender_schedule_enabled boolean default true,
  bingo_enabled boolean default true,
  donations_enabled boolean default true,
  ai_assistant_enabled boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Seed plan for Post 300
insert into public.post_plans (post_id, plan_name, billing_status)
select id, 'standard', 'active'
from public.posts
where post_slug = 'amlpost300'
on conflict do nothing;

-- Seed plan for Post 579
insert into public.post_plans (post_id, plan_name, billing_status)
select id, 'standard', 'active'
from public.posts
where post_slug = 'amlpost579'
on conflict do nothing;

-- ================================================================
-- VERIFY post_plans
-- ================================================================
select p.post_slug, pp.plan_name, pp.billing_status, pp.ai_assistant_enabled
from public.post_plans pp
join public.posts p on p.id = pp.post_id;

-- ================================================================
-- DONE — Both posts are now tenants in the same database schema.
-- Every query in the app must filter by post_id going forward.
-- ================================================================
