package media

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

// Uploader generates presigned upload URLs and deletes objects.
type Uploader interface {
	PresignPutURL(ctx context.Context, key, mime string, expires time.Duration) (string, error)
	DeleteObject(ctx context.Context, key string) error
}

// TripChecker verifies trip membership without importing the trips package.
type TripChecker interface {
	IsMember(ctx context.Context, tripID, userID uuid.UUID) (bool, error)
}

// Service handles media business logic.
type Service struct {
	repo    Repository
	upload  Uploader
	tripChk TripChecker
}

// NewService wires media service dependencies.
func NewService(repo Repository, upload Uploader, tripChk TripChecker) *Service {
	return &Service{repo: repo, upload: upload, tripChk: tripChk}
}

// GetUploadURL creates a pending media record and returns a presigned PUT URL.
func (s *Service) GetUploadURL(ctx context.Context, callerID uuid.UUID, req UploadURLRequest) (*UploadURLResponse, error) {
	if req.Mime == "" {
		return nil, fmt.Errorf("mime is required")
	}

	r2Key := fmt.Sprintf("uploads/%s/%s", callerID, uuid.New())

	m, err := s.repo.CreateMedia(ctx, CreateMediaParams{
		OwnerID: callerID,
		R2Key:   r2Key,
		Mime:    req.Mime,
	})
	if err != nil {
		return nil, fmt.Errorf("create media record: %w", err)
	}

	uploadURL, err := s.upload.PresignPutURL(ctx, r2Key, req.Mime, 15*time.Minute)
	if err != nil {
		return nil, fmt.Errorf("presign url: %w", err)
	}

	return &UploadURLResponse{
		MediaID:   m.ID.String(),
		UploadURL: uploadURL,
		R2Key:     r2Key,
	}, nil
}

// AttachMedia updates a media record with upload metadata and optionally attaches it to a checkin.
func (s *Service) AttachMedia(ctx context.Context, mediaID, callerID uuid.UUID, req AttachRequest) (*MediaResponse, error) {
	m, err := s.repo.FindByID(ctx, mediaID)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("find media: %w", err)
	}

	if m.OwnerID != callerID {
		return nil, ErrForbidden
	}

	p := AttachMediaParams{
		Width:  req.Width,
		Height: req.Height,
		Lat:    req.Lat,
		Lng:    req.Lng,
	}
	if req.TakenAt != nil {
		t, err := time.Parse(time.RFC3339, *req.TakenAt)
		if err == nil {
			p.TakenAt = &t
		}
	}
	if req.CheckinID != nil {
		id, err := uuid.Parse(*req.CheckinID)
		if err == nil {
			p.CheckinID = &id
		}
	}

	updated, err := s.repo.AttachMedia(ctx, mediaID, p)
	if err != nil {
		return nil, fmt.Errorf("attach media: %w", err)
	}

	r := toMediaResponse(updated)
	return &r, nil
}

// DeleteMedia removes a media record and its R2 object.
func (s *Service) DeleteMedia(ctx context.Context, mediaID, callerID uuid.UUID) error {
	m, err := s.repo.FindByID(ctx, mediaID)
	if err != nil {
		if err == pgx.ErrNoRows {
			return ErrNotFound
		}
		return fmt.Errorf("find media: %w", err)
	}

	if m.OwnerID != callerID {
		return ErrForbidden
	}

	if err := s.upload.DeleteObject(ctx, m.R2Key); err != nil {
		return fmt.Errorf("delete r2 object: %w", err)
	}

	return s.repo.DeleteMedia(ctx, mediaID)
}
