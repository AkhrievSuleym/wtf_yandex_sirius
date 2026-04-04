package favorites

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/wtf/backend/internal/model"
)

type Repository struct {
	db *pgxpool.Pool
}

func NewRepository(db *pgxpool.Pool) *Repository {
	return &Repository{db: db}
}

func (r *Repository) List(ctx context.Context, ownerUID string) ([]model.Profile, error) {
	rows, err := r.db.Query(ctx, `
		SELECT u.uid::text, u.username, u.display_name, u.bio, u.avatar_url, u.comment_count, u.is_public
		FROM favorites f
		JOIN users u ON u.uid = f.favorite_uid
		WHERE f.owner_uid = $1::uuid
		ORDER BY f.created_at DESC
	`, ownerUID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var profiles []model.Profile
	for rows.Next() {
		var p model.Profile
		var username *string
		if err := rows.Scan(&p.UID, &username, &p.DisplayName, &p.Bio, &p.AvatarURL, &p.CommentCount, &p.IsPublic); err != nil {
			return nil, err
		}
		if username != nil {
			p.Username = *username
		}
		profiles = append(profiles, p)
	}
	if profiles == nil {
		profiles = []model.Profile{}
	}
	return profiles, rows.Err()
}

func (r *Repository) Add(ctx context.Context, ownerUID, favoriteUID string) error {
	_, err := r.db.Exec(ctx, `
		INSERT INTO favorites (owner_uid, favorite_uid) VALUES ($1::uuid, $2::uuid)
		ON CONFLICT DO NOTHING
	`, ownerUID, favoriteUID)
	return err
}

func (r *Repository) Remove(ctx context.Context, ownerUID, favoriteUID string) error {
	_, err := r.db.Exec(ctx, `
		DELETE FROM favorites WHERE owner_uid = $1::uuid AND favorite_uid = $2::uuid
	`, ownerUID, favoriteUID)
	return err
}

func (r *Repository) Exists(ctx context.Context, ownerUID, favoriteUID string) (bool, error) {
	var exists bool
	err := r.db.QueryRow(ctx, `
		SELECT EXISTS(SELECT 1 FROM favorites WHERE owner_uid = $1::uuid AND favorite_uid = $2::uuid)
	`, ownerUID, favoriteUID).Scan(&exists)
	return exists, err
}
