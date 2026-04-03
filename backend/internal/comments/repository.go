package comments

import (
	"context"
	"encoding/json"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/wtf/backend/internal/model"
)

type Repository struct {
	db *pgxpool.Pool
}

func NewRepository(db *pgxpool.Pool) *Repository {
	return &Repository{db: db}
}

// ListByOwner returns all comments for a board with aggregated reactions.
func (r *Repository) ListByOwner(ctx context.Context, ownerID string) ([]model.Comment, error) {
	// Fetch comments
	rows, err := r.db.Query(ctx, `
		SELECT id::text, board_owner_id::text, author_id::text, text, is_read, created_at
		FROM comments
		WHERE board_owner_id = $1::uuid
		ORDER BY created_at DESC
	`, ownerID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var comments []model.Comment
	idIndex := make(map[string]int)

	for rows.Next() {
		var c model.Comment
		var authorID *string
		if err := rows.Scan(&c.ID, &c.BoardOwnerID, &authorID, &c.Text, &c.IsRead, &c.CreatedAt); err != nil {
			return nil, err
		}
		c.AuthorID = authorID
		c.Reactions = model.DefaultReactions()
		c.ReactedBy = model.DefaultReactedBy()
		idIndex[c.ID] = len(comments)
		comments = append(comments, c)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	if len(comments) == 0 {
		return []model.Comment{}, nil
	}

	// Fetch reactions
	commentIDs := make([]string, len(comments))
	for i, c := range comments {
		commentIDs[i] = c.ID
	}

	rxRows, err := r.db.Query(ctx, `
		SELECT comment_id::text, reaction_key, user_id::text
		FROM reactions
		WHERE comment_id::text = ANY($1)
	`, commentIDs)
	if err != nil {
		return nil, err
	}
	defer rxRows.Close()

	for rxRows.Next() {
		var commentID, key, userID string
		if err := rxRows.Scan(&commentID, &key, &userID); err != nil {
			return nil, err
		}
		if i, ok := idIndex[commentID]; ok {
			comments[i].Reactions[key]++
			comments[i].ReactedBy[key] = append(comments[i].ReactedBy[key], userID)
		}
	}

	if err := rxRows.Err(); err != nil {
		return nil, err
	}

	// Fetch reply counts
	rcRows, err := r.db.Query(ctx, `
		SELECT comment_id::text, COUNT(*)::int
		FROM replies WHERE comment_id::text = ANY($1)
		GROUP BY comment_id
	`, commentIDs)
	if err != nil {
		return comments, nil // non-fatal
	}
	defer rcRows.Close()
	for rcRows.Next() {
		var cid string
		var count int
		if err := rcRows.Scan(&cid, &count); err != nil {
			continue
		}
		if i, ok := idIndex[cid]; ok {
			comments[i].ReplyCount = count
		}
	}

	return comments, rcRows.Err()
}

// Create inserts a new comment and increments the board owner's comment count.
func (r *Repository) Create(ctx context.Context, boardOwnerID string, authorID *string, text string) (*model.Comment, error) {
	var id string
	err := r.db.QueryRow(ctx, `
		INSERT INTO comments (board_owner_id, author_id, text)
		VALUES ($1::uuid, $2::uuid, $3)
		RETURNING id::text
	`, boardOwnerID, authorID, text).Scan(&id)
	if err != nil {
		return nil, err
	}

	// Increment comment count
	_, _ = r.db.Exec(ctx, `UPDATE users SET comment_count = comment_count + 1 WHERE uid = $1::uuid`, boardOwnerID)

	return &model.Comment{
		ID:           id,
		BoardOwnerID: boardOwnerID,
		AuthorID:     authorID,
		Text:         text,
		IsRead:       false,
		Reactions:    model.DefaultReactions(),
		ReactedBy:    model.DefaultReactedBy(),
	}, nil
}

func (r *Repository) MarkAsRead(ctx context.Context, commentID string) error {
	_, err := r.db.Exec(ctx, `UPDATE comments SET is_read = true WHERE id = $1::uuid`, commentID)
	return err
}

// ToggleReaction adds or removes a reaction. Returns true if added, false if removed.
func (r *Repository) ToggleReaction(ctx context.Context, commentID, reactionKey, userID string) (bool, error) {
	result, err := r.db.Exec(ctx, `
		DELETE FROM reactions
		WHERE comment_id = $1::uuid AND reaction_key = $2 AND user_id = $3::uuid
	`, commentID, reactionKey, userID)
	if err != nil {
		return false, err
	}
	if result.RowsAffected() > 0 {
		return false, nil // removed
	}

	_, err = r.db.Exec(ctx, `
		INSERT INTO reactions (comment_id, reaction_key, user_id)
		VALUES ($1::uuid, $2, $3::uuid)
		ON CONFLICT DO NOTHING
	`, commentID, reactionKey, userID)
	return err == nil, err
}

// GetOwner returns the board_owner_id for a given comment.
func (r *Repository) GetOwner(ctx context.Context, commentID string) (string, error) {
	var ownerID string
	err := r.db.QueryRow(ctx, `SELECT board_owner_id::text FROM comments WHERE id = $1::uuid`, commentID).Scan(&ownerID)
	return ownerID, err
}

func (r *Repository) Delete(ctx context.Context, commentID string) error {
	_, err := r.db.Exec(ctx, `DELETE FROM comments WHERE id = $1::uuid`, commentID)
	return err
}

// GetWithReactions returns a single comment with its reactions.
func (r *Repository) GetWithReactions(ctx context.Context, commentID string) (*model.Comment, error) {
	var c model.Comment
	var authorID *string
	err := r.db.QueryRow(ctx, `
		SELECT id::text, board_owner_id::text, author_id::text, text, is_read, created_at
		FROM comments WHERE id = $1::uuid
	`, commentID).Scan(&c.ID, &c.BoardOwnerID, &authorID, &c.Text, &c.IsRead, &c.CreatedAt)
	if err != nil {
		return nil, err
	}
	c.AuthorID = authorID
	c.Reactions = model.DefaultReactions()
	c.ReactedBy = model.DefaultReactedBy()

	rxRows, err := r.db.Query(ctx, `
		SELECT reaction_key, user_id::text FROM reactions WHERE comment_id = $1::uuid
	`, commentID)
	if err != nil {
		return nil, err
	}
	defer rxRows.Close()
	for rxRows.Next() {
		var key, uid string
		if err := rxRows.Scan(&key, &uid); err != nil {
			return nil, err
		}
		c.Reactions[key]++
		c.ReactedBy[key] = append(c.ReactedBy[key], uid)
	}
	return &c, rxRows.Err()
}

// jsonStr is a helper used in SSE events.
func jsonStr(v any) string {
	b, _ := json.Marshal(v)
	return string(b)
}
