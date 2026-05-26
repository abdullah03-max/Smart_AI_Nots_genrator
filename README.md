# 🤖 AI Smart Notes App

> **University Semester Project — Mobile Application Development**
> A production-ready Flutter app with AI-powered note summarization, quiz generation, and smart study tools.

---

## 📋 Project Abstract

AI Smart Notes is a cross-platform mobile application built with Flutter that empowers students to study smarter using artificial intelligence. Users can create rich notes, upload PDFs and images, and leverage AI features like automatic summarization and quiz generation. The app uses Supabase for authentication and cloud storage, and a Python FastAPI backend to interface with Google Gemini AI.

---

## 🏗️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.x (Dart) |
| State Management | Provider |
| Backend | Python FastAPI |
| Database | Supabase (PostgreSQL) |
| Authentication | Supabase Auth |
| File Storage | Supabase Storage |
| AI Integration | Google Gemini 1.5 Flash / OpenAI GPT-4o-mini |
| UI Design | Material 3, Google Fonts (Poppins) |

---

## 📁 Project Structure

```
ai_smart_notes/
├── flutter_app/                    # Flutter frontend
│   ├── lib/
│   │   ├── core/
│   │   │   ├── constants/          # App-wide constants
│   │   │   ├── theme/              # Light & dark themes
│   │   │   └── utils/              # Router, helpers
│   │   ├── data/
│   │   │   ├── models/             # Note, User, Quiz models
│   │   │   ├── repositories/       # Data layer abstractions
│   │   │   └── datasources/        # Supabase + API clients
│   │   ├── domain/
│   │   │   ├── entities/           # Business entities
│   │   │   └── usecases/           # Business logic
│   │   └── presentation/
│   │       ├── screens/            # All screens
│   │       │   ├── auth/           # Login, Signup, ForgotPassword
│   │       │   ├── home/           # Dashboard
│   │       │   ├── notes/          # Notes CRUD
│   │       │   ├── ai/             # AI Summary, Explain
│   │       │   ├── quiz/           # Quiz + Results
│   │       │   ├── profile/        # User profile
│   │       │   ├── onboarding/     # Onboarding flow
│   │       │   └── splash/         # Splash screen
│   │       ├── widgets/            # Reusable widgets
│   │       │   ├── common/         # Buttons, text fields, overlays
│   │       │   ├── notes/          # NoteCard
│   │       │   ├── quiz/           # Quiz widgets
│   │       │   └── dashboard/      # Stats cards
│   │       └── providers/          # AuthProvider, NotesProvider, AiProvider, ThemeProvider
│   ├── assets/
│   │   ├── images/
│   │   └── icons/
│   └── pubspec.yaml
│
└── backend/                        # Python FastAPI backend
    ├── app/
    │   ├── main.py                 # FastAPI app entry point
    │   ├── core/
    │   │   ├── config.py           # Settings from .env
    │   │   └── auth_middleware.py  # JWT verification
    │   ├── api/routes/
    │   │   ├── ai_routes.py        # /api/ai/* endpoints
    │   │   ├── notes_routes.py     # /api/notes/* endpoints
    │   │   ├── file_routes.py      # /api/files/upload
    │   │   └── health_routes.py    # /health
    │   ├── models/
    │   │   └── schemas.py          # Pydantic request/response models
    │   └── services/
    │       └── ai_service.py       # Gemini & OpenAI integration
    ├── requirements.txt
    ├── .env.example
    └── supabase_setup.sql          # Database schema + RLS policies
```

---

## 🚀 Setup Guide

### Prerequisites

- Flutter SDK ≥ 3.1.0 ([install](https://flutter.dev/docs/get-started/install))
- Python 3.11+ ([install](https://python.org))
- A Supabase account ([free at supabase.com](https://supabase.com))
- Google Gemini API key ([free at aistudio.google.com](https://aistudio.google.com))

---

### Step 1: Supabase Setup

1. Go to [supabase.com](https://supabase.com) → **New Project**
2. Choose a name (e.g. `ai-smart-notes`), set a strong DB password, pick a region
3. Wait ~2 minutes for provisioning

**Create the database tables:**
1. In your project dashboard → **SQL Editor** → **New Query**
2. Paste the entire contents of `backend/supabase_setup.sql`
3. Click **Run**

**Create Storage Buckets:**
1. Go to **Storage** → **New bucket**
2. Create `profiles` bucket → enable **Public** access
3. Create `note-files` bucket → enable **Public** access

**Get your credentials:**
- Go to **Project Settings** → **API**
- Copy: **Project URL**, **anon/public key**, **JWT Secret**

---

### Step 2: Backend Setup

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate      # macOS/Linux
# venv\Scripts\activate       # Windows

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env — fill in your keys:
#   GEMINI_API_KEY=...
#   SUPABASE_URL=...
#   SUPABASE_JWT_SECRET=...

# Run the backend server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Open http://localhost:8000/docs to see the interactive API documentation.

---

### Step 3: Flutter App Setup

```bash
cd flutter_app

# Install dependencies
flutter pub get

# Update Supabase credentials in:
# lib/core/constants/app_constants.dart
#   supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co'
#   supabaseAnonKey = 'your_anon_key'

# Run on Android emulator
flutter run

# Run on iOS simulator (macOS only)
flutter run -d ios

# Run as web app (for quick testing)
flutter run -d chrome
```

**Android emulator backend URL:** `http://10.0.2.2:8000` (already set as default)
**iOS simulator / physical device:** Change to your computer's local IP: `http://192.168.x.x:8000`

---

## 📱 Screens Overview

| Screen | Description |
|--------|-------------|
| Splash | Animated logo, auto-redirects based on auth state |
| Onboarding | 4-page feature introduction (shown once) |
| Login | Email/password auth with validation |
| Sign Up | Account creation with name, email, password |
| Forgot Password | Email reset via Supabase |
| Dashboard | Stats cards, recent notes, quick actions |
| Notes List | Searchable, deletable note list |
| Create/Edit Note | Rich text editor + file attachment |
| Note Detail | Full note view with AI action buttons |
| AI Summary | Summarize notes + explain difficult text |
| Quiz | AI-generated MCQ quiz with score tracking |
| Quiz Result | Score, grade, question review |
| Profile | Name/photo edit, dark mode, logout |

---

## 🗄️ Database Schema

```
users          → id, name, email, profile_image, created_at
notes          → id, title, content, user_id, file_url, file_type, tags, created_at, updated_at
quizzes        → id, note_id, user_id, question, options[], correct_index, explanation
quiz_results   → id, user_id, note_id, score, total_questions, created_at
```

All tables have Row Level Security (RLS) — users can only access their own data.

---

## 🤖 AI API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/ai/summarize` | Summarize note content |
| POST | `/api/ai/explain` | Explain difficult text |
| POST | `/api/ai/generate-quiz` | Generate MCQ questions |
| POST | `/api/files/upload` | Upload PDF/image |
| GET | `/health` | Server health check |

All endpoints require `Authorization: Bearer <supabase_jwt_token>` header.

---

## 🧪 Testing

```bash
# Backend tests
cd backend
pytest tests/ -v

# Flutter tests
cd flutter_app
flutter test

# Flutter integration tests (requires device/emulator)
flutter drive --target=test_driver/app.dart
```

---

## 📸 Screenshot Ideas for Submission

1. **Splash Screen** — Purple gradient with animated logo
2. **Onboarding** — Feature walkthrough pages
3. **Dashboard** — Stats cards + recent notes grid
4. **Notes List** — Colorful note cards with search
5. **Create Note** — Note editor with tag chips
6. **AI Summary** — Summary results card
7. **Quiz Screen** — MCQ question with options
8. **Quiz Result** — Score card with grade emoji

---

## 🎓 Viva Questions & Answers

**Q1: What is the architecture of this app?**
A: Clean Architecture with separation into Data, Domain, and Presentation layers. State management uses Provider pattern, with separate providers for Auth, Notes, AI, and Theme.

**Q2: Why Supabase instead of Firebase?**
A: Supabase is open-source, PostgreSQL-based (SQL queries), has a generous free tier, built-in Auth and Storage, and Row Level Security for fine-grained access control.

**Q3: How does the AI integration work?**
A: The Flutter app sends the note content to the FastAPI backend via HTTP POST. The backend calls Google Gemini API with a structured prompt and returns the result as JSON. For quizzes, it parses the JSON response into QuizQuestion objects.

**Q4: What is Provider in Flutter?**
A: Provider is a state management package that uses InheritedWidget under the hood. It allows sharing state (like user info, notes list) across the widget tree without passing data down manually through constructors.

**Q5: How is authentication handled?**
A: Supabase Auth handles registration, login, JWT generation, and session management. The JWT token is included in API requests to the FastAPI backend which verifies it using the Supabase JWT secret.

**Q6: What is Row Level Security (RLS)?**
A: PostgreSQL security feature that restricts which database rows a user can access. We configured policies so users can only read/write their own notes, quiz results, etc., even if they send crafted SQL queries.

**Q7: How does dark mode work?**
A: Flutter's `ThemeMode` is controlled by `ThemeProvider`. Both `lightTheme` and `darkTheme` are defined in `AppTheme`. The preference is persisted to `SharedPreferences` so it survives app restarts.

**Q8: What is the difference between stateful and stateless widgets?**
A: StatelessWidget is immutable — it rebuilds when its parent changes. StatefulWidget maintains a mutable State object that can call `setState()` to trigger rebuilds independently.

---

## 📊 Features List for Presentation

### Core Features
- ✅ Email/password sign up & login
- ✅ Forgot password (email reset)
- ✅ Session persistence
- ✅ Create, read, update, delete notes
- ✅ Full-text note search
- ✅ Tags system
- ✅ File attachment (PDF & images)
- ✅ Supabase cloud storage

### AI Features
- ✅ AI note summarization (Gemini/OpenAI)
- ✅ AI text explanation
- ✅ AI MCQ quiz generation
- ✅ Quiz scoring & history

### UX Features
- ✅ Onboarding flow (first launch)
- ✅ Dark mode / light mode
- ✅ Animated transitions
- ✅ Pull-to-refresh
- ✅ Loading indicators
- ✅ Form validation
- ✅ Error messages (Snackbars)
- ✅ Empty states with call-to-action

---

## 📄 Project Title Page

**Title:** AI Smart Notes — An AI-Powered Study Companion Mobile Application

**Submitted by:** [Your Name] | [Roll Number]

**Submitted to:** [Professor Name]

**Course:** Mobile Application Development

**Department:** [Department Name]

**University:** [University Name]

**Semester:** [Semester / Year]

**Date:** [Submission Date]

---

## 📝 License

This project is created for educational purposes as a university semester project.
