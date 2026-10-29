-- Run in Supabase SQL Editor to allow booking requests at any hour.
-- Existing bookings and the two-bookings-per-hour limit are preserved.
alter table public.bookings drop constraint if exists bookings_booking_hour_check;
alter table public.bookings add constraint bookings_booking_hour_check check (booking_hour between 0 and 23);

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
