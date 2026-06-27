CREATE TABLE IF NOT EXISTS posts (
  id SERIAL PRIMARY KEY,
  post_slug TEXT UNIQUE NOT NULL,
  post_name TEXT NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  admin_password_hash TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS post_records (
  id SERIAL PRIMARY KEY,
  post_id INTEGER NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  record_type TEXT NOT NULL,
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS post_records_type_idx ON post_records(post_id, record_type);
CREATE INDEX IF NOT EXISTS post_records_data_gin_idx ON post_records USING GIN (data);

INSERT INTO posts (post_slug, post_name, is_active)
VALUES ('amlpost300', 'American Legion Post 300', TRUE)
ON CONFLICT (post_slug) DO UPDATE SET post_name = EXCLUDED.post_name, is_active = TRUE;

INSERT INTO post_records (post_id, record_type, data)
SELECT p.id, seed.record_type, seed.data::jsonb
FROM posts p
CROSS JOIN (VALUES
  ('announcement', '{"title":"Welcome to Post 300","body":"Serving veterans, families, and the San Antonio community from the William J. Bordelon Post.","category":"General","is_active":true}'),
  ('announcement', '{"title":"Hall rentals open","body":"Submit a rental inquiry online and the post team will follow up with availability and pricing.","category":"Hall","is_active":true}'),
  ('event', '{"title":"Bingo Night","event_date":"2026-07-03","start_time":"18:30","event_type":"Bingo","location":"Post 300 Hall","description":"Weekly bingo with food, fellowship, and prizes."}'),
  ('event', '{"title":"Post Membership Meeting","event_date":"2026-07-08","start_time":"19:00","event_type":"Meeting","location":"Post 300 Hall","description":"Monthly post business meeting."}'),
  ('event', '{"title":"Whiskey Wednesday","event_date":"2026-07-15","start_time":"18:00","event_type":"Social","location":"Canteen","description":"Midweek canteen social."}'),
  ('officer', '{"full_name":"Commander","title":"Post Commander","email":"","phone":"","sort_order":1,"is_active":true}'),
  ('officer', '{"full_name":"Adjutant","title":"Post Adjutant","email":"","phone":"","sort_order":2,"is_active":true}'),
  ('officer', '{"full_name":"Service Officer","title":"Veterans Service Officer","email":"","phone":"","sort_order":3,"is_active":true}'),
  ('gallery', '{"photo_url":"https://media.base44.com/images/public/6a3d2806f16fa7f06a81b78e/bf3c44271_IMG_7553.jpg","caption":"Post 300 gathering","category":"Post","is_active":true,"sort_order":1}'),
  ('gallery', '{"photo_url":"https://media.base44.com/images/public/6a3d2806f16fa7f06a81b78e/aaa850338_IMG_7552.jpg","caption":"Post 300 hall","category":"Hall","is_active":true,"sort_order":2}'),
  ('gallery', '{"photo_url":"https://media.base44.com/images/public/6a3d2806f16fa7f06a81b78e/a01186b23_IMG_7551.jpg","caption":"Post 300 community","category":"Community","is_active":true,"sort_order":3}'),
  ('inventory', '{"item_name":"Bingo paper","quantity":42,"min_quantity":20,"category":"Games"}'),
  ('inventory', '{"item_name":"Canteen cups","quantity":180,"min_quantity":75,"category":"Canteen"}'),
  ('staff', '{"full_name":"Volunteer Coordinator","role":"Volunteer Lead","staff_type":"Volunteer","is_active":true}'),
  ('bingo_event', '{"title":"Friday Bingo","event_date":"2026-07-03","start_time":"18:30","price":"Cards from $5"}'),
  ('bingo_winner', '{"winner_name":"Recent winner","game_title":"Coverall","prize":"Post jackpot","won_at":"2026-06-19"}')
) AS seed(record_type, data)
WHERE p.post_slug = 'amlpost300'
AND NOT EXISTS (
  SELECT 1 FROM post_records r WHERE r.post_id = p.id AND r.record_type = seed.record_type AND r.data->>'title' = seed.data::jsonb->>'title'
);
