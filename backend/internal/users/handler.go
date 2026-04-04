package users

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	intmw "github.com/wtf/backend/internal/middleware"
)

type Handler struct {
	repo       *Repository
	uploadsDir string
}

func NewHandler(repo *Repository, uploadsDir string) *Handler {
	return &Handler{repo: repo, uploadsDir: uploadsDir}
}

// GET /users/check/{username}
func (h *Handler) CheckUsername(w http.ResponseWriter, r *http.Request) {
	username := strings.ToLower(chi.URLParam(r, "username"))
	exists, err := h.repo.UsernameExists(r.Context(), username)
	if err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]bool{"available": !exists}) //nolint:errcheck
}

// GET /users/resolve/{username}
func (h *Handler) ResolveUsername(w http.ResponseWriter, r *http.Request) {
	username := strings.ToLower(chi.URLParam(r, "username"))
	user, err := h.repo.GetByUsername(r.Context(), username)
	if err != nil {
		if err == pgx.ErrNoRows {
			http.Error(w, "not found", http.StatusNotFound)
			return
		}
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"uid": user.UID}) //nolint:errcheck
}

// GET /users/{uid}
func (h *Handler) Get(w http.ResponseWriter, r *http.Request) {
	uid := chi.URLParam(r, "uid")
	user, err := h.repo.GetByUID(r.Context(), uid)
	if err != nil {
		if err == pgx.ErrNoRows {
			http.Error(w, "not found", http.StatusNotFound)
			return
		}
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	stats, err := h.repo.ReactionStatsForBoard(r.Context(), uid)
	if err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	user.ReactionStats = stats
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user) //nolint:errcheck
}

// POST /users — create profile (set username, displayName, bio for anonymous user)
func (h *Handler) Create(w http.ResponseWriter, r *http.Request) {
	uid := intmw.UID(r)

	var req struct {
		Username    string `json:"username"`
		DisplayName string `json:"displayName"`
		Bio         string `json:"bio"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request", http.StatusBadRequest)
		return
	}
	req.Username = strings.ToLower(strings.TrimSpace(req.Username))

	if err := h.repo.SetProfile(r.Context(), uid, req.Username, req.DisplayName, req.Bio); err != nil {
		if IsUniqueViolation(err) {
			http.Error(w, "username already taken", http.StatusConflict)
			return
		}
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}

	user, err := h.repo.GetByUID(r.Context(), uid)
	if err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user) //nolint:errcheck
}

// PUT /users/{uid}
func (h *Handler) Update(w http.ResponseWriter, r *http.Request) {
	uid := chi.URLParam(r, "uid")
	if uid != intmw.UID(r) {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}

	var req struct {
		DisplayName *string `json:"displayName"`
		Bio         *string `json:"bio"`
		IsPublic    *bool   `json:"isPublic"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request", http.StatusBadRequest)
		return
	}

	if err := h.repo.Update(r.Context(), uid, UpdateFields{
		DisplayName: req.DisplayName,
		Bio:         req.Bio,
		IsPublic:    req.IsPublic,
	}); err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}

	user, err := h.repo.GetByUID(r.Context(), uid)
	if err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user) //nolint:errcheck
}

// DELETE /users/{uid}
func (h *Handler) Delete(w http.ResponseWriter, r *http.Request) {
	uid := chi.URLParam(r, "uid")
	if uid != intmw.UID(r) {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	if err := h.repo.Delete(r.Context(), uid); err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// POST /users/{uid}/avatar — multipart file upload
func (h *Handler) UploadAvatar(w http.ResponseWriter, r *http.Request) {
	uid := chi.URLParam(r, "uid")
	if uid != intmw.UID(r) {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}

	r.Body = http.MaxBytesReader(w, r.Body, 5<<20) // 5 MB
	if err := r.ParseMultipartForm(5 << 20); err != nil {
		http.Error(w, "file too large", http.StatusRequestEntityTooLarge)
		return
	}

	file, header, err := r.FormFile("file")
	if err != nil {
		http.Error(w, "file required", http.StatusBadRequest)
		return
	}
	defer file.Close()

	ext := strings.ToLower(filepath.Ext(header.Filename))
	if ext == "" {
		ext = ".jpg"
	}
	dir := filepath.Join(h.uploadsDir, uid)
	if err := os.MkdirAll(dir, 0755); err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}

	destPath := filepath.Join(dir, "avatar"+ext)
	dest, err := os.Create(destPath)
	if err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	defer dest.Close()

	if _, err := io.Copy(dest, file); err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}

	avatarURL := fmt.Sprintf("/uploads/%s/avatar%s", uid, ext)
	if err := h.repo.UpdateAvatar(r.Context(), uid, avatarURL); err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"avatarUrl": avatarURL}) //nolint:errcheck
}
