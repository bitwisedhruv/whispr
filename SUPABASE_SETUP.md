# Connecting Whispr to Supabase

To enable authentication and data syncing in Whispr, follow these steps:

1.  **Create a Supabase Project**:
    *   Go to [supabase.com](https://supabase.com/) and sign in.
    *   Create a new project.
2.  **Get Your Credentials**:
    *   In your Supabase project settings, go to **Project Settings > API**.
    *   Copy your **Project URL** and **anon public key**.
3.  **Configure Whispr**:
    *   Open `lib/services/supabase_service.dart`.
    *   Uncomment the `Supabase.initialize` block in the `init()` method.
    *   Replace `'YOUR_SUPABASE_URL'` and `'YOUR_SUPABASE_ANON_KEY'` with your actual credentials.
4.  **Enable Email Auth**:
    *   In the Supabase dashboard, go to **Authentication > Providers**.
    *   Ensure **Email** is enabled.
    *   (Optional) Disable "Confirm Email" for faster testing during development.

---

## Troubleshooting Redirects & Email Auth

### 1. "Localhost:3000 Refused Connect"
By default, Supabase redirects users to `localhost:3000` after they click the email confirmation link. Since you are developing a Mobile/Desktop app, you have two choices:

**Option A: Disable Email Confirmation (Recommended for Dev)**
1.  In Supabase, go to **Authentication > Providers > Email**.
2.  Toggle **OFF** "Confirm email".
3.  Now, users will be logged in immediately after sign-up without needing to click a link.

**Option B: Update the Redirect URL**
1.  Go to **Authentication > URL Configuration**.
2.  Change the **Site URL** to your specific deep-link scheme or a hosted landing page.
3.  Add `io.supabase.whispr://login-callback/` (or your app's scheme) to **Redirect URLs**.

---

## All-in-One Database Setup
Copy and paste this entire block into your Supabase **SQL Editor** and click **Run**. This will create the table, set up security, and automate user profiles.

```sql
-- "FRESH START" SCRIPT
-- This will safely create or update your profiles table and permissions.

-- 1. Create the profiles table (if it doesn't already exist)
create table if not exists public.profiles (
  id uuid references auth.users not null primary key,
  updated_at timestamp with time zone default now(),
  full_name text,
  avatar_url text,
  vault_salt text
);

-- 2. Enable Row Level Security (RLS)
alter table public.profiles enable row level security;

-- 3. Clear old policies and create fresh ones
drop policy if exists "Public profiles are viewable by everyone." on profiles;
drop policy if exists "Users can insert their own profile." on profiles;
drop policy if exists "Users can update own profile." on profiles;

create policy "Public profiles are viewable by everyone."
  on profiles for select
  using ( true );

create policy "Users can insert their own profile."
  on profiles for insert
  with check ( auth.uid() = id );

create policy "Users can update own profile."
  on profiles for update
  using ( auth.uid() = id )
  with check ( auth.uid() = id );

-- 4. Create a function to handle new user signups
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, avatar_url)
  values (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'avatar_url')
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

-- 5. Set up the trigger
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
```

### Why this works:
*   **Order Matters**: The table is created first so the function (Step 4) has a destination for data.
*   **Security**: RLS (Step 2 & 3) ensures that even though the table exists, users can't mess with each other's data.
*   **Automation**: The Trigger (Step 5) handles the "glue" between Supabase Auth and your custom data automatically.

---

## Updating Existing Tables (Migration)
If you already have the tables and just need to add the new `vault_salt` column, run this:

```sql
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS vault_salt text;
```

---

## Supabase Storage Setup (Avatars)

To support custom profile picture uploads, you need to create a storage bucket:

1.  **Create Bucket**:
    -   Go to **Storage** in the Supabase sidebar.
    -   Click **New Bucket**.
    -   Name it exactly `avatars`.
    -   Make sure it is set to **Public** (so profile pictures can be viewed by others).
2.  **Security Policies**:
    -   Copy and paste this into the **SQL Editor** to allow users to manage their own avatars:

```sql
-- 1. Allow public access to view any avatar
create policy "Allow public viewing of avatars" on storage.objects
  for select using (bucket_id = 'avatars');

-- 2. Allow users to upload their own avatar
create policy "Allow individual uploads" on storage.objects
  for insert with check (
    bucket_id = 'avatars' AND 
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- 3. Allow users to update/delete their own avatar
create policy "Allow individual updates" on storage.objects
  for update using (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);


---

## Password Manager Setup

To store your encrypted passwords, you need to create a new table and set up security rules.

1.  **Run SQL Script**: 
    Copy and paste this into the Supabase **SQL Editor** and click **Run**.

```sql
-- 1. Create the passwords table
create table if not exists public.passwords (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users not null default auth.uid(),
  title text not null,
  website_url text,
  username_encrypted text not null,
  password_encrypted text not null,
  notes_encrypted text,
  category text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- 2. Enable Row Level Security (RLS)
alter table public.passwords enable row level security;

-- 3. Create fresh policies
drop policy if exists "Users can only see their own passwords" on passwords;
drop policy if exists "Users can insert their own passwords" on passwords;
drop policy if exists "Users can update their own passwords" on passwords;
drop policy if exists "Users can delete their own passwords" on passwords;

create policy "Users can only see their own passwords" 
  on passwords for select 
  using (auth.uid() = user_id);

create policy "Users can insert their own passwords" 
  on passwords for insert 
  with check (auth.uid() = user_id);

create policy "Users can update their own passwords" 
  on passwords for update 
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete their own passwords" 
  on passwords for delete 
  using (auth.uid() = user_id);
```

2.  **Verify Column Types**:
    -   All secret data (username, password, notes) is stored as `text` because it will hold the base64-encoded encrypted strings.
    -   The `user_id` is automatically set to the logged-in user's ID.

---

## Authenticator Setup

To store your encrypted TOTP secrets, run this script in the Supabase **SQL Editor**.

```sql
-- 1. Create the authenticators table
create table if not exists public.authenticators (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users not null default auth.uid(),
  issuer text not null,
  account_name text not null,
  encrypted_secret text not null,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- 2. Enable Row Level Security (RLS)
alter table public.authenticators enable row level security;

-- 3. Create fresh policies
drop policy if exists "Users can only see their own authenticators" on authenticators;
drop policy if exists "Users can insert their own authenticators" on authenticators;
drop policy if exists "Users can delete their own authenticators" on authenticators;

create policy "Users can only see their own authenticators" 
  on authenticators for select 
  using (auth.uid() = user_id);

create policy "Users can insert their own authenticators" 
  on authenticators for insert 
  with check (auth.uid() = user_id);

create policy "Users can delete their own authenticators" 
  on authenticators for delete 
  using (auth.uid() = user_id);
```
