package comments

import (
	"context"
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	intmw "github.com/wtf/backend/internal/middleware"
)

type Reply struct {
	ID        string    `json:"id"`
	CommentID string    `json:"commentId"`
	OwnerUID  *string   `json:"ownerUid,omitempty"`
	Text      string    `json:"text"`
	CreatedAt time.Time `json:"createdAt"`
}

type RepliesRepository struct {
	db *pgxpool.Pool
}

func NewRepliesRepository(db *pgxpool.Pool) *RepliesRepository {
	return &RepliesRepository{db: db}
}

func (r *RepliesRepository) List(ctx context.Context, commentID string) ([]Reply, error) {
	rows, err := r.db.Query(ctx, `
		SELECT id::text, comment_id::text, owner_uid::text, text, created_at
		FROM replies WHERE comment_id = $1::uuid ORDER BY created_at ASC
	`, commentID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var replies []Reply
	for rows.Next() {
		var rep Reply
		if err := rows.Scan(&rep.ID, &rep.CommentID, &rep.OwnerUID, &rep.Text, &rep.CreatedAt); err != nil {
			return nil, err
		}
		replies = append(replies, rep)
	}
	if replies == nil {
		replies = []Reply{}
	}
	return replies, rows.Err()
}

func (r *RepliesRepository) Create(ctx context.Context, commentID string, ownerUID *string, text string) (*Reply, error) {
	rep := &Reply{}
	err := r.db.QueryRow(ctx, `
		INSERT INTO replies (comment_id, owner_uid, text)
		VALUES ($1::uuid, $2::uuid, $3)
		RETURNING id::text, comment_id::text, owner_uid::text, text, created_at
	`, commentID, ownerUID, text).Scan(
		&rep.ID, &rep.CommentID, &rep.OwnerUID, &rep.Text, &rep.CreatedAt,
	)
	return rep, err
}

// GetCommentOwner returns board_owner_id for a comment.
func (r *RepliesRepository) GetCommentOwner(ctx context.Context, commentID string) (string, error) {
	var ownerUID string
	err := r.db.QueryRow(ctx,
		`SELECT board_owner_id::text FROM comments WHERE id = $1::uuid`, commentID,
	).Scan(&ownerUID)
	return ownerUID, err
}

func (r *RepliesRepository) Delete(ctx context.Context, replyID string) (string, error) {
	var commentID string
	err := r.db.QueryRow(ctx,
		`DELETE FROM replies WHERE id = $1::uuid RETURNING comment_id::text`, replyID,
	).Scan(&commentID)
	return commentID, err
}

func (r *RepliesRepository) GetReplyOwner(ctx context.Context, replyID string) (*string, error) {
	var ownerUID *string
	err := r.db.QueryRow(ctx,
		`SELECT owner_uid::text FROM replies WHERE id = $1::uuid`, replyID,
	).Scan(&ownerUID)
	return ownerUID, err
}

func (r *RepliesRepository) GetBoardOwnerForReply(ctx context.Context, replyID string) (string, error) {
	var boardOwner string
	err := r.db.QueryRow(ctx, `
		SELECT c.board_owner_id::text FROM replies r
		JOIN comments c ON c.id = r.comment_id
		WHERE r.id = $1::uuid`, replyID,
	).Scan(&boardOwner)
	return boardOwner, err
}

// CountByComment returns reply count for a list of comment IDs.
func (r *RepliesRepository) CountByComment(ctx context.Context, commentIDs []string) (map[string]int, error) {
	rows, err := r.db.Query(ctx, `
		SELECT comment_id::text, COUNT(*)::int
		FROM replies WHERE comment_id::text = ANY($1)
		GROUP BY comment_id
	`, commentIDs)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	counts := make(map[string]int)
	for rows.Next() {
		var id string
		var count int
		if err := rows.Scan(&id, &count); err != nil {
			return nil, err
		}
		counts[id] = count
	}
	return counts, rows.Err()
}

// RepliesHandler handles HTTP for replies.
type RepliesHandler struct {
	repo    *RepliesRepository
	hub     *Hub
	mainHub *Hub
}

func NewRepliesHandler(repo *RepliesRepository, hub *Hub) *RepliesHandler {
	return &RepliesHandler{repo: repo, hub: hub}
}

// GET /comments/{id}/replies
func (h *RepliesHandler) List(w http.ResponseWriter, r *http.Request) {
	commentID := chi.URLParam(r, "id")
	replies, err := h.repo.List(r.Context(), commentID)
	if err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(replies) //nolint:errcheck
}

func (h *RepliesHandler) Create(w http.ResponseWriter, r *http.Request) {
	commentID := chi.URLParam(r, "id")
	callerUID := intmw.UID(r)
	var authorUID *string
	if callerUID != "" {
		authorUID = &callerUID
	}

	boardOwnerID, err := h.repo.GetCommentOwner(r.Context(), commentID)
	if err != nil {
		if err == pgx.ErrNoRows {
			http.Error(w, "comment not found", http.StatusNotFound)
			return
		}
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}

	var req struct {
		Text string `json:"text"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Text == "" {
		http.Error(w, "text required", http.StatusBadRequest)
		return
	}

	reply, err := h.repo.Create(r.Context(), commentID, authorUID, req.Text)
	if err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}

	h.hub.Notify(boardOwnerID)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(reply) //nolint:errcheck
}

func (h *RepliesHandler) Delete(w http.ResponseWriter, r *http.Request) {
	replyID := chi.URLParam(r, "id")
	callerUID := intmw.UID(r)
	if callerUID == "" {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	boardOwner, err := h.repo.GetBoardOwnerForReply(r.Context(), replyID)
	if err != nil {
		if err == pgx.ErrNoRows {
			http.Error(w, "not found", http.StatusNotFound)
			return
		}
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}

	replyOwner, err := h.repo.GetReplyOwner(r.Context(), replyID)
	if err != nil {
		if err == pgx.ErrNoRows {
			http.Error(w, "not found", http.StatusNotFound)
			return
		}
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}

	allowed := boardOwner == callerUID
	if !allowed && replyOwner != nil && *replyOwner == callerUID {
		allowed = true
	}
	if !allowed {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}

	_, err = h.repo.Delete(r.Context(), replyID)
	if err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}

	h.hub.Notify(boardOwner)

	w.WriteHeader(http.StatusNoContent)
}
