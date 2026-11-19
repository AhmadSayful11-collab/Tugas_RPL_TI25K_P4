-- Jalankan di Supabase: SQL Editor > New query > Run
-- Aman dijalankan ulang (termasuk kalau versi lama sudah pernah dijalankan).

create table if not exists public.profiles(
  id uuid primary key references auth.users on delete cascade,
  nik text unique not null, nama text not null, jabatan text default 'Karyawan',
  telepon text, gaji_pokok numeric default 6500000, role text default 'karyawan');
create table if not exists public.absensi(
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users on delete cascade,
  tanggal date not null, masuk timestamptz, pulang timestamptz, status text,
  terlambat_menit int default 0, jarak_m int, foto_masuk text, foto_pulang text,
  unique(user_id,tanggal));
create table if not exists public.izin(
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users on delete cascade,
  jenis text not null, mulai date not null, selesai date not null, alasan text not null,
  status text not null default 'Menunggu', created_at timestamptz default now());

alter table public.profiles enable row level security;
alter table public.absensi enable row level security;
alter table public.izin enable row level security;

-- Cek apakah pengguna yang login adalah Admin HRD
create or replace function public.is_hrd() returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.profiles where id=auth.uid() and role='hrd') $$;

-- Bersihkan aturan lama lalu buat ulang
do $$ declare r record; begin
  for r in select policyname,tablename from pg_policies where schemaname='public' and tablename in('profiles','absensi','izin')
  loop execute format('drop policy %I on public.%I',r.policyname,r.tablename); end loop;
  for r in select policyname from pg_policies where schemaname='storage' and tablename='objects' and policyname like 'selfie:%'
  loop execute format('drop policy %I on storage.objects',r.policyname); end loop;
end $$;

create policy "profil: baca" on public.profiles for select to authenticated using (auth.uid()=id or public.is_hrd());
create policy "profil: ubah sendiri" on public.profiles for update to authenticated using (auth.uid()=id) with check (auth.uid()=id);
-- Karyawan hanya boleh mengubah nomor telepon (bukan role atau gaji)
revoke update on public.profiles from anon, authenticated;
grant update(telepon) on public.profiles to authenticated;

create policy "absensi: baca" on public.absensi for select to authenticated using (auth.uid()=user_id or public.is_hrd());
create policy "absensi: tambah" on public.absensi for insert to authenticated with check (auth.uid()=user_id);
create policy "absensi: ubah sendiri" on public.absensi for update to authenticated using (auth.uid()=user_id);

create policy "izin: baca" on public.izin for select to authenticated using (auth.uid()=user_id or public.is_hrd());
create policy "izin: tambah" on public.izin for insert to authenticated with check (auth.uid()=user_id and status='Menunggu');
create policy "izin: HRD proses" on public.izin for update to authenticated using (public.is_hrd()) with check (public.is_hrd());

-- Profil dibuat otomatis saat akun didaftarkan
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin
  insert into public.profiles(id,nik,nama,jabatan)
  values(new.id,new.raw_user_meta_data->>'nik',new.raw_user_meta_data->>'nama',coalesce(new.raw_user_meta_data->>'jabatan','Karyawan'));
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

-- Penyimpanan foto selfie (privat; karyawan hanya foldernya sendiri, HRD bisa melihat semua)
insert into storage.buckets(id,name,public) values('selfie','selfie',false) on conflict do nothing;
create policy "selfie: tambah" on storage.objects for insert to authenticated with check (bucket_id='selfie' and (storage.foldername(name))[1]=auth.uid()::text);
create policy "selfie: ubah" on storage.objects for update to authenticated using (bucket_id='selfie' and (storage.foldername(name))[1]=auth.uid()::text);
create policy "selfie: baca" on storage.objects for select to authenticated using (bucket_id='selfie' and ((storage.foldername(name))[1]=auth.uid()::text or public.is_hrd()));

-- JADIKAN ADMIN HRD: daftar dulu lewat aplikasi (mis. NIK hrd01), lalu jalankan baris ini:
-- update public.profiles set role='hrd', jabatan='Admin HRD' where nik='hrd01';
