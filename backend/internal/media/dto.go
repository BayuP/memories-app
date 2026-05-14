package media

// UploadURLRequest is the POST /media/upload-url body.
type UploadURLRequest struct {
	Mime string `json:"mime"`
}

// UploadURLResponse is the presigned upload URL response.
type UploadURLResponse struct {
	MediaID   string `json:"media_id"`
	UploadURL string `json:"upload_url"`
	R2Key     string `json:"r2_key"`
}

// AttachRequest is the PATCH /media/:id body.
type AttachRequest struct {
	CheckinID *string  `json:"checkin_id"`
	Width     *int     `json:"width"`
	Height    *int     `json:"height"`
	TakenAt   *string  `json:"taken_at"`
	Lat       *float64 `json:"lat"`
	Lng       *float64 `json:"lng"`
}

// MediaResponse is the public view of a media record.
type MediaResponse struct {
	ID        string   `json:"id"`
	CheckinID *string  `json:"checkin_id"`
	OwnerID   string   `json:"owner_id"`
	R2Key     string   `json:"r2_key"`
	Mime      string   `json:"mime"`
	Width     *int     `json:"width"`
	Height    *int     `json:"height"`
	TakenAt   *string  `json:"taken_at"`
	Lat       *float64 `json:"lat"`
	Lng       *float64 `json:"lng"`
	CreatedAt string   `json:"created_at"`
}

func toMediaResponse(m *Media) MediaResponse {
	r := MediaResponse{
		ID:        m.ID.String(),
		OwnerID:   m.OwnerID.String(),
		R2Key:     m.R2Key,
		Mime:      m.Mime,
		Width:     m.Width,
		Height:    m.Height,
		Lat:       m.Lat,
		Lng:       m.Lng,
		CreatedAt: m.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
	}
	if m.CheckinID != nil {
		s := m.CheckinID.String()
		r.CheckinID = &s
	}
	if m.TakenAt != nil {
		s := m.TakenAt.Format("2006-01-02T15:04:05Z07:00")
		r.TakenAt = &s
	}
	return r
}
