-- Run once in a new Supabase project's SQL editor.
create extension if not exists pgcrypto;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  access_token uuid not null unique default gen_random_uuid(),
  created_at timestamptz not null default now(),
  name text not null check (char_length(name) between 2 and 80),
  phone text not null check (phone ~ '^[0-9+() -]{8,20}$'),
  vehicle_type text not null check (vehicle_type in ('sedan','suv','van')),
  vehicle_model text not null check (char_length(vehicle_model) between 2 and 80),
  plate text not null check (char_length(plate) between 2 and 24),
  service text not null check (service in ('exterior','interior','full')),
  address text not null check (char_length(address) between 8 and 500),
  latitude double precision check (latitude between -90 and 90),
  longitude double precision check (longitude between -180 and 180),
  booking_date date not null,
  booking_hour integer not null check (booking_hour between 0 and 23),
  status text not null default 'new' check (status in ('new','confirmed','on_way','done','cancelled')),
  quote_amount integer check (quote_amount between 0 and 100000000),
  quote_status text not null default 'pending' check (quote_status in ('pending','offered','accepted','declined')),
  admin_note text not null default ''
);
create index if not exists bookings_schedule_idx on public.bookings(booking_date, booking_hour);
create table if not exists public.booking_messages (
  id bigint generated always as identity primary key,
  booking_id uuid not null references public.bookings(id) on delete cascade,
  sender text not null check (sender in ('customer','admin')),
  body text not null check (char_length(body) between 1 and 1000),
  created_at timestamptz not null default now()
);
create index if not exists booking_messages_booking_idx on public.booking_messages(booking_id, created_at);

alter table public.admin_users enable row level security;
alter table public.bookings enable row level security;
alter table public.booking_messages enable row level security;
revoke all on public.admin_users, public.bookings, public.booking_messages from anon, authenticated;
grant select on public.admin_users to authenticated;
grant select, update on public.bookings to authenticated;
grant select, insert on public.booking_messages to authenticated;
grant usage, select on sequence public.booking_messages_id_seq to authenticated;

create policy "own admin membership" on public.admin_users for select to authenticated
  using (user_id = (select auth.uid()));
create policy "admin reads bookings" on public.bookings for select to authenticated
  using (exists (select 1 from public.admin_users where user_id = (select auth.uid())));
create policy "admin updates bookings" on public.bookings for update to authenticated
  using (exists (select 1 from public.admin_users where user_id = (select auth.uid())))
  with check (exists (select 1 from public.admin_users where user_id = (select auth.uid())));
create policy "admin reads messages" on public.booking_messages for select to authenticated
  using (exists (select 1 from public.admin_users where user_id = (select auth.uid())));
create policy "admin sends messages" on public.booking_messages for insert to authenticated
  with check (sender = 'admin' and exists (select 1 from public.admin_users where user_id = (select auth.uid())));

create or replace function public.book_visit(
  p_name text,p_phone text,p_vehicle_type text,p_vehicle_model text,p_plate text,
  p_service text,p_address text,p_latitude double precision,p_longitude double precision,
  p_date date,p_hour integer
) returns table(id uuid, access_token uuid)
language plpgsql security definer set search_path = public, pg_temp as $$
declare v_duration integer; v_start timestamp; v_slot timestamp; v_count integer; v_now timestamp;
begin
  v_now := now() at time zone 'Asia/Ulaanbaatar';
  if p_date < v_now::date or p_date > v_now::date + 60 or p_hour not between 0 and 23 then
    raise exception 'INVALID_SLOT';
  end if;
  v_start := p_date::timestamp + p_hour * interval '1 hour';
  if v_start <= v_now then raise exception 'INVALID_SLOT'; end if;
  v_duration := case when p_service = 'full' then 2 else 1 end;
  perform pg_advisory_xact_lock(hashtext('easycarwash-booking-calendar'));
  for v_slot in select generate_series(v_start, v_start + (v_duration-1) * interval '1 hour', interval '1 hour') loop
    select count(*) into v_count from public.bookings b
      where b.status <> 'cancelled'
      and (b.booking_date::timestamp + b.booking_hour * interval '1 hour') <= v_slot
      and (b.booking_date::timestamp + (b.booking_hour + case when b.service='full' then 2 else 1 end) * interval '1 hour') > v_slot;
    if v_count >= 2 then raise exception 'SLOT_FULL'; end if;
  end loop;
  return query insert into public.bookings
    (name,phone,vehicle_type,vehicle_model,plate,service,address,latitude,longitude,booking_date,booking_hour)
    values (trim(p_name),trim(p_phone),p_vehicle_type,trim(p_vehicle_model),trim(p_plate),p_service,
      trim(p_address),p_latitude,p_longitude,p_date,p_hour)
    returning bookings.id,bookings.access_token;
end $$;
revoke all on function public.book_visit(text,text,text,text,text,text,text,double precision,double precision,date,integer) from public;
grant execute on function public.book_visit(text,text,text,text,text,text,text,double precision,double precision,date,integer) to anon;

create or replace function public.available_hours(p_date date,p_service text)
returns table(hour integer, available boolean) language plpgsql security definer set search_path = public, pg_temp as $$
declare h integer; v_slot timestamp; v_start timestamp; v_now timestamp; n integer; duration integer; okay boolean;
begin
  v_now := now() at time zone 'Asia/Ulaanbaatar';
  duration := case when p_service = 'full' then 2 else 1 end;
  for h in 0..23 loop
    v_start := p_date::timestamp + h * interval '1 hour';
    okay := p_date between v_now::date and v_now::date + 60 and v_start > v_now;
    if okay then
      for v_slot in select generate_series(v_start, v_start + (duration-1) * interval '1 hour', interval '1 hour') loop
        select count(*) into n from public.bookings b where b.status <> 'cancelled'
          and (b.booking_date::timestamp + b.booking_hour * interval '1 hour') <= v_slot
          and (b.booking_date::timestamp + (b.booking_hour + case when b.service='full' then 2 else 1 end) * interval '1 hour') > v_slot;
        if n >= 2 then okay := false; end if;
      end loop;
    end if;
    hour := h; available := okay; return next;
  end loop;
end $$;
revoke all on function public.available_hours(date,text) from public;
grant execute on function public.available_hours(date,text) to anon, authenticated;

create or replace function public.customer_booking(p_token uuid)
returns jsonb language sql security definer set search_path = public, pg_temp as $$
  select jsonb_build_object('booking',to_jsonb(b) - 'access_token' - 'admin_note',
    'messages',coalesce((select jsonb_agg(to_jsonb(m) order by m.created_at) from public.booking_messages m where m.booking_id=b.id),'[]'::jsonb))
  from public.bookings b where b.access_token=p_token limit 1
$$;
revoke all on function public.customer_booking(uuid) from public;
grant execute on function public.customer_booking(uuid) to anon;

create or replace function public.customer_message(p_token uuid,p_body text)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
declare v_id uuid;
begin
  select id into v_id from public.bookings where access_token=p_token;
  if v_id is null or char_length(trim(p_body)) not between 1 and 1000 then raise exception 'INVALID_MESSAGE'; end if;
  insert into public.booking_messages(booking_id,sender,body) values(v_id,'customer',trim(p_body));
end $$;
revoke all on function public.customer_message(uuid,text) from public;
grant execute on function public.customer_message(uuid,text) to anon;

create or replace function public.respond_quote(p_token uuid,p_accept boolean)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
begin
  update public.bookings set quote_status=case when p_accept then 'accepted' else 'declined' end
  where access_token=p_token and quote_status='offered';
  if not found then raise exception 'QUOTE_UNAVAILABLE'; end if;
end $$;
revoke all on function public.respond_quote(uuid,boolean) from public;
grant execute on function public.respond_quote(uuid,boolean) to anon;

-- After creating an Auth user for the owner, run this in SQL editor:
-- insert into public.admin_users(user_id) select id from auth.users where email = 'OWNER_EMAIL';
