package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/go-chi/chi/v5"
	chimw "github.com/go-chi/chi/v5/middleware"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/wtf/backend/internal/auth"
	"github.com/wtf/backend/internal/comments"
	"github.com/wtf/backend/internal/favorites"
	intmw "github.com/wtf/backend/internal/middleware"
	"github.com/wtf/backend/internal/search"
	"github.com/wtf/backend/internal/users"
)

func main() {
	dbURL := getenv("DATABASE_URL", "postgres://wtf:wtf@localhost:5432/wtf?sslmode=disable")
	jwtSecret := getenv("JWT_SECRET", "dev-secret-change-in-production")
	uploadsDir := getenv("UPLOADS_DIR", "./uploads")

	if err := os.MkdirAll(uploadsDir, 0755); err != nil {
		log.Fatalf("create uploads dir: %v", err)
	}

	pool := mustConnectDB(dbURL)
	defer pool.Close()

	if err := runMigrations(pool); err != nil {
		log.Fatalf("migrations failed: %v", err)
	}

	hub := comments.NewHub()

	// Repositories
	usersRepo := users.NewRepository(pool)
	commentsRepo := comments.NewRepository(pool)
	repliesRepo := comments.NewRepliesRepository(pool)
	favoritesRepo := favorites.NewRepository(pool)

	// Handlers
	authHandler := auth.NewHandler(pool, jwtSecret)
	usersHandler := users.NewHandler(usersRepo, uploadsDir)
	commentsHandler := comments.NewHandler(commentsRepo, hub)
	repliesHandler := comments.NewRepliesHandler(repliesRepo, hub)
	favoritesHandler := favorites.NewHandler(favoritesRepo)
	searchHandler := search.NewHandler(usersRepo)

	r := chi.NewRouter()
	r.Use(chimw.Logger)
	r.Use(chimw.Recoverer)
	r.Use(intmw.CORS)

	// Public
	r.Post("/auth/anonymous", authHandler.Anonymous)
	r.Post("/auth/login", authHandler.Login)

	// Static uploads
	r.Handle("/uploads/*", http.StripPrefix("/uploads/", http.FileServer(http.Dir(uploadsDir))))

	// Protected
	r.Group(func(r chi.Router) {
		r.Use(intmw.Auth(jwtSecret))

		// Auth
		r.Put("/auth/password", authHandler.SetPassword)

		// Users
		r.Get("/users/check/{username}", usersHandler.CheckUsername)
		r.Post("/users", usersHandler.Create)
		r.Put("/users/{uid}", usersHandler.Update)
		r.Delete("/users/{uid}", usersHandler.Delete)
		r.Post("/users/{uid}/avatar", usersHandler.UploadAvatar)

		// Favorites
		r.Get("/users/{uid}/favorites", favoritesHandler.List)
		r.Post("/users/{uid}/favorites", favoritesHandler.Add)
		r.Delete("/users/{uid}/favorites/{favoriteUid}", favoritesHandler.Remove)
		r.Get("/users/{uid}/favorites/{favoriteUid}/check", favoritesHandler.Check)

		// Comments
		r.Put("/comments/{id}/read", commentsHandler.MarkRead)
		r.Post("/comments/{id}/reaction", commentsHandler.ToggleReaction)
		r.Delete("/comments/{id}", commentsHandler.Delete)

		// Replies
		r.Delete("/replies/{id}", repliesHandler.Delete)

		// Search
		r.Get("/search", searchHandler.Search)
	})

	r.Group(func(r chi.Router) {
		r.Use(intmw.OptionalAuth(jwtSecret))
		r.Get("/users/resolve/{username}", usersHandler.ResolveUsername)
		r.Get("/users/{uid}", usersHandler.Get)
		r.Get("/comments/board/{ownerId}", commentsHandler.List)
		r.Get("/comments/board/{ownerId}/stream", commentsHandler.Stream)
		r.Post("/comments", commentsHandler.Create)
		r.Get("/comments/{id}/replies", repliesHandler.List)
		r.Post("/comments/{id}/replies", repliesHandler.Create)
	})

	addr := ":8080"
	log.Printf("🚀 WTF backend listening on %s", addr)
	if err := http.ListenAndServe(addr, r); err != nil {
		log.Fatalf("server: %v", err)
	}
}

func mustConnectDB(url string) *pgxpool.Pool {
	var pool *pgxpool.Pool
	for i := range 10 {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		p, err := pgxpool.New(ctx, url)
		cancel()
		if err == nil {
			if err := p.Ping(context.Background()); err == nil {
				log.Printf("✅ Connected to database (attempt %d)", i+1)
				return p
			}
			p.Close()
		}
		log.Printf("⏳ Waiting for database... (attempt %d/10)", i+1)
		time.Sleep(2 * time.Second)
	}
	log.Fatal("failed to connect to database after 10 attempts")
	return pool
}

func runMigrations(pool *pgxpool.Pool) error {
	_, err := pool.Exec(context.Background(), schema)
	return err
}

func getenv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

const schema = `
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS users (
	uid           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	username      VARCHAR(30) UNIQUE,
	display_name  VARCHAR(50)  NOT NULL DEFAULT '',
	bio           VARCHAR(200) NOT NULL DEFAULT '',
	avatar_url    TEXT,
	is_public     BOOLEAN      NOT NULL DEFAULT true,
	comment_count INTEGER      NOT NULL DEFAULT 0,
	password_hash TEXT,
	created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
	updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash TEXT;

CREATE TABLE IF NOT EXISTS comments (
	id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	board_owner_id UUID NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
	author_id      UUID REFERENCES users(uid) ON DELETE SET NULL,
	text           TEXT        NOT NULL,
	is_read        BOOLEAN     NOT NULL DEFAULT false,
	created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_comments_owner ON comments(board_owner_id, created_at DESC);

CREATE TABLE IF NOT EXISTS reactions (
	comment_id   UUID        NOT NULL REFERENCES comments(id) ON DELETE CASCADE,
	reaction_key VARCHAR(20) NOT NULL,
	user_id      UUID        NOT NULL,
	created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
	PRIMARY KEY (comment_id, reaction_key, user_id)
);

CREATE TABLE IF NOT EXISTS favorites (
	owner_uid    UUID NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
	favorite_uid UUID NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
	created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
	PRIMARY KEY (owner_uid, favorite_uid)
);

CREATE TABLE IF NOT EXISTS replies (
	id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	comment_id UUID NOT NULL REFERENCES comments(id) ON DELETE CASCADE,
	owner_uid  UUID NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
	text       TEXT        NOT NULL,
	created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_replies_comment ON replies(comment_id, created_at ASC);

ALTER TABLE replies ALTER COLUMN owner_uid DROP NOT NULL;
ALTER TABLE replies DROP CONSTRAINT IF EXISTS replies_owner_uid_fkey;
ALTER TABLE replies ADD CONSTRAINT replies_owner_uid_fkey FOREIGN KEY (owner_uid) REFERENCES users(uid) ON DELETE SET NULL;
`
