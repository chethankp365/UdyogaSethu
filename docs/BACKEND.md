# UdyogaSethu Backend & Supabase Architecture Guide

## Supabase CLI Workflow Commands

The project uses Supabase CLI for database migrations, Edge Functions deployment, and secret management.

### Project Reference
Project Reference ID: `mmzbpeqkfomnywuzoqii`

### Key Commands

1. **Initialize / Link Project**
   ```bash
   npx supabase init
   npx supabase link --project-ref mmzbpeqkfomnywuzoqii
   ```

2. **Database Migrations**
   - Apply pending local migrations to remote Supabase DB:
     ```bash
     npx supabase db push
     ```
   - Lint migration files for syntax and RLS safety:
     ```bash
     npx supabase db lint
     ```

3. **Edge Functions & Secrets**
   - Set environment secrets on remote Supabase project:
     ```bash
     npx supabase secrets set KEY=value
     ```
   - Deploy an Edge Function:
     ```bash
     npx supabase functions deploy <function_name>
     ```

---

## Ping Verification Function (`public.ping()`)
- Defined in `supabase/migrations/0000_ping.sql`.
- Returns a JSONB object containing `server_time`, `postgres_version`, and `status`.
- Granted execute access to `anon` and `authenticated` roles.
