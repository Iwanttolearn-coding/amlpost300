-- ================================================================
-- AMERICAN LEGION POST 300 — COMPLETE SUPABASE SCHEMA
-- Run this in your Post 300 Supabase SQL Editor
-- Safe to re-run — all statements are idempotent
-- ================================================================

-- ── EXTENSIONS ───────────────────────────────────────────────
create extension if not exists pgcrypto;
create extension if not exists "uuid-ossp";

-- ================================================================
-- TABLE 1: POSTS (multi-tenant root)
-- ================================================================
create table if not exists public.posts (
  id              uuid primary key default gen_random_uuid(),
  post_slug       text unique not null,
  post_name       text not null,
  post_number     text not null,
  address         text,
  phone           text,
  email           text,
  website         text,
  logo_url        text,
  hero_image_url  text,
  theme_primary   text default '#0B1F3A',
  theme_secondary text default '#B22234',
  is_active       boolean default true,
  created_at      timestamptz default now(),
  updated_at      timestamptz default now()
);

alter table public.posts add column if not exists city          text;
alter table public.posts add column if not exists state         text default 'TX';
alter table public.posts add column if not exists zip_code      text;
alter table public.posts add column if not exists facebook_url  text;
alter table public.posts add column if not exists founded_year  text;
alter table public.posts add column if not exists namesake      text;
alter table public.posts add column if not exists storage_bucket text default 'amlpost300';

insert into public.posts
  (post_slug, post_name, post_number, address, phone, email, website, logo_url, hero_image_url, theme_primary, theme_secondary, is_active)
values
  ('amlpost579', 'American Legion Post 579', '579',
   '3002 Gunsmoke St, San Antonio, TX 78227',
   null, null, null, null, null, '#0B1F3A', '#B22234', true),
  ('amlpost300', 'William J. Bordelon American Legion Post 300', '300',
   '3290 Grosenbacher Rd, San Antonio, TX 78245',
   '(210) 674-3364', 'alpost300@yahoo.com', 'https://post300tx.org',
   null, null, '#0B1F3A', '#B22234', true)
on conflict (post_slug) do nothing;

update public.posts set city='San Antonio', state='TX', zip_code='78227', storage_bucket='amlpost579'
  where post_slug='amlpost579' and city is null;
update public.posts set city='San Antonio', state='TX', zip_code='78245',
  facebook_url='https://www.facebook.com/ALPost300TX/',
  founded_year='1995',
  namesake='Staff Sergeant William James Bordelon, Medal of Honor recipient',
  storage_bucket='amlpost300'
  where post_slug='amlpost300' and city is null;

-- ================================================================
-- TABLE 2: POST PLANS
-- ================================================================
create table if not exists public.post_plans (
  id                          uuid primary key default gen_random_uuid(),
  post_id                     uuid references public.posts(id) on delete cascade,
  plan_name                   text default 'standard',
  billing_status              text default 'active',
  max_admins                  int default 5,
  max_staff                   int default 100,
  max_gallery_photos          int default 500,
  max_storage_mb              int default 5000,
  events_enabled              boolean default true,
  hall_rental_enabled         boolean default true,
  staff_enabled               boolean default true,
  inventory_enabled           boolean default true,
  bartender_schedule_enabled  boolean default true,
  bingo_enabled               boolean default true,
  donations_enabled           boolean default true,
  ai_assistant_enabled        boolean default true,
  documents_enabled           boolean default true,
  training_enabled            boolean default true,
  created_at                  timestamptz default now(),
  updated_at                  timestamptz default now()
);
create index if not exists idx_post_plans_post_id on public.post_plans(post_id);

insert into public.post_plans (post_id, plan_name, billing_status)
  select id, 'standard', 'active' from public.posts where post_slug='amlpost300'
  on conflict do nothing;
insert into public.post_plans (post_id, plan_name, billing_status)
  select id, 'standard', 'active' from public.posts where post_slug='amlpost579'
  on conflict do nothing;

-- ================================================================
-- TABLE 3: SITE MEMBERS
-- ================================================================
create table if not exists public.site_members (
  id                uuid primary key default gen_random_uuid(),
  post_id           uuid references public.posts(id),
  full_name         text not null,
  email             text,
  phone             text,
  date_of_birth     date,
  address           text,
  city              text,
  branch_of_service text,
  years_of_service  int,
  membership_type   text default 'American Legion',
  membership_status text default 'pending'
    check (membership_status in ('pending','active','inactive','expired','approved','rejected')),
  role              text default 'member'
    check (role in ('member','officer','admin','staff','volunteer')),
  notes             text,
  photo_url         text,
  created_at        timestamptz default now(),
  updated_at        timestamptz default now()
);
create index if not exists idx_members_post_id on public.site_members(post_id);

-- ================================================================
-- TABLE 4: EVENTS
-- ================================================================
create table if not exists public.events (
  id          uuid primary key default gen_random_uuid(),
  post_id     uuid references public.posts(id),
  title       text not null,
  event_date  date not null,
  start_time  time,
  end_time    time,
  event_type  text,
  description text,
  location    text,
  image_url   text,
  is_public   boolean default true,
  is_recurring boolean default false,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);
create index if not exists idx_events_post_id   on public.events(post_id);
create index if not exists idx_events_date      on public.events(event_date);

-- ================================================================
-- TABLE 5: HALL RENTAL INQUIRIES
-- ================================================================
create table if not exists public.hall_rental_inquiries (
  id             uuid primary key default gen_random_uuid(),
  post_id        uuid references public.posts(id),
  contact_name   text not null,
  contact_email  text,
  contact_phone  text,
  event_type     text,
  event_date     date,
  start_time     time,
  end_time       time,
  guest_count    int,
  notes          text,
  admin_notes    text,
  status         text default 'pending'
    check (status in ('pending','approved','confirmed','cancelled','rejected')),
  deposit_paid   boolean default false,
  total_amount   numeric(10,2),
  created_at     timestamptz default now(),
  updated_at     timestamptz default now()
);
create index if not exists idx_rentals_post_id on public.hall_rental_inquiries(post_id);

-- ================================================================
-- TABLE 6: OFFICERS
-- ================================================================
create table if not exists public.officers (
  id          uuid primary key default gen_random_uuid(),
  post_id     uuid references public.posts(id),
  name        text not null,
  full_name   text,
  title       text not null,
  position    text,
  email       text,
  phone       text,
  photo_url   text,
  bio         text,
  sort_order  int default 0,
  is_active   boolean default true,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);
create index if not exists idx_officers_post_id on public.officers(post_id);

-- ================================================================
-- TABLE 7: GALLERY
-- ================================================================
create table if not exists public.gallery (
  id          uuid primary key default gen_random_uuid(),
  post_id     uuid references public.posts(id),
  photo_url   text not null,
  image_url   text,
  caption     text,
  category    text,
  storage_path text,
  is_active   boolean default true,
  sort_order  int default 0,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);
create index if not exists idx_gallery_post_id on public.gallery(post_id);

-- ================================================================
-- TABLE 8: ANNOUNCEMENTS
-- ================================================================
create table if not exists public.announcements (
  id         uuid primary key default gen_random_uuid(),
  post_id    uuid references public.posts(id),
  title      text not null,
  body       text,
  category   text default 'General',
  is_active  boolean default true,
  expires_at date,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
create index if not exists idx_announcements_post_id on public.announcements(post_id);

-- ================================================================
-- TABLE 9: STAFF
-- ================================================================
create table if not exists public.staff (
  id          uuid primary key default gen_random_uuid(),
  post_id     uuid references public.posts(id),
  full_name   text not null,
  role        text not null,
  staff_type  text default 'employee'
    check (staff_type in ('employee','volunteer','contractor','bartender','manager','maintenance')),
  department  text,
  email       text,
  phone       text,
  photo_url   text,
  bio         text,
  branch_of_service text,
  start_date  date,
  end_date    date,
  hourly_rate numeric(8,2),
  is_active   boolean default true,
  sort_order  int default 0,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);
create index if not exists idx_staff_post_id on public.staff(post_id);

-- ================================================================
-- TABLE 10: INVENTORY
-- ================================================================
create table if not exists public.inventory (
  id             uuid primary key default gen_random_uuid(),
  post_id        uuid references public.posts(id),
  item_name      text not null,
  category       text default 'General',
  quantity       int default 0,
  unit           text default 'each',
  min_quantity   int default 0,
  max_quantity   int,
  cost_per_unit  numeric(10,2),
  location       text,
  supplier       text,
  sku            text,
  notes          text,
  is_active      boolean default true,
  last_restocked date,
  created_at     timestamptz default now(),
  updated_at     timestamptz default now()
);
create index if not exists idx_inventory_post_id on public.inventory(post_id);

-- ================================================================
-- TABLE 11: BARTENDER SCHEDULE
-- ================================================================
create table if not exists public.bartender_schedule (
  id           uuid primary key default gen_random_uuid(),
  post_id      uuid references public.posts(id),
  staff_id     uuid references public.staff(id) on delete set null,
  event_id     uuid references public.events(id) on delete set null,
  shift_date   date not null,
  start_time   time,
  end_time     time,
  role         text default 'Bartender',
  notes        text,
  status       text default 'scheduled'
    check (status in ('scheduled','confirmed','completed','cancelled','no_show')),
  created_at   timestamptz default now(),
  updated_at   timestamptz default now()
);
create index if not exists idx_bartender_post_id on public.bartender_schedule(post_id);

-- ================================================================
-- TABLE 12: BUILDING MAINTENANCE
-- ================================================================
create table if not exists public.building_maintenance (
  id              uuid primary key default gen_random_uuid(),
  post_id         uuid references public.posts(id),
  title           text not null,
  description     text,
  priority        text default 'Medium'
    check (priority in ('Low','Medium','High','Urgent')),
  status          text default 'Open'
    check (status in ('Open','In Progress','Completed','Cancelled','On Hold')),
  location        text,
  assigned_to     text,
  assigned_staff  uuid references public.staff(id) on delete set null,
  reported_date   date,
  due_date        date,
  completed_date  date,
  estimated_cost  numeric(10,2),
  actual_cost     numeric(10,2),
  photo_url       text,
  notes           text,
  created_at      timestamptz default now(),
  updated_at      timestamptz default now()
);
create index if not exists idx_maintenance_post_id on public.building_maintenance(post_id);

-- ================================================================
-- TABLE 13: BINGO EVENTS
-- ================================================================
create table if not exists public.bingo_events (
  id           uuid primary key default gen_random_uuid(),
  post_id      uuid references public.posts(id),
  event_name   text not null,
  event_date   date not null,
  start_time   time,
  max_players  int default 100,
  entry_fee    numeric(8,2) default 5.00,
  prize_pool   numeric(10,2),
  status       text default 'scheduled'
    check (status in ('scheduled','active','completed','cancelled')),
  notes        text,
  created_at   timestamptz default now(),
  updated_at   timestamptz default now()
);
create index if not exists idx_bingo_post_id on public.bingo_events(post_id);

-- ================================================================
-- TABLE 14: BINGO PLAYERS
-- ================================================================
create table if not exists public.bingo_players (
  id         uuid primary key default gen_random_uuid(),
  post_id    uuid references public.posts(id),
  event_id   uuid references public.bingo_events(id) on delete cascade,
  player_name text not null,
  phone      text,
  cards_purchased int default 1,
  amount_paid numeric(8,2),
  checked_in boolean default false,
  created_at timestamptz default now()
);
create index if not exists idx_bingo_players_post_id  on public.bingo_players(post_id);
create index if not exists idx_bingo_players_event_id on public.bingo_players(event_id);

-- ================================================================
-- TABLE 15: BINGO GAMES
-- ================================================================
create table if not exists public.bingo_games (
  id          uuid primary key default gen_random_uuid(),
  post_id     uuid references public.posts(id),
  event_id    uuid references public.bingo_events(id) on delete cascade,
  game_number int default 1,
  pattern     text default 'Any Line',
  prize_amount numeric(8,2),
  status      text default 'pending'
    check (status in ('pending','active','completed','cancelled')),
  winner_id   uuid,
  winner_name text,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);
create index if not exists idx_bingo_games_post_id  on public.bingo_games(post_id);
create index if not exists idx_bingo_games_event_id on public.bingo_games(event_id);

-- ================================================================
-- TABLE 16: BINGO CARDS
-- ================================================================
create table if not exists public.bingo_cards (
  id          uuid primary key default gen_random_uuid(),
  post_id     uuid references public.posts(id),
  event_id    uuid references public.bingo_events(id) on delete cascade,
  player_id   uuid references public.bingo_players(id) on delete cascade,
  card_number int,
  card_data   jsonb,
  is_winner   boolean default false,
  created_at  timestamptz default now()
);
create index if not exists idx_bingo_cards_post_id on public.bingo_cards(post_id);

-- ================================================================
-- TABLE 17: BINGO CALLS
-- ================================================================
create table if not exists public.bingo_calls (
  id         uuid primary key default gen_random_uuid(),
  post_id    uuid references public.posts(id),
  event_id   uuid references public.bingo_events(id) on delete cascade,
  game_id    uuid references public.bingo_games(id) on delete cascade,
  call_value text not null,
  call_order int,
  called_at  timestamptz default now()
);
create index if not exists idx_bingo_calls_post_id on public.bingo_calls(post_id);

-- ================================================================
-- TABLE 18: BINGO WINNERS
-- ================================================================
create table if not exists public.bingo_winners (
  id           uuid primary key default gen_random_uuid(),
  post_id      uuid references public.posts(id),
  event_id     uuid references public.bingo_events(id) on delete cascade,
  game_id      uuid references public.bingo_games(id) on delete cascade,
  player_id    uuid references public.bingo_players(id) on delete set null,
  winner_name  text not null,
  prize_amount numeric(8,2),
  pattern_won  text,
  verified     boolean default false,
  created_at   timestamptz default now()
);
create index if not exists idx_bingo_winners_post_id on public.bingo_winners(post_id);

-- ================================================================
-- TABLE 19: DONATIONS / PAYMENTS
-- ================================================================
create table if not exists public.donations (
  id              uuid primary key default gen_random_uuid(),
  post_id         uuid references public.posts(id),
  donor_name      text,
  donor_email     text,
  donor_phone     text,
  amount          numeric(10,2) not null,
  payment_method  text default 'cash'
    check (payment_method in ('cash','check','card','online','stripe','paypal','other')),
  purpose         text,
  notes           text,
  is_anonymous    boolean default false,
  is_recurring    boolean default false,
  receipt_number  text,
  status          text default 'completed'
    check (status in ('pending','completed','refunded','failed')),
  transaction_id  text,
  created_at      timestamptz default now(),
  updated_at      timestamptz default now()
);
create index if not exists idx_donations_post_id on public.donations(post_id);

-- ================================================================
-- TABLE 20: DOCUMENTS / UPLOADS
-- ================================================================
create table if not exists public.documents (
  id           uuid primary key default gen_random_uuid(),
  post_id      uuid references public.posts(id),
  staff_id     uuid references public.staff(id) on delete set null,
  title        text not null,
  doc_type     text default 'General',
  file_url     text,
  storage_path text,
  file_size_kb int,
  notes        text,
  expires_at   date,
  is_active    boolean default true,
  created_at   timestamptz default now(),
  updated_at   timestamptz default now()
);
create index if not exists idx_documents_post_id on public.documents(post_id);

-- ================================================================
-- TABLE 21: TRAINING / CERTIFICATIONS
-- ================================================================
create table if not exists public.staff_training (
  id                  uuid primary key default gen_random_uuid(),
  post_id             uuid references public.posts(id),
  staff_id            uuid references public.staff(id) on delete cascade,
  course_name         text not null,
  provider            text,
  completion_date     date,
  expiration_date     date,
  certificate_url     text,
  storage_path        text,
  status              text default 'active'
    check (status in ('active','expired','in_progress','pending')),
  notes               text,
  created_at          timestamptz default now(),
  updated_at          timestamptz default now()
);
create index if not exists idx_training_post_id  on public.staff_training(post_id);
create index if not exists idx_training_staff_id on public.staff_training(staff_id);

-- ================================================================
-- TABLE 22: HOME PAGE CONTENT
-- ================================================================
create table if not exists public.home_content (
  id             uuid primary key default gen_random_uuid(),
  post_id        uuid references public.posts(id) unique,
  hero_title     text,
  hero_subtitle  text,
  hero_image_url text,
  mission_text   text,
  about_text     text,
  hours_text     text,
  contact_notes  text,
  show_bingo     boolean default true,
  show_events    boolean default true,
  show_rental    boolean default true,
  show_gallery   boolean default true,
  updated_at     timestamptz default now()
);
create index if not exists idx_home_content_post_id on public.home_content(post_id);

-- Seed default home content for Post 300
insert into public.home_content (post_id, hero_title, hero_subtitle, mission_text)
  select id,
    'William J. Bordelon American Legion Post 300',
    'Honoring Those Who Served — San Antonio, Texas',
    'Serving veterans and the San Antonio community since 1995. God, Country, and Community.'
  from public.posts where post_slug = 'amlpost300'
  on conflict (post_id) do nothing;

-- ================================================================
-- STORAGE BUCKET SETUP (run in Supabase Dashboard > Storage)
-- Or use the SQL below via the storage schema
-- ================================================================
-- NOTE: Bucket creation must be done via Supabase Dashboard
-- Go to: Storage > New Bucket > "amlpost300" > Public: true
-- Then create folders: officers, staff, gallery, events,
--   hall-rental, bingo, documents, maintenance, training

-- ================================================================
-- SEED: POST 300 OFFICERS (publicly listed)
-- ================================================================
insert into public.officers (post_id, name, full_name, title, position, sort_order, is_active)
select
  p.id,
  v.name, v.name, v.title, v.title, v.sort_order, true
from public.posts p,
(values
  ('Jack Caniglia',  'Commander',             1),
  ('Malcolm Wright', '1st Vice Commander',    2),
  ('Scottie Clark',  'Adjutant',              3),
  ('Michael Veile',  'Judge Advocate',        4),
  ('Karl Hammerle',  'Finance Officer',       5),
  ('James Burleigh', 'Chaplain / Sgt-at-Arms',6),
  ('John Grunalt',   'Historian',             7),
  ('Amanda Acebo',   'Service Officer',       8)
) as v(name, title, sort_order)
where p.post_slug = 'amlpost300'
  and not exists (
    select 1 from public.officers o
    where o.post_id = p.id and o.name = v.name
  );

-- ================================================================
-- VERIFY
-- ================================================================
select
  p.post_slug,
  p.post_name,
  pp.plan_name,
  pp.billing_status,
  (select count(*) from public.officers o where o.post_id = p.id) as officers,
  (select count(*) from public.events  e where e.post_id = p.id) as events
from public.posts p
left join public.post_plans pp on pp.post_id = p.id
where p.post_slug = 'amlpost300';

-- ================================================================
-- DONE — 22-table schema fully deployed for Post 300
-- ================================================================
