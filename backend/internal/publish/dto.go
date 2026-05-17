package publish

// PublicTripResponse is the public trip view (no member info, no logistics).
type PublicTripResponse struct {
	ID          string   `json:"id"`
	Title       string   `json:"title"`
	Destination string   `json:"destination"`
	StartDate   *string  `json:"start_date"`
	EndDate     *string  `json:"end_date"`
	Vibes       []string `json:"vibes"`
}

type PublicItemResponse struct {
	ID           string   `json:"id"`
	Day          int      `json:"day"`
	StartTime    *string  `json:"start_time"`
	Title        string   `json:"title"`
	Description  *string  `json:"description"`
	LocationName *string  `json:"location_name"`
	Lat          *float64 `json:"lat"`
	Lng          *float64 `json:"lng"`
	Source       string   `json:"source"`
}

type PublicCheckinResponse struct {
	ID             string             `json:"id"`
	CapturedAt     string             `json:"captured_at"`
	Lat            *float64           `json:"lat"`
	Lng            *float64           `json:"lng"`
	Kind           string             `json:"kind"`
	Recommendation *RecommendResponse `json:"recommendation"`
}

type RecommendResponse struct {
	Title  string   `json:"title"`
	Body   string   `json:"body"`
	Tags   []string `json:"tags"`
	Rating *int     `json:"rating"`
}

type PublicTripDetailResponse struct {
	Trip     PublicTripResponse      `json:"trip"`
	Items    []PublicItemResponse    `json:"items"`
	Checkins []PublicCheckinResponse `json:"checkins"`
}

func toPublicTripResponse(t *PublicTrip) PublicTripResponse {
	r := PublicTripResponse{
		ID:          t.ID.String(),
		Title:       t.Title,
		Destination: t.Destination,
		Vibes:       t.Vibes,
	}
	if t.StartDate != nil {
		s := t.StartDate.Format("2006-01-02")
		r.StartDate = &s
	}
	if t.EndDate != nil {
		e := t.EndDate.Format("2006-01-02")
		r.EndDate = &e
	}
	if r.Vibes == nil {
		r.Vibes = []string{}
	}
	return r
}

func toPublicItemResponse(item *PublicItem) PublicItemResponse {
	return PublicItemResponse{
		ID:           item.ID.String(),
		Day:          item.Day,
		StartTime:    item.StartTime,
		Title:        item.Title,
		Description:  item.Description,
		LocationName: item.LocationName,
		Lat:          item.Lat,
		Lng:          item.Lng,
		Source:       item.Source,
	}
}

func toPublicCheckinResponse(c *PublicCheckin) PublicCheckinResponse {
	r := PublicCheckinResponse{
		ID:         c.ID.String(),
		CapturedAt: c.CapturedAt.Format("2006-01-02T15:04:05Z07:00"),
		Lat:        c.Lat,
		Lng:        c.Lng,
		Kind:       c.Kind,
	}
	if c.RecTitle != nil && c.RecBody != nil {
		tags := c.RecTags
		if tags == nil {
			tags = []string{}
		}
		r.Recommendation = &RecommendResponse{
			Title:  *c.RecTitle,
			Body:   *c.RecBody,
			Tags:   tags,
			Rating: c.RecRating,
		}
	}
	return r
}
