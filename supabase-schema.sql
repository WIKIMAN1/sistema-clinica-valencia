-- ============================================================
-- Clínica Valencia — Supabase schema (v1)
-- Pegar TODO el archivo de una sola vez en Supabase:
-- Dashboard del proyecto -> SQL Editor -> New query -> Run.
-- Requiere: autenticación por email habilitada (por defecto).
-- Los usuarios se crean desde la app con Supabase Auth; las
-- contraseñas NUNCA se guardan en ninguna tabla.
-- ============================================================

-- ---------- Helper: ¿es el doctor? ----------
create or replace function public.is_doctor()
returns boolean language sql stable as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'doctor'
  );
$$;

create or replace function public.is_staff()
returns boolean language sql stable as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('doctor','enfermera')
  );
$$;

-- ---------- profiles (uno por usuario de Auth) ----------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('paciente','doctor','enfermera')),
  full_name text not null,
  whatsapp text,
  birth_date date,
  username text unique,
  must_change_password boolean not null default false,
  created_at timestamptz not null default now()
);
alter table public.profiles enable row level security;
drop policy if exists "profiles self read" on public.profiles;
create policy "profiles self read" on public.profiles
  for select using (auth.uid() = id or public.is_staff());
drop policy if exists "profiles self insert" on public.profiles;
create policy "profiles self insert" on public.profiles
  for insert with check (auth.uid() = id);
drop policy if exists "profiles self update" on public.profiles;
create policy "profiles self update" on public.profiles
  for update using (auth.uid() = id or public.is_doctor());

-- ---------- medical_records (una por paciente) ----------
create table if not exists public.medical_records (
  patient_id uuid primary key references public.profiles(id) on delete cascade,
  blood_type text,
  allergies text,
  base_diseases text,
  medications text,
  surgeries text,
  family_history text,
  habits text,
  vaccines text,
  vitals text,
  weight numeric,
  height numeric,
  bmi numeric,
  pregnancy text,
  updated_by uuid references public.profiles(id),
  updated_at timestamptz not null default now()
);
alter table public.medical_records enable row level security;
drop policy if exists "mr read" on public.medical_records;
create policy "mr read" on public.medical_records
  for select using (auth.uid() = patient_id or public.is_staff());
drop policy if exists "mr write staff" on public.medical_records;
create policy "mr write staff" on public.medical_records
  for all using (public.is_staff()) with check (public.is_staff());

-- ---------- appointments ----------
create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  specialty text not null,
  motivo text,
  date date not null,
  time text,
  status text not null default 'programada',
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);
alter table public.appointments enable row level security;
drop policy if exists "appt read" on public.appointments;
create policy "appt read" on public.appointments
  for select using (auth.uid() = patient_id or public.is_staff());
drop policy if exists "appt insert" on public.appointments;
create policy "appt insert" on public.appointments
  for insert with check (auth.uid() = patient_id or public.is_staff());
drop policy if exists "appt update staff" on public.appointments;
create policy "appt update staff" on public.appointments
  for update using (public.is_staff());

-- ---------- consultations ----------
create table if not exists public.consultations (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  reason text,
  summary text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);
alter table public.consultations enable row level security;
drop policy if exists "cons read" on public.consultations;
create policy "cons read" on public.consultations
  for select using (auth.uid() = patient_id or public.is_staff());
drop policy if exists "cons insert staff" on public.consultations;
create policy "cons insert staff" on public.consultations
  for insert with check (public.is_staff());

-- ---------- exams (v1: metadatos; el archivo NO se sube) ----------
create table if not exists public.exams (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  type text not null,
  file_name text,
  notes text,
  ai_analysis text,
  ai_status text not null default 'pendiente',
  doctor_note text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);
alter table public.exams enable row level security;
drop policy if exists "exams read" on public.exams;
create policy "exams read" on public.exams
  for select using (auth.uid() = patient_id or public.is_staff());
drop policy if exists "exams insert" on public.exams;
create policy "exams insert" on public.exams
  for insert with check (auth.uid() = patient_id or public.is_staff());
drop policy if exists "exams update staff" on public.exams;
create policy "exams update staff" on public.exams
  for update using (public.is_staff());

-- ---------- procedures ----------
create table if not exists public.procedures (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  details text,
  status text not null default 'programado',
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);
alter table public.procedures enable row level security;
drop policy if exists "proc read" on public.procedures;
create policy "proc read" on public.procedures
  for select using (auth.uid() = patient_id or public.is_staff());
drop policy if exists "proc insert staff" on public.procedures;
create policy "proc insert staff" on public.procedures
  for insert with check (public.is_staff());

-- ---------- surgeries ----------
create table if not exists public.surgeries (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  type text not null,
  details text,
  status text not null default 'programada',
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);
alter table public.surgeries enable row level security;
drop policy if exists "surg read" on public.surgeries;
create policy "surg read" on public.surgeries
  for select using (auth.uid() = patient_id or public.is_staff());
drop policy if exists "surg insert staff" on public.surgeries;
create policy "surg insert staff" on public.surgeries
  for insert with check (public.is_staff());

-- ---------- perioperative_plans ----------
create table if not exists public.perioperative_plans (
  id uuid primary key default gen_random_uuid(),
  surgery_id uuid not null references public.surgeries(id) on delete cascade,
  supplies text,
  oms_checklist text,
  diet_proposal text,
  preop_exams text,
  meds_to_suspend text,
  recovery_milestones text,
  created_at timestamptz not null default now()
);
alter table public.perioperative_plans enable row level security;
drop policy if exists "peri read staff" on public.perioperative_plans;
create policy "peri read staff" on public.perioperative_plans
  for select using (public.is_staff());
drop policy if exists "peri insert staff" on public.perioperative_plans;
create policy "peri insert staff" on public.perioperative_plans
  for insert with check (public.is_staff());

-- ---------- inventory ----------
create table if not exists public.inventory_items (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  stock integer not null default 0,
  min_stock integer not null default 0,
  created_at timestamptz not null default now()
);
create table if not exists public.inventory_movements (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.inventory_items(id) on delete cascade,
  qty integer not null,
  reason text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);
alter table public.inventory_items enable row level security;
alter table public.inventory_movements enable row level security;
drop policy if exists "inv read staff" on public.inventory_items;
create policy "inv read staff" on public.inventory_items
  for select using (public.is_staff());
drop policy if exists "inv write doctor" on public.inventory_items;
create policy "inv write doctor" on public.inventory_items
  for all using (public.is_doctor()) with check (public.is_doctor());
drop policy if exists "invmov read staff" on public.inventory_movements;
create policy "invmov read staff" on public.inventory_movements
  for select using (public.is_staff());
drop policy if exists "invmov insert staff" on public.inventory_movements;
create policy "invmov insert staff" on public.inventory_movements
  for insert with check (public.is_staff());

-- ---------- room_visits ----------
create table if not exists public.room_visits (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid references public.profiles(id) on delete set null,
  patient_label text,
  companion text,
  people_count integer not null default 1,
  notes text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);
alter table public.room_visits enable row level security;
drop policy if exists "rv staff" on public.room_visits;
create policy "rv staff" on public.room_visits
  for all using (public.is_staff()) with check (public.is_staff());

-- ---------- followups (incluye registro de mensajes de WhatsApp) ----------
create table if not exists public.followups (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid references public.profiles(id) on delete set null,
  patient_label text,
  channel text,
  message text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);
alter table public.followups enable row level security;
drop policy if exists "fu read" on public.followups;
create policy "fu read" on public.followups
  for select using (auth.uid() = patient_id or public.is_staff());
drop policy if exists "fu insert" on public.followups;
create policy "fu insert" on public.followups
  for insert with check (auth.uid() = patient_id or public.is_staff());

-- ---------- followup_tasks (tareas de enfermería) ----------
create table if not exists public.followup_tasks (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid references public.profiles(id) on delete set null,
  title text not null,
  details text,
  status text not null default 'pendiente',
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);
alter table public.followup_tasks enable row level security;
drop policy if exists "fut staff" on public.followup_tasks;
create policy "fut staff" on public.followup_tasks
  for all using (public.is_staff()) with check (public.is_staff());

-- ---------- shift_handovers ----------
create table if not exists public.shift_handovers (
  id uuid primary key default gen_random_uuid(),
  summary text,
  pending text,
  created_by uuid references public.profiles(id),
  confirmed_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);
alter table public.shift_handovers enable row level security;
drop policy if exists "sh staff" on public.shift_handovers;
create policy "sh staff" on public.shift_handovers
  for all using (public.is_staff()) with check (public.is_staff());

-- ---------- incomes (SOLO doctor) ----------
create table if not exists public.incomes (
  id uuid primary key default gen_random_uuid(),
  date date not null,
  concept text,
  amount numeric not null default 0,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);
alter table public.incomes enable row level security;
drop policy if exists "inc doctor only" on public.incomes;
create policy "inc doctor only" on public.incomes
  for all using (public.is_doctor()) with check (public.is_doctor());

-- ---------- staff_payments (SOLO doctor) ----------
create table if not exists public.staff_payments (
  id uuid primary key default gen_random_uuid(),
  staff_id uuid references public.profiles(id) on delete set null,
  staff_label text,
  date date not null,
  amount numeric not null default 0,
  concept text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);
alter table public.staff_payments enable row level security;
drop policy if exists "sp doctor only" on public.staff_payments;
create policy "sp doctor only" on public.staff_payments
  for all using (public.is_doctor()) with check (public.is_doctor());

-- ---------- services (38 especialidades; precio 0 = por confirmar) ----------
create table if not exists public.services (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  price numeric not null default 0
);
alter table public.services enable row level security;
drop policy if exists "svc read auth" on public.services;
create policy "svc read auth" on public.services
  for select using (auth.role() = 'authenticated');
drop policy if exists "svc write doctor" on public.services;
create policy "svc write doctor" on public.services
  for all using (public.is_doctor()) with check (public.is_doctor());
insert into public.services (name, price) values
('Medicina General',0),('Medicina Interna',0),('Pediatría',0),('Ginecología',0),
('Obstetricia',0),('Cardiología',0),('Dermatología',0),('Endocrinología',0),
('Gastroenterología',0),('Neumología',0),('Neurología',0),('Traumatología',0),
('Reumatología',0),('Urología',0),('Nefrología',0),('Psiquiatría',0),
('Psicología',0),('Oftalmología',0),('Otorrinolaringología',0),('Odontología',0),
('Medicina Estética',0),('Cirugía General',0),('Cirugía Plástica',0),('Cirugía Vascular',0),
('Oncología',0),('Infectología',0),('Alergología',0),('Hematología',0),
('Fisiatría y Rehabilitación',0),('Medicina del Deporte',0),('Medicina Familiar',0),('Geriatría',0),
('Medicina Laboral',0),('Urgencias y Cuidados Críticos',0),('Emergencia',0),('Partos',0),
('Biopsia / Laboratorio',0),('Rayos X',0)
on conflict (name) do nothing;

-- ---------- prescriptions ----------
create table if not exists public.prescriptions (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid references public.profiles(id) on delete set null,
  patient_label text,
  details text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);
alter table public.prescriptions enable row level security;
drop policy if exists "rx read" on public.prescriptions;
create policy "rx read" on public.prescriptions
  for select using (auth.uid() = patient_id or public.is_staff());
drop policy if exists "rx insert doctor" on public.prescriptions;
create policy "rx insert doctor" on public.prescriptions
  for insert with check (public.is_doctor());

-- ---------- certificates ----------
create table if not exists public.certificates (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid references public.profiles(id) on delete set null,
  patient_label text,
  text_content text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);
alter table public.certificates enable row level security;
drop policy if exists "cf read" on public.certificates;
create policy "cf read" on public.certificates
  for select using (auth.uid() = patient_id or public.is_staff());
drop policy if exists "cf insert doctor" on public.certificates;
create policy "cf insert doctor" on public.certificates
  for insert with check (public.is_doctor());

-- ---------- discharge_summaries ----------
create table if not exists public.discharge_summaries (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  summary text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);
alter table public.discharge_summaries enable row level security;
drop policy if exists "dc read" on public.discharge_summaries;
create policy "dc read" on public.discharge_summaries
  for select using (auth.uid() = patient_id or public.is_staff());
drop policy if exists "dc insert doctor" on public.discharge_summaries;
create policy "dc insert doctor" on public.discharge_summaries
  for insert with check (public.is_doctor());

-- ---------- surveys ----------
create table if not exists public.surveys (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid references public.profiles(id) on delete set null,
  rating integer check (rating between 1 and 5),
  comments text,
  created_at timestamptz not null default now()
);
alter table public.surveys enable row level security;
drop policy if exists "sv read staff" on public.surveys;
create policy "sv read staff" on public.surveys
  for select using (public.is_staff());
drop policy if exists "sv insert" on public.surveys;
create policy "sv insert" on public.surveys
  for insert with check (auth.uid() = patient_id);
