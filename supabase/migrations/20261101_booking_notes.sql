-- Additive wrapper: notes and booking commit together; existing clients still work.
create or replace function public.book_visit_with_notes(
 p_name text,p_phone text,p_vehicle_type text,p_vehicle_model text,p_plate text,
 p_service text,p_address text,p_latitude double precision,p_longitude double precision,
 p_date date,p_hour integer,p_notes text
) returns table(id uuid, access_token uuid)
language plpgsql security definer set search_path = public, pg_temp as $$
declare booked record;
begin
 if char_length(trim(p_notes)) not between 1 and 1000 then raise exception 'INVALID_NOTES'; end if;
 select * into booked from public.book_visit(p_name,p_phone,p_vehicle_type,p_vehicle_model,p_plate,
 p_service,p_address,p_latitude,p_longitude,p_date,p_hour);
 insert into public.booking_messages(booking_id,sender,body) values(booked.id,'customer',trim(p_notes));
 return query select booked.id::uuid,booked.access_token::uuid;
end $$;
revoke all on function public.book_visit_with_notes(text,text,text,text,text,text,text,double precision,double precision,date,integer,text) from public;
grant execute on function public.book_visit_with_notes(text,text,text,text,text,text,text,double precision,double precision,date,integer,text) to anon;
