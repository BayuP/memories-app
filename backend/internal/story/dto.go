package story

// StoryResponse is the JSON response for all story endpoints.
type StoryResponse struct {
	ID        string  `json:"id"`
	TripID    string  `json:"trip_id"`
	Title     *string `json:"title"`
	Body      *string `json:"body"`
	Status    *string `json:"status"`
	CreatedAt string  `json:"created_at"`
	UpdatedAt string  `json:"updated_at"`
}

// PatchStoryRequest is the body for PATCH /trips/{tripID}/story.
type PatchStoryRequest struct {
	Title *string `json:"title"`
	Body  *string `json:"body"`
}

// toStoryResponse converts a Story domain object to its JSON response shape.
func toStoryResponse(s *Story) StoryResponse {
	return StoryResponse{
		ID:        s.ID.String(),
		TripID:    s.TripID.String(),
		Title:     s.Title,
		Body:      s.Body,
		Status:    s.Status,
		CreatedAt: s.CreatedAt.UTC().Format("2006-01-02T15:04:05Z"),
		UpdatedAt: s.UpdatedAt.UTC().Format("2006-01-02T15:04:05Z"),
	}
}
