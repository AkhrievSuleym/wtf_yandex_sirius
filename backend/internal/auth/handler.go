package auth

import (
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	intmw "github.com/wtf/backend/internal/middleware"
	"golang.org/x/crypto/bcrypt"
)

type Handler struct {
	db        *pgxpool.Pool
	jwtSecret string
}

func NewHandler(db *pgxpool.Pool, jwtSecret string) *Handler {
	return &Handler{db: db, jwtSecret: jwtSecret}
}

// POST /auth/anonymous
func (h *Handler) Anonymous(w http.ResponseWriter, r *http.Request) {
	var uid string
	err := h.db.QueryRow(r.Context(),
		`INSERT INTO users DEFAULT VALUES RETURNING uid::text`).Scan(&uid)
	if err != nil {
		http.Error(w, "failed to create user", http.StatusInternalServerError)
		return
	}

	token, err := h.mintToken(uid)
	if err != nil {
		http.Error(w, "failed to generate token", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"uid": uid, "token": token}) //nolint:errcheck
}

// POST /auth/login  body: {username, password}
func (h *Handler) Login(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Username string `json:"username"`
		Password string `json:"password"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request", http.StatusBadRequest)
		return
	}
	req.Username = strings.ToLower(strings.TrimSpace(req.Username))
	if req.Username == "" || req.Password == "" {
		http.Error(w, "username and password required", http.StatusBadRequest)
		return
	}

	var uid, hash string
	err := h.db.QueryRow(r.Context(),
		`SELECT uid::text, COALESCE(password_hash,'') FROM users WHERE username = $1`,
		req.Username).Scan(&uid, &hash)
	if err == pgx.ErrNoRows {
		http.Error(w, "неверный логин или пароль", http.StatusUnauthorized)
		return
	}
	if err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	if hash == "" {
		http.Error(w, "пароль не установлен для этого аккаунта", http.StatusUnauthorized)
		return
	}
	if err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(req.Password)); err != nil {
		http.Error(w, "неверный логин или пароль", http.StatusUnauthorized)
		return
	}

	token, err := h.mintToken(uid)
	if err != nil {
		http.Error(w, "failed to generate token", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"uid": uid, "token": token}) //nolint:errcheck
}

// PUT /auth/password  body: {password}  (authenticated)
func (h *Handler) SetPassword(w http.ResponseWriter, r *http.Request) {
	uid := intmw.UID(r)

	var req struct {
		Password string `json:"password"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request", http.StatusBadRequest)
		return
	}
	if len(req.Password) < 6 {
		http.Error(w, "пароль должен быть минимум 6 символов", http.StatusBadRequest)
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}

	_, err = h.db.Exec(r.Context(),
		`UPDATE users SET password_hash = $2 WHERE uid = $1::uuid`, uid, string(hash))
	if err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) mintToken(uid string) (string, error) {
	claims := jwt.MapClaims{
		"uid": uid,
		"exp": time.Now().Add(365 * 24 * time.Hour).Unix(),
		"iat": time.Now().Unix(),
	}
	return jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(h.jwtSecret))
}
