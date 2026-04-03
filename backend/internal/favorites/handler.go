package favorites

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	intmw "github.com/wtf/backend/internal/middleware"
)

type Handler struct {
	repo *Repository
}

func NewHandler(repo *Repository) *Handler {
	return &Handler{repo: repo}
}

// GET /users/{uid}/favorites
func (h *Handler) List(w http.ResponseWriter, r *http.Request) {
	uid := chi.URLParam(r, "uid")
	if uid != intmw.UID(r) {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	profiles, err := h.repo.List(r.Context(), uid)
	if err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(profiles) //nolint:errcheck
}

// POST /users/{uid}/favorites
func (h *Handler) Add(w http.ResponseWriter, r *http.Request) {
	uid := chi.URLParam(r, "uid")
	if uid != intmw.UID(r) {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	var req struct {
		FavoriteUID string `json:"favoriteUid"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.FavoriteUID == "" {
		http.Error(w, "favoriteUid required", http.StatusBadRequest)
		return
	}
	if err := h.repo.Add(r.Context(), uid, req.FavoriteUID); err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// DELETE /users/{uid}/favorites/{favoriteUid}
func (h *Handler) Remove(w http.ResponseWriter, r *http.Request) {
	uid := chi.URLParam(r, "uid")
	if uid != intmw.UID(r) {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	favoriteUID := chi.URLParam(r, "favoriteUid")
	if err := h.repo.Remove(r.Context(), uid, favoriteUID); err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// GET /users/{uid}/favorites/{favoriteUid}/check
func (h *Handler) Check(w http.ResponseWriter, r *http.Request) {
	uid := chi.URLParam(r, "uid")
	favoriteUID := chi.URLParam(r, "favoriteUid")
	exists, err := h.repo.Exists(r.Context(), uid, favoriteUID)
	if err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]bool{"isFavorite": exists}) //nolint:errcheck
}
