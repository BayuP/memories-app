package users

// ProfileResponse is the public view of a user returned by GET /me and handle lookup.
type ProfileResponse struct {
	ID          string  `json:"id"`
	Email       string  `json:"email,omitempty"`
	Handle      string  `json:"handle"`
	DisplayName string  `json:"display_name"`
	AvatarURL   *string `json:"avatar_url"`
	CreatedAt   string  `json:"created_at"`
}

// ToProfileResponse converts a User domain entity to its public representation.
func ToProfileResponse(u *User) ProfileResponse {
	return ProfileResponse{
		ID:          u.ID.String(),
		Email:       u.Email,
		Handle:      u.Handle,
		DisplayName: u.DisplayName,
		AvatarURL:   u.AvatarURL,
		CreatedAt:   u.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
	}
}

// PublicProfileResponse is the handle lookup response (no email).
type PublicProfileResponse struct {
	ID          string  `json:"id"`
	Handle      string  `json:"handle"`
	DisplayName string  `json:"display_name"`
	AvatarURL   *string `json:"avatar_url"`
}

// ToPublicProfileResponse creates a handle lookup response without PII.
func ToPublicProfileResponse(u *User) PublicProfileResponse {
	return PublicProfileResponse{
		ID:          u.ID.String(),
		Handle:      u.Handle,
		DisplayName: u.DisplayName,
		AvatarURL:   u.AvatarURL,
	}
}

// UpdateMeRequest carries optional fields for PATCH /me.
type UpdateMeRequest struct {
	DisplayName *string `json:"display_name"`
	AvatarURL   *string `json:"avatar_url"`
}

// SearchResponse wraps a user handle search result.
type SearchResponse struct {
	Users []PublicProfileResponse `json:"users"`
}
