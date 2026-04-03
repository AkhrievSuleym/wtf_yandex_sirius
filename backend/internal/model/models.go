package model

import "time"

const (
	ReactionFire  = "fire"
	ReactionHeart = "heart"
	ReactionLaugh = "laugh"
	ReactionPoop  = "poop"
	ReactionClown = "clown"
)

var DefaultReactionKeys = []string{ReactionFire, ReactionHeart, ReactionLaugh, ReactionPoop, ReactionClown}

type User struct {
	UID          string    `json:"uid"`
	Username     *string   `json:"username"`
	DisplayName  string    `json:"displayName"`
	Bio          string    `json:"bio"`
	AvatarURL    *string   `json:"avatarUrl"`
	IsPublic     bool      `json:"isPublic"`
	CommentCount  int            `json:"commentCount"`
	ReactionStats map[string]int `json:"reactionStats,omitempty"`
	CreatedAt     time.Time      `json:"createdAt"`
	UpdatedAt     time.Time      `json:"updatedAt"`
}

type Comment struct {
	ID           string              `json:"id"`
	BoardOwnerID string              `json:"boardOwnerId"`
	AuthorID     *string             `json:"authorId"`
	Text         string              `json:"text"`
	IsRead       bool                `json:"isRead"`
	CreatedAt    time.Time           `json:"createdAt"`
	Reactions    map[string]int      `json:"reactions"`
	ReactedBy    map[string][]string `json:"reactedBy"`
	ReplyCount   int                 `json:"replyCount"`
}

type Profile struct {
	UID          string  `json:"uid"`
	Username     string  `json:"username"`
	DisplayName  string  `json:"displayName"`
	Bio          string  `json:"bio"`
	AvatarURL    *string `json:"avatarUrl"`
	CommentCount int     `json:"commentCount"`
	IsPublic     bool    `json:"isPublic"`
}

func DefaultReactions() map[string]int {
	return map[string]int{
		ReactionFire: 0, ReactionHeart: 0, ReactionLaugh: 0, ReactionPoop: 0, ReactionClown: 0,
	}
}

func DefaultReactedBy() map[string][]string {
	return map[string][]string{
		ReactionFire: {}, ReactionHeart: {}, ReactionLaugh: {}, ReactionPoop: {}, ReactionClown: {},
	}
}

func IsValidReactionKey(key string) bool {
	for _, k := range DefaultReactionKeys {
		if k == key {
			return true
		}
	}
	return false
}
