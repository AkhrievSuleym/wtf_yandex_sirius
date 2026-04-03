package search

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/wtf/backend/internal/users"
)

type Handler struct {
	usersRepo *users.Repository
}

func NewHandler(usersRepo *users.Repository) *Handler {
	return &Handler{usersRepo: usersRepo}
}

// GET /search?q=...
func (h *Handler) Search(w http.ResponseWriter, r *http.Request) {
	q := strings.ToLower(strings.TrimSpace(r.URL.Query().Get("q")))
	if q == "" {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode([]struct{}{}) //nolint:errcheck
		return
	}

	results, err := h.usersRepo.Search(r.Context(), q, 20)
	if err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}

	// Convert to Profile response
	type profileResp struct {
		UID          string  `json:"uid"`
		Username     string  `json:"username"`
		DisplayName  string  `json:"displayName"`
		Bio          string  `json:"bio"`
		AvatarURL    *string `json:"avatarUrl"`
		CommentCount int     `json:"commentCount"`
		IsPublic     bool    `json:"isPublic"`
	}

	out := make([]profileResp, 0, len(results))
	for _, u := range results {
		username := ""
		if u.Username != nil {
			username = *u.Username
		}
		out = append(out, profileResp{
			UID:          u.UID,
			Username:     username,
			DisplayName:  u.DisplayName,
			Bio:          u.Bio,
			AvatarURL:    u.AvatarURL,
			CommentCount: u.CommentCount,
			IsPublic:     u.IsPublic,
		})
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(out) //nolint:errcheck
}
