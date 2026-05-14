package checkin

// CreateCheckinRequest is the POST /trips/:id/checkins body.
type CreateCheckinRequest struct {
	ItineraryItemID *string  `json:"itinerary_item_id"`
	CapturedAt      string   `json:"captured_at"`
	Lat             *float64 `json:"lat"`
	Lng             *float64 `json:"lng"`
	Kind            string   `json:"kind"` // "planned" or "spontaneous"
}

// UpsertMemoryRequest is the PUT /checkins/:id/memory body.
type UpsertMemoryRequest struct {
	Note       *string  `json:"note"`
	Mood       *string  `json:"mood"`
	SharedWith []string `json:"shared_with"`
}

// UpsertLogisticsRequest is the PUT /checkins/:id/logistics body.
// PRIVACY: this layer is never returned on public endpoints.
type UpsertLogisticsRequest struct {
	Cost     *float64 `json:"cost"`
	Currency *string  `json:"currency"`
	Notes    *string  `json:"notes"`
}

// UpsertRecommendationRequest is the PUT /checkins/:id/recommendation body.
type UpsertRecommendationRequest struct {
	Title  string   `json:"title"`
	Body   string   `json:"body"`
	Tags   []string `json:"tags"`
	Rating *int     `json:"rating"`
}

// CheckinResponse is the full check-in view including all layers and media.
type CheckinResponse struct {
	ID              string              `json:"id"`
	TripID          string              `json:"trip_id"`
	AuthorID        string              `json:"author_id"`
	ItineraryItemID *string             `json:"itinerary_item_id"`
	CapturedAt      string              `json:"captured_at"`
	Lat             *float64            `json:"lat"`
	Lng             *float64            `json:"lng"`
	Kind            string              `json:"kind"`
	Memory          *MemoryResponse     `json:"memory"`
	Logistics       *LogisticsResponse  `json:"logistics"`
	Recommendation  *RecommendResponse  `json:"recommendation"`
	Media           []MediaItemResponse `json:"media"`
	CreatedAt       string              `json:"created_at"`
}

// MemoryResponse is the public view of the memory layer.
type MemoryResponse struct {
	ID         string   `json:"id"`
	Note       *string  `json:"note"`
	Mood       *string  `json:"mood"`
	SharedWith []string `json:"shared_with"`
}

// LogisticsResponse is the private view of the logistics layer.
// PRIVACY: only included in member responses.
type LogisticsResponse struct {
	ID       string   `json:"id"`
	Cost     *float64 `json:"cost"`
	Currency *string  `json:"currency"`
	Notes    *string  `json:"notes"`
}

// RecommendResponse is the public view of the recommendation layer.
type RecommendResponse struct {
	ID     string   `json:"id"`
	Title  string   `json:"title"`
	Body   string   `json:"body"`
	Tags   []string `json:"tags"`
	Rating *int     `json:"rating"`
}

// MediaItemResponse is the media view within a check-in.
type MediaItemResponse struct {
	ID      string   `json:"id"`
	R2Key   string   `json:"r2_key"`
	Mime    string   `json:"mime"`
	Width   *int     `json:"width"`
	Height  *int     `json:"height"`
	TakenAt *string  `json:"taken_at"`
	Lat     *float64 `json:"lat"`
	Lng     *float64 `json:"lng"`
}

func toCheckinResponse(c *Checkin, mem *Memory, log *Logistics, rec *Recommendation, media []*MediaItem) CheckinResponse {
	r := CheckinResponse{
		ID:         c.ID.String(),
		TripID:     c.TripID.String(),
		AuthorID:   c.AuthorID.String(),
		CapturedAt: c.CapturedAt.Format("2006-01-02T15:04:05Z07:00"),
		Lat:        c.Lat,
		Lng:        c.Lng,
		Kind:       c.Kind,
		Media:      []MediaItemResponse{},
		CreatedAt:  c.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
	}
	if c.ItineraryItemID != nil {
		s := c.ItineraryItemID.String()
		r.ItineraryItemID = &s
	}
	if mem != nil {
		r.Memory = &MemoryResponse{
			ID:         mem.ID.String(),
			Note:       mem.Note,
			Mood:       mem.Mood,
			SharedWith: mem.SharedWith,
		}
	}
	if log != nil {
		r.Logistics = &LogisticsResponse{
			ID:       log.ID.String(),
			Cost:     log.Cost,
			Currency: log.Currency,
			Notes:    log.Notes,
		}
	}
	if rec != nil {
		r.Recommendation = &RecommendResponse{
			ID:     rec.ID.String(),
			Title:  rec.Title,
			Body:   rec.Body,
			Tags:   rec.Tags,
			Rating: rec.Rating,
		}
	}
	for _, m := range media {
		item := MediaItemResponse{
			ID:     m.ID.String(),
			R2Key:  m.R2Key,
			Mime:   m.Mime,
			Width:  m.Width,
			Height: m.Height,
			Lat:    m.Lat,
			Lng:    m.Lng,
		}
		if m.TakenAt != nil {
			s := m.TakenAt.Format("2006-01-02T15:04:05Z07:00")
			item.TakenAt = &s
		}
		r.Media = append(r.Media, item)
	}
	return r
}
