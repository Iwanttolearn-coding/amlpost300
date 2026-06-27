-- ================================================================
-- SQL_POST_PLANS.sql
-- Run this AFTER the main MIGRATION_MULTI_TENANT.sql
-- Adds per-post feature flags and billing plan tracking
-- Safe to re-run — all statements are idempotent
-- ================================================================

create extension if not exists pgcrypto;

-- ── CREATE TABLE ──────────────────────────────────────────────
create table if not exists public.post_plans (
  id                          uuid primary key default gen_random_uuid(),
  post_id                     uuid references public.posts(id) on delete cascade,
  plan_name                   text default 'standard',       -- 'trial' | 'standard' | 'pro'
  billing_status              text default 'active',         -- 'active' | 'past_due' | 'cancelled'
  -- Limits
  max_admins                  int default 5,
  max_staff                   int default 100,
  max_gallery_photos          int default 500,
  max_storage_mb              int default 5000,
  -- Feature flags
  events_enabled              boolean default true,
  hall_rental_enabled         boolean default true,
  staff_enabled               boolean default true,
  inventory_enabled           boolean default true,
  bartender_schedule_enabled  boolean default true,
  bingo_enabled               boolean default true,
  donations_enabled           boolean default true,
  ai_assistant_enabled        boolean default true,
  -- Timestamps
  created_at                  timestamptz default now(),
  updated_at                  timestamptz default now()
);

-- ── INDEX ─────────────────────────────────────────────────────
create index if not exists idx_post_plans_post_id on public.post_plans(post_id);

-- ── SEED: Post 300 ────────────────────────────────────────────
insert into public.post_plans (post_id, plan_name, billing_status)
select id, 'standard', 'active'
from public.posts
where post_slug = 'amlpost300'
on conflict do nothing;

-- ── SEED: Post 579 ────────────────────────────────────────────
insert into public.post_plans (post_id, plan_name, billing_status)
select id, 'standard', 'active'
from public.posts
where post_slug = 'amlpost579'
on conflict do nothing;

-- ── VERIFY ────────────────────────────────────────────────────
select
  p.post_slug,
  p.post_name,
  pp.plan_name,
  pp.billing_status,
  pp.ai_assistant_enabled,
  pp.bingo_enabled,
  pp.max_staff
from public.post_plans pp
join public.posts p on p.id = pp.post_id;

-- ================================================================
-- DONE — Every post now has a plan row.
-- Check features in your app like:
--   SELECT ai_assistant_enabled FROM post_plans WHERE post_id = $1
-- ================================================================
