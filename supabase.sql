-- MM MATERIAL MANAGEMENT | SHIFT TAM | Supabase schema
-- Run this script in Supabase Dashboard > SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.material_bom (
  id uuid primary key default gen_random_uuid(),
  model text not null,
  code text not null,
  remark text,
  norm_qty numeric(18,4) not null check (norm_qty >= 0),
  unit text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists material_bom_code_idx on public.material_bom(code);
create index if not exists material_bom_model_idx on public.material_bom(model);

create table if not exists public.material_prices (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  unit_price numeric(18,4) not null check (unit_price >= 0),
  currency text not null default 'VND',
  supplier text,
  effective_date date not null default current_date,
  created_at timestamptz not null default now()
);
create index if not exists material_prices_code_date_idx
  on public.material_prices(code, effective_date desc);

create table if not exists public.material_over (
  id uuid primary key default gen_random_uuid(),
  work_date date not null,
  model text not null,
  code text not null,
  actual_qty numeric(18,4) not null check (actual_qty >= 0),
  note text,
  created_at timestamptz not null default now()
);
create index if not exists material_over_date_idx on public.material_over(work_date desc);
create index if not exists material_over_code_idx on public.material_over(code);

-- View: resolve BOM norm and latest applicable price for each OVER record.
create or replace view public.v_material_over_calculated as
select
  o.id,
  o.work_date,
  o.model,
  o.code,
  o.actual_qty,
  o.note,
  o.created_at,
  b.norm_qty,
  case
    when b.id is null then null
    else greatest(o.actual_qty - b.norm_qty, 0)::numeric(18,4)
  end as excess_qty,
  p.unit_price,
  case
    when b.id is null or p.id is null then null
    else (greatest(o.actual_qty - b.norm_qty, 0) * p.unit_price)::numeric(18,4)
  end as excess_cost,
  (b.id is not null) as bom_found,
  (p.id is not null) as price_found
from public.material_over o
left join lateral (
  select mb.id, mb.norm_qty
  from public.material_bom mb
  where mb.code = o.code
    and (
      trim(mb.model) = trim(o.model)
      or o.model = any(string_to_array(replace(mb.model, ' ', ''), '.'))
    )
  order by
    case when trim(mb.model) = trim(o.model) then 0 else 1 end,
    mb.created_at desc
  limit 1
) b on true
left join lateral (
  select mp.id, mp.unit_price
  from public.material_prices mp
  where mp.code = o.code
    and mp.effective_date <= o.work_date
  order by mp.effective_date desc, mp.created_at desc
  limit 1
) p on true;

-- Enable RLS. Authenticated users can access the app data.
alter table public.material_bom enable row level security;
alter table public.material_prices enable row level security;
alter table public.material_over enable row level security;

drop policy if exists "authenticated_all_material_bom" on public.material_bom;
create policy "authenticated_all_material_bom" on public.material_bom
for all to authenticated using (true) with check (true);

drop policy if exists "authenticated_all_material_prices" on public.material_prices;
create policy "authenticated_all_material_prices" on public.material_prices
for all to authenticated using (true) with check (true);

drop policy if exists "authenticated_all_material_over" on public.material_over;
create policy "authenticated_all_material_over" on public.material_over
for all to authenticated using (true) with check (true);

grant select, insert, update, delete on public.material_bom to authenticated;
grant select, insert, update, delete on public.material_prices to authenticated;
grant select, insert, update, delete on public.material_over to authenticated;
grant select on public.v_material_over_calculated to authenticated;
