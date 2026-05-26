-- ============================================================
-- AI Smart Notes App — Supabase Database Setup
-- Run this in: Supabase Dashboard > SQL Editor > New Query
-- ============================================================

-- ── 1. USERS TABLE ──────────────────────────────────────────────────────────
-- Extends Supabase auth.users with profile data
CREATE TABLE IF NOT EXISTS public.users (
    id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name        TEXT NOT NULL DEFAULT 'Student',
    email       TEXT NOT NULL,
    profile_image TEXT,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── 2. NOTES TABLE ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.notes (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title       TEXT NOT NULL,
    content     TEXT NOT NULL DEFAULT '',
    user_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    file_url    TEXT,
    file_type   TEXT CHECK (file_type IN ('pdf', 'image', NULL)),
    tags        TEXT[] DEFAULT '{}',
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast user note queries
CREATE INDEX IF NOT EXISTS idx_notes_user_id ON public.notes(user_id);
CREATE INDEX IF NOT EXISTS idx_notes_created_at ON public.notes(created_at DESC);

-- Full-text search index
CREATE INDEX IF NOT EXISTS idx_notes_fts ON public.notes
    USING gin(to_tsvector('english', title || ' ' || content));

-- ── 3. QUIZZES TABLE ────────────────────────────────────────────────────────
-- Stores individual quiz questions generated from notes
CREATE TABLE IF NOT EXISTS public.quizzes (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    note_id       UUID NOT NULL REFERENCES public.notes(id) ON DELETE CASCADE,
    user_id       UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    question      TEXT NOT NULL,
    options       TEXT[] NOT NULL,
    correct_index INTEGER NOT NULL CHECK (correct_index >= 0),
    explanation   TEXT,
    created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_quizzes_note_id ON public.quizzes(note_id);
CREATE INDEX IF NOT EXISTS idx_quizzes_user_id ON public.quizzes(user_id);

-- ── 4. QUIZ_RESULTS TABLE ───────────────────────────────────────────────────
-- Stores completed quiz scores
CREATE TABLE IF NOT EXISTS public.quiz_results (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    note_id         UUID NOT NULL REFERENCES public.notes(id) ON DELETE CASCADE,
    score           INTEGER NOT NULL DEFAULT 0,
    total_questions INTEGER NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_quiz_results_user_id ON public.quiz_results(user_id);

-- ── 5. AUTO-UPDATE TIMESTAMPS ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE TRIGGER update_notes_updated_at
    BEFORE UPDATE ON public.notes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ── 6. ROW LEVEL SECURITY (RLS) ──────────────────────────────────────────────
-- CRITICAL: Enable RLS so users can only access their own data

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_results ENABLE ROW LEVEL SECURITY;

-- Users: can only read/update their own profile
CREATE POLICY "Users can view own profile"
    ON public.users FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON public.users FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
    ON public.users FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Notes: full CRUD for own notes only
CREATE POLICY "Users can view own notes"
    ON public.notes FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create notes"
    ON public.notes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own notes"
    ON public.notes FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own notes"
    ON public.notes FOR DELETE
    USING (auth.uid() = user_id);

-- Quizzes: own data only
CREATE POLICY "Users can view own quizzes"
    ON public.quizzes FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert quizzes"
    ON public.quizzes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Quiz results: own data only
CREATE POLICY "Users can view own quiz results"
    ON public.quiz_results FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert quiz results"
    ON public.quiz_results FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ── 7. STORAGE BUCKETS ───────────────────────────────────────────────────────
-- Run these separately in the Supabase Dashboard > Storage tab
-- OR uncomment and run here:

-- INSERT INTO storage.buckets (id, name, public) VALUES ('profiles', 'profiles', true);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('note-files', 'note-files', true);

-- Storage policies (after creating buckets):
-- CREATE POLICY "Anyone can view profile images"
--     ON storage.objects FOR SELECT USING (bucket_id = 'profiles');
-- CREATE POLICY "Users can upload their own profile image"
--     ON storage.objects FOR INSERT
--     WITH CHECK (bucket_id = 'profiles' AND auth.uid()::text = (storage.foldername(name))[1]);

-- ── 8. SAMPLE DATA (optional for testing) ────────────────────────────────────
-- Uncomment to insert test data after creating a user

-- INSERT INTO public.notes (title, content, user_id, tags) VALUES
-- ('Introduction to Algorithms', 'Big O notation describes algorithm complexity...', 
--  auth.uid(), ARRAY['CS', 'Algorithms']),
-- ('Physics: Kinematics', 'v = u + at, s = ut + ½at²...', 
--  auth.uid(), ARRAY['Physics', 'Mechanics']);
