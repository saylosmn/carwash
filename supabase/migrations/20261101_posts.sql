begin;
create table if not exists public.posts (
 id uuid primary key default gen_random_uuid(),
 created_at timestamptz not null default now(),
 caption text not null check (char_length(trim(caption)) between 1 and 2000),
 image_path text not null check (image_path ~ '^[a-f0-9-]+\.(jpg|png|webp)$'),
 published boolean not null default true
);
alter table public.posts enable row level security;
revoke all on public.posts from anon, authenticated;
grant select on public.posts to anon, authenticated;
grant insert, update, delete on public.posts to authenticated;
create policy "published posts are readable" on public.posts for select to anon, authenticated using (published);
create policy "admins manage posts" on public.posts for all to authenticated
 using (exists(select 1 from public.admin_users where user_id = (select auth.uid())))
 with check (exists(select 1 from public.admin_users where user_id = (select auth.uid())));
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
 values('post-images','post-images',true,5242880,array['image/jpeg','image/png','image/webp'])
 on conflict(id) do update set public=true,file_size_limit=5242880,allowed_mime_types=array['image/jpeg','image/png','image/webp'];
create policy "admins manage post images" on storage.objects for all to authenticated
 using (bucket_id='post-images' and exists(select 1 from public.admin_users where user_id=(select auth.uid())))
 with check (bucket_id='post-images' and exists(select 1 from public.admin_users where user_id=(select auth.uid())));
commit;
