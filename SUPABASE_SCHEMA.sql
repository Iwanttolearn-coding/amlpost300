-- ================================================================
-- AMERICAN LEGION POST 300 — William J. Bordelon Post
-- Supabase Database Schema
-- San Antonio, TX 78245
-- ================================================================
-- Run this entire file in your Supabase SQL Editor after creating
-- a NEW Supabase project for Post 300.
-- ================================================================

-- SITE MEMBERS
create table if not exists public.site_members (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  email text,
  phone text,
  date_of_birth date,
  membership_type text default 'American Legion',
  membership_status text default 'pending' check (membership_status in ('pending','active','inactive','expired')),
  role text default 'member' check (role in ('member','admin','officer')),
  branch_of_service text,
  years_of_service int,
  address text,
  city text default 'San Antonio',
  zip_code text,
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- HALL RENTAL INQUIRIES
create table if not exists public.hall_rental_inquiries (
  id uuid primary key default gen_random_uuid(),
  contact_name text not null,
  contact_email text,
  contact_phone text,
  event_date date,
  event_type text,
  start_time text,
  end_time text,
  guest_count int,
  status text default 'pending' check (status in ('pending','confirmed','approved','cancelled')),
  notes text,
  admin_notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- EVENTS
create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  event_date date not null,
  event_type text default 'Social',
  start_time text,
  end_time text,
  description text,
  location text default '3290 Grosenbacher Rd, San Antonio, TX 78245',
  is_public boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- OFFICERS
create table if not exists public.officers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  full_name text,
  title text not null,
  position text,
  email text,
  phone text,
  photo_url text,
  bio text,
  sort_order int default 0,
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- GALLERY
create table if not exists public.gallery (
  id uuid primary key default gen_random_uuid(),
  photo_url text,
  image_url text,
  caption text,
  category text default 'General',
  is_active boolean default true,
  created_at timestamptz default now()
);

-- ANNOUNCEMENTS
create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text,
  category text default 'General',
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- BINGO EVENTS
create table if not exists public.bingo_events (
  id uuid primary key default gen_random_uuid(),
  event_name text not null,
  event_date date not null,
  start_time text,
  status text default 'scheduled' check (status in ('scheduled','active','completed','cancelled')),
  max_players int default 100,
  entry_fee numeric(10,2) default 5.00,
  prize_pool numeric(10,2) default 0,
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- BINGO PLAYERS
create table if not exists public.bingo_players (
  id uuid primary key default gen_random_uuid(),
  event_id uuid references public.bingo_events(id) on delete cascade,
  player_name text not null,
  card_count int default 1,
  paid boolean default false,
  created_at timestamptz default now()
);

-- STAFF
create table if not exists public.staff (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  role text not null default 'Other',
  staff_type text not null default 'employee',
  department text default 'General',
  email text,
  phone text,
  photo_url text,
  branch_service text,
  start_date date,
  bio text,
  sort_order int default 0,
  is_active boolean default true,
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- INVENTORY
create table if not exists public.inventory (
  id uuid primary key default gen_random_uuid(),
  item_name text not null,
  category text default 'General',
  quantity numeric default 0,
  unit text default 'each',
  min_quantity numeric default 0,
  max_quantity numeric,
  location text,
  supplier text,
  cost_per_unit numeric(10,2) default 0,
  notes text,
  last_restocked date,
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- BARTENDER SCHEDULE
create table if not exists public.bartender_schedule (
  id uuid primary key default gen_random_uuid(),
  event_id uuid references public.events(id) on delete set null,
  staff_id uuid references public.staff(id) on delete cascade,
  shift_date date not null,
  shift_start time,
  shift_end time,
  role_that_night text,
  station text,
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- STAFF TRAINING
create table if not exists public.staff_training (
  id uuid primary key default gen_random_uuid(),
  staff_id uuid references public.staff(id) on delete cascade,
  training_name text not null,
  provider text,
  certificate_url text,
  completed boolean default false,
  completion_date date,
  expiration_date date,
  notes text,
  created_at timestamptz default now()
);

-- STAFF DOCUMENTS
create table if not exists public.staff_documents (
  id uuid primary key default gen_random_uuid(),
  staff_id uuid references public.staff(id) on delete cascade,
  document_type text,
  title text,
  file_url text,
  expiration_date date,
  created_at timestamptz default now()
);

-- STAFF AVAILABILITY
create table if not exists public.staff_availability (
  id uuid primary key default gen_random_uuid(),
  staff_id uuid references public.staff(id) on delete cascade,
  day_of_week int,
  available_start time,
  available_end time,
  unavailable boolean default false,
  notes text
);

-- STAFF TIME OFF
create table if not exists public.staff_time_off (
  id uuid primary key default gen_random_uuid(),
  staff_id uuid references public.staff(id) on delete cascade,
  start_date date not null,
  end_date date not null,
  reason text,
  approved boolean default false,
  notes text,
  created_at timestamptz default now()
);

-- BUILDING MAINTENANCE
create table if not exists public.building_maintenance (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  category text default 'General',
  priority text default 'Medium',
  status text default 'Open',
  assigned_staff_id uuid references public.staff(id) on delete set null,
  location text,
  due_date date,
  completed_date date,
  photo_url text,
  admin_notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ================================================================
-- INDEXES
-- ================================================================
create index if not exists idx_p300_events_date on public.events(event_date);
create index if not exists idx_p300_rentals_date on public.hall_rental_inquiries(event_date);
create index if not exists idx_p300_rentals_status on public.hall_rental_inquiries(status);
create index if not exists idx_p300_members_status on public.site_members(membership_status);
create index if not exists idx_p300_officers_sort on public.officers(sort_order);
create index if not exists idx_p300_staff_active on public.staff(is_active);
create index if not exists idx_p300_inventory_stock on public.inventory(quantity, min_quantity);
create index if not exists idx_p300_maintenance_status on public.building_maintenance(status);
create index if not exists idx_p300_bingo_date on public.bingo_events(event_date);

-- ================================================================
-- SEED DEFAULT OFFICERS (publicly available data)
-- ================================================================
insert into public.officers (name, full_name, title, position, sort_order, is_active) values
  ('Jack Caniglia',   'Jack Caniglia',   'Commander',           'Commander',           1, true),
  ('Malcolm Wright',  'Malcolm Wright',  '1st Vice Commander',  '1st Vice Commander',  2, true),
  ('Scottie Clark',   'Scottie Clark',   'Adjutant',            'Adjutant',            3, true),
  ('Michael Veile',   'Michael Veile',   'Judge Advocate',      'Judge Advocate',      4, true),
  ('Karl Hammerle',   'Karl Hammerle',   'Finance Officer',     'Finance Officer',     5, true),
  ('James Burleigh',  'James Burleigh',  'Chaplain / Sgt-at-Arms', 'Chaplain',         6, true),
  ('John Grunalt',    'John Grunalt',    'Historian',           'Historian',           7, true),
  ('Amanda Acebo',    'Amanda Acebo',    'Service Officer',     'Service Officer',     8, true)
on conflict do nothing;

-- ================================================================
-- SEED WELCOME ANNOUNCEMENT
-- ================================================================
insert into public.announcements (title, body, category, is_active) values
  ('Welcome to Post 300 — William J. Bordelon Post!',
   'Welcome to the official website of American Legion Post 300, named in honor of Medal of Honor recipient Staff Sergeant William James Bordelon. Located at 3290 Grosenbacher Road, San Antonio, TX. Call us at (210) 674-3364.',
   'General', true)
on conflict do nothing;

-- ================================================================
-- SEED SAMPLE RECURRING EVENTS
-- ================================================================
insert into public.events (title, event_date, event_type, start_time, description) values
  ('$2 Tuesday', '2026-07-07', 'Social', '17:00', '$2 drinks all night at the canteen!'),
  ('Whiskey Wednesday', '2026-07-08', 'Social', '18:00', 'Weekly whiskey tasting and social night.'),
  ('Dungeons & Dragons Night', '2026-07-10', 'Social', '18:00', 'Join our weekly D&D campaign. All experience levels welcome.'),
  ('Commander''s Night', '2026-07-11', 'Meeting', '19:00', 'Monthly Commander''s Night — all members welcome.'),
  ('Executive Board Meeting', '2026-07-14', 'Meeting', '18:00', 'Monthly executive board meeting for Post 300 officers.'),
  ('BINGO Night', '2026-07-15', 'Bingo', '19:00', 'Fun bingo night open to members and guests. Great prizes!'),
  ('$2 Tuesday', '2026-07-14', 'Social', '17:00', '$2 drinks all night at the canteen!'),
  ('Whiskey Wednesday', '2026-07-15', 'Social', '18:00', 'Weekly whiskey tasting and social night.'),
  ('Veterans Memorial Ceremony', '2026-07-20', 'Memorial', '10:00', 'Monthly memorial ceremony honoring our fallen heroes.'),
  ('Fundraiser Night', '2026-07-25', 'Fundraiser', '17:00', 'Monthly fundraiser supporting veteran assistance programs.')
on conflict do nothing;
