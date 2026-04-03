package users

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/wtf/backend/internal/model"
)

type Repository struct {
	db *pgxpool.Pool
}

func NewRepository(db *pgxpool.Pool) *Repository {
	return &Repository{db: db}
}

const userColumns = `uid::text, username, display_name, bio, avatar_url, is_public, comment_count, created_at, updated_at`

func scanUser(row pgx.Row) (*model.User, error) {
	u := &model.User{}
	err := row.Scan(&u.UID, &u.Username, &u.DisplayName, &u.Bio, &u.AvatarURL, &u.IsPublic, &u.CommentCount, &u.CreatedAt, &u.UpdatedAt)
	if err != nil {
		return nil, err
	}
	return u, nil
}

func (r *Repository) GetByUID(ctx context.Context, uid string) (*model.User, error) {
	return scanUser(r.db.QueryRow(ctx,
		`SELECT `+userColumns+` FROM users WHERE uid = $1::uuid`, uid))
}

func (r *Repository) GetByUsername(ctx context.Context, username string) (*model.User, error) {
	return scanUser(r.db.QueryRow(ctx,
		`SELECT `+userColumns+` FROM users WHERE username = $1`, username))
}

func (r *Repository) UsernameExists(ctx context.Context, username string) (bool, error) {
	var exists bool
	err := r.db.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM users WHERE username = $1)`, username).Scan(&exists)
	return exists, err
}

// SetProfile sets username/displayName/bio for an existing user (profile creation).
func (r *Repository) SetProfile(ctx context.Context, uid, username, displayName, bio string) error {
	_, err := r.db.Exec(ctx, `
		UPDATE users
		SET username = $2, display_name = $3, bio = $4, updated_at = NOW()
		WHERE uid = $1::uuid
	`, uid, username, displayName, bio)
	return err
}

type UpdateFields struct {
	DisplayName *string
	Bio         *string
	IsPublic    *bool
	AvatarURL   *string
}

func (r *Repository) Update(ctx context.Context, uid string, f UpdateFields) error {
	_, err := r.db.Exec(ctx, `
		UPDATE users SET
			display_name = COALESCE($2, display_name),
			bio          = COALESCE($3, bio),
			is_public    = COALESCE($4, is_public),
			avatar_url   = COALESCE($5, avatar_url),
			updated_at   = NOW()
		WHERE uid = $1::uuid
	`, uid, f.DisplayName, f.Bio, f.IsPublic, f.AvatarURL)
	return err
}

func (r *Repository) Delete(ctx context.Context, uid string) error {
	_, err := r.db.Exec(ctx, `DELETE FROM users WHERE uid = $1::uuid`, uid)
	return err
}

func (r *Repository) UpdateAvatar(ctx context.Context, uid, avatarURL string) error {
	_, err := r.db.Exec(ctx, `UPDATE users SET avatar_url = $2, updated_at = NOW() WHERE uid = $1::uuid`, uid, avatarURL)
	return err
}

func (r *Repository) ReactionStatsForBoard(ctx context.Context, boardOwnerID string) (map[string]int, error) {
	out := model.DefaultReactions()
	rows, err := r.db.Query(ctx, `
		SELECT r.reaction_key, COUNT(*)::int
		FROM reactions r
		INNER JOIN comments c ON c.id = r.comment_id
		WHERE c.board_owner_id = $1::uuid
		GROUP BY r.reaction_key
	`, boardOwnerID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var key string
		var n int
		if err := rows.Scan(&key, &n); err != nil {
			return nil, err
		}
		out[key] = n
	}
	return out, rows.Err()
}

func (r *Repository) Search(ctx context.Context, query string, limit int) ([]*model.User, error) {
	rows, err := r.db.Query(ctx, `
		SELECT `+userColumns+`
		FROM users
		WHERE username LIKE $1 || '%' AND username IS NOT NULL
		ORDER BY username
		LIMIT $2
	`, query, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var users []*model.User
	for rows.Next() {
		u, err := scanUser(rows)
		if err != nil {
			return nil, err
		}
		users = append(users, u)
	}
	return users, rows.Err()
}

// IsUniqueViolation checks for PostgreSQL unique constraint violation (code 23505).
func IsUniqueViolation(err error) bool {
	var pgErr *pgconn.PgError
	return errors.As(err, &pgErr) && pgErr.Code == "23505"
}
