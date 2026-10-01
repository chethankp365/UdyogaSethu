# UdyogaSethu

A Multilingual, Trust-Centric Platform for Informal Workers, Customers, Farmers, and Direct Local Commerce in India.

## Getting Started

### 1. Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK

### 2. Environment Setup
Copy the sample environment file `env.example.json` to `env.json`:

```bash
cp env.example.json env.json
```

Update `env.json` with your Supabase credentials:

```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key"
}
```

### 3. Run the Application

Run the app using the exact dart-define command:

```bash
flutter run --dart-define-from-file=env.json
```
