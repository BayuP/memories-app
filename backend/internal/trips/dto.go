package trips

// CreateTripRequest is the POST /trips body.
type CreateTripRequest struct {
	Title       string   `json:"title"`
	Destination string   `json:"destination"`
	StartDate   *string  `json:"start_date"`
	EndDate     *string  `json:"end_date"`
	Vibes       []string `json:"vibes"`
}

// UpdateTripRequest is the PATCH /trips/:id body (all fields optional).
type UpdateTripRequest struct {
	Title       *string  `json:"title"`
	Destination *string  `json:"destination"`
	StartDate   *string  `json:"start_date"`
	EndDate     *string  `json:"end_date"`
	Vibes       []string `json:"vibes"`
	Status      *string  `json:"status"`
}

// AddMemberRequest is the POST /trips/:id/members body.
type AddMemberRequest struct {
	UserID string `json:"user_id"`
}

// TripResponse is the summary trip view.
type TripResponse struct {
	ID          string   `json:"id"`
	OwnerID     string   `json:"owner_id"`
	Title       string   `json:"title"`
	Destination string   `json:"destination"`
	StartDate   *string  `json:"start_date"`
	EndDate     *string  `json:"end_date"`
	Vibes       []string `json:"vibes"`
	Status      string   `json:"status"`
	CreatedAt   string   `json:"created_at"`
	UpdatedAt   string   `json:"updated_at"`
}

// TripDetailResponse is the full trip view including members.
type TripDetailResponse struct {
	Trip    TripResponse     `json:"trip"`
	Members []MemberResponse `json:"members"`
}

// MemberResponse represents a trip membership record.
type MemberResponse struct {
	ID        string `json:"id"`
	TripID    string `json:"trip_id"`
	UserID    string `json:"user_id"`
	Role      string `json:"role"`
	CreatedAt string `json:"created_at"`
}

func toTripResponse(t *Trip) TripResponse {
	r := TripResponse{
		ID:          t.ID.String(),
		OwnerID:     t.OwnerID.String(),
		Title:       t.Title,
		Destination: t.Destination,
		Vibes:       t.Vibes,
		Status:      t.Status,
		CreatedAt:   t.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		UpdatedAt:   t.UpdatedAt.Format("2006-01-02T15:04:05Z07:00"),
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

func toMemberResponse(m *Member) MemberResponse {
	return MemberResponse{
		ID:        m.ID.String(),
		TripID:    m.TripID.String(),
		UserID:    m.UserID.String(),
		Role:      m.Role,
		CreatedAt: m.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
	}
}

func toTripDetail(t *Trip, members []*Member) *TripDetailResponse {
	mrs := make([]MemberResponse, len(members))
	for i, m := range members {
		mrs[i] = toMemberResponse(m)
	}
	tr := toTripResponse(t)
	return &TripDetailResponse{Trip: tr, Members: mrs}
}
