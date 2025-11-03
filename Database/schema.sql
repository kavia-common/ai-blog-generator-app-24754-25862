-- AI Blog Generator DB Schema
-- Database: ai_blog_generator_db
-- Note: This file is applied on container startup by startup.sh

-- Ensure public schema exists
CREATE SCHEMA IF NOT EXISTS public;

-- Extensions (optional but commonly useful)
-- Uncomment if needed and permitted in environment
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Table: users
CREATE TABLE IF NOT EXISTS public.users (
    id                 BIGSERIAL PRIMARY KEY,
    email              VARCHAR(255) NOT NULL UNIQUE,
    username           VARCHAR(100) UNIQUE,
    password_hash      VARCHAR(255) NOT NULL,
    role               VARCHAR(50) NOT NULL DEFAULT 'user', -- user | admin
    is_active          BOOLEAN NOT NULL DEFAULT TRUE,
    last_login_at      TIMESTAMPTZ,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table: sessions
CREATE TABLE IF NOT EXISTS public.sessions (
    id                 BIGSERIAL PRIMARY KEY,
    user_id            BIGINT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    session_token      VARCHAR(255) NOT NULL UNIQUE,
    ip_address         INET,
    user_agent         TEXT,
    is_active          BOOLEAN NOT NULL DEFAULT TRUE,
    expires_at         TIMESTAMPTZ NOT NULL,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table: posts
CREATE TABLE IF NOT EXISTS public.posts (
    id                 BIGSERIAL PRIMARY KEY,
    user_id            BIGINT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title              VARCHAR(300) NOT NULL,
    slug               VARCHAR(320) UNIQUE,
    status             VARCHAR(50) NOT NULL DEFAULT 'draft', -- draft | published | archived
    seo_keywords       TEXT, -- comma separated or JSON in future
    word_count         INTEGER,
    current_version_id BIGINT, -- pointer to post_versions.id
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table: post_versions
CREATE TABLE IF NOT EXISTS public.post_versions (
    id                 BIGSERIAL PRIMARY KEY,
    post_id            BIGINT NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    version_number     INTEGER NOT NULL, -- 1..N
    content_markdown   TEXT NOT NULL,
    content_html       TEXT,
    notes              TEXT,
    created_by         BIGINT REFERENCES public.users(id) ON DELETE SET NULL,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (post_id, version_number)
);

-- Back-reference from posts.current_version_id to post_versions.id with constraint
ALTER TABLE public.posts
    ADD CONSTRAINT posts_current_version_fk
    FOREIGN KEY (current_version_id)
    REFERENCES public.post_versions(id)
    ON DELETE SET NULL
    DEFERRABLE INITIALLY DEFERRED;

-- Table: exports
CREATE TABLE IF NOT EXISTS public.exports (
    id                 BIGSERIAL PRIMARY KEY,
    post_id            BIGINT NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    version_id         BIGINT REFERENCES public.post_versions(id) ON DELETE SET NULL,
    export_format      VARCHAR(50) NOT NULL, -- pdf | html | markdown
    file_path          TEXT, -- optional path or storage key
    status             VARCHAR(50) NOT NULL DEFAULT 'queued', -- queued | processing | completed | failed
    error_message      TEXT,
    created_by         BIGINT REFERENCES public.users(id) ON DELETE SET NULL,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at       TIMESTAMPTZ
);

-- Table: activity_logs
CREATE TABLE IF NOT EXISTS public.activity_logs (
    id                 BIGSERIAL PRIMARY KEY,
    user_id            BIGINT REFERENCES public.users(id) ON DELETE SET NULL,
    session_id         BIGINT REFERENCES public.sessions(id) ON DELETE SET NULL,
    action             VARCHAR(100) NOT NULL, -- e.g., login, create_post, generate_content
    entity_type        VARCHAR(100),          -- user | post | export | system
    entity_id          BIGINT,
    details            JSONB,
    ip_address         INET,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_sessions_user ON public.sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_token ON public.sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_posts_user ON public.posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_slug ON public.posts(slug);
CREATE INDEX IF NOT EXISTS idx_posts_status ON public.posts(status);
CREATE INDEX IF NOT EXISTS idx_post_versions_post ON public.post_versions(post_id);
CREATE INDEX IF NOT EXISTS idx_exports_post ON public.exports(post_id);
CREATE INDEX IF NOT EXISTS idx_exports_version ON public.exports(version_id);
CREATE INDEX IF NOT EXISTS idx_exports_status ON public.exports(status);
CREATE INDEX IF NOT EXISTS idx_activity_logs_user ON public.activity_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_action ON public.activity_logs(action);

-- Trigger to auto update updated_at on users and posts
CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_users_touch_updated_at ON public.users;
CREATE TRIGGER trg_users_touch_updated_at
BEFORE UPDATE ON public.users
FOR EACH ROW
EXECUTE PROCEDURE public.touch_updated_at();

DROP TRIGGER IF EXISTS trg_posts_touch_updated_at ON public.posts;
CREATE TRIGGER trg_posts_touch_updated_at
BEFORE UPDATE ON public.posts
FOR EACH ROW
EXECUTE PROCEDURE public.touch_updated_at();

-- Initial admin (optional): comment out if not desired
-- INSERT INTO public.users (email, username, password_hash, role)
-- VALUES ('admin@example.com', 'admin', 'REPLACE_WITH_HASH', 'admin')
-- ON CONFLICT (email) DO NOTHING;
