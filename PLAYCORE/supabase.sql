-- Выполните целиком в Supabase -> SQL Editor -> Run

-- 1. Таблица игр
create table if not exists games (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 1 and 40),
  description text check (char_length(description) <= 200),
  category text not null default 'easy' check (category in ('easy','sim','sports')),
  author text check (char_length(author) <= 24),
  file_path text not null,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now()
);
alter table games enable row level security;
create policy "read approved" on games for select using (status = 'approved');
create policy "submit pending" on games for insert with check (status = 'pending');

-- 2. Жалобы
create table if not exists reports (
  id uuid primary key default gen_random_uuid(),
  game_id uuid not null references games(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table reports enable row level security;
create policy "send report" on reports for insert with check (true);

-- 3. Хранилище: публичное, только HTML, до 5 МБ
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('games', 'games', true, 5242880, array['text/html'])
on conflict (id) do update set public = true, file_size_limit = 5242880, allowed_mime_types = array['text/html'];

create policy "upload html games" on storage.objects
  for insert with check (bucket_id = 'games' and name like '%.html');

-- Модерация: в Table Editor -> games поменяйте status с 'pending' на 'approved'
-- (или 'rejected', чтобы отклонить). Жалобы смотрите в таблице reports.
