package comments

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	intmw "github.com/wtf/backend/internal/middleware"
	"github.com/wtf/backend/internal/model"
)

type Handler struct {
	repo *Repository
	hub  *Hub
}

func NewHandler(repo *Repository, hub *Hub) *Handler {
	return &Handler{repo: repo, hub: hub}
}

// GET /comments/board/{ownerId}
func (h *Handler) List(w http.ResponseWriter, r *http.Request) {
	ownerID := chi.URLParam(r, "ownerId")
	comments, err := h.repo.ListByOwner(r.Context(), ownerID)
	if err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(comments) //nolint:errcheck
}

// GET /comments/board/{ownerId}/stream — SSE endpoint for real-time updates.
func (h *Handler) Stream(w http.ResponseWriter, r *http.Request) {
	ownerID := chi.URLParam(r, "ownerId")

	flusher, ok := w.(http.Flusher)
	if !ok {
		http.Error(w, "streaming not supported", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "text/event-stream")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")
	w.Header().Set("X-Accel-Buffering", "no")

	ch := h.hub.Subscribe(ownerID)
	defer h.hub.Unsubscribe(ownerID, ch)

	// Send initial heartbeat
	fmt.Fprintf(w, ": connected\n\n")
	flusher.Flush()

	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-r.Context().Done():
			return
		case <-ch:
			fmt.Fprintf(w, "data: update\n\n")
			flusher.Flush()
		case <-ticker.C:
			fmt.Fprintf(w, ": heartbeat\n\n")
			flusher.Flush()
		}
	}
}

// POST /comments
func (h *Handler) Create(w http.ResponseWriter, r *http.Request) {
	callerUID := intmw.UID(r)
	var authorID *string
	if callerUID != "" {
		authorID = &callerUID
	}

	var req struct {
		BoardOwnerID string `json:"boardOwnerId"`
		Text         string `json:"text"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.BoardOwnerID == "" || req.Text == "" {
		http.Error(w, "boardOwnerId and text are required", http.StatusBadRequest)
		return
	}

	comment, err := h.repo.Create(r.Context(), req.BoardOwnerID, authorID, req.Text)
	if err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}

	comment.AuthorID = nil

	h.hub.Notify(req.BoardOwnerID)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(comment) //nolint:errcheck
}

// PUT /comments/{id}/read
func (h *Handler) MarkRead(w http.ResponseWriter, r *http.Request) {
	commentID := chi.URLParam(r, "id")
	ownerID, err := h.repo.GetOwner(r.Context(), commentID)
	if err != nil {
		if err == pgx.ErrNoRows {
			http.Error(w, "not found", http.StatusNotFound)
			return
		}
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	if ownerID != intmw.UID(r) {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	if err := h.repo.MarkAsRead(r.Context(), commentID); err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	h.hub.Notify(ownerID)
	w.WriteHeader(http.StatusNoContent)
}

// POST /comments/{id}/reaction
func (h *Handler) ToggleReaction(w http.ResponseWriter, r *http.Request) {
	commentID := chi.URLParam(r, "id")

	var req struct {
		ReactionKey string `json:"reactionKey"`
		UserID      string `json:"userId"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.ReactionKey == "" || req.UserID == "" {
		http.Error(w, "reactionKey and userId are required", http.StatusBadRequest)
		return
	}
	if !model.IsValidReactionKey(req.ReactionKey) {
		http.Error(w, "invalid reactionKey", http.StatusBadRequest)
		return
	}

	ownerID, err := h.repo.GetOwner(r.Context(), commentID)
	if err != nil {
		if err == pgx.ErrNoRows {
			http.Error(w, "not found", http.StatusNotFound)
			return
		}
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}

	if _, err := h.repo.ToggleReaction(r.Context(), commentID, req.ReactionKey, req.UserID); err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}

	comment, err := h.repo.GetWithReactions(r.Context(), commentID)
	if err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}

	h.hub.Notify(ownerID)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(comment) //nolint:errcheck
}

// DELETE /comments/{id}
func (h *Handler) Delete(w http.ResponseWriter, r *http.Request) {
	commentID := chi.URLParam(r, "id")
	ownerID, err := h.repo.GetOwner(r.Context(), commentID)
	if err != nil {
		if err == pgx.ErrNoRows {
			http.Error(w, "not found", http.StatusNotFound)
			return
		}
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	if ownerID != intmw.UID(r) {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	if err := h.repo.Delete(r.Context(), commentID); err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	h.hub.Notify(ownerID)
	w.WriteHeader(http.StatusNoContent)
}
