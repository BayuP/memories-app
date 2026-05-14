package media

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

// CreateMediaParams carries the initial fields when registering a media upload.
type CreateMediaParams struct {
	OwnerID uuid.UUID
	R2Key   string
	Mime    string
}

// AttachMediaParams carries the fields set after a successful upload.
type AttachMediaParams struct {
	CheckinID *uuid.UUID
	Width     *int
	Height    *int
	TakenAt   *time.Time
	Lat       *float64
	Lng       *float64
}

// Repository defines the data access contract for media.
type Repository interface {
	CreateMedia(ctx context.Context, p CreateMediaParams) (*Media, error)
	FindByID(ctx context.Context, id uuid.UUID) (*Media, error)
	AttachMedia(ctx context.Context, id uuid.UUID, p AttachMediaParams) (*Media, error)
	DeleteMedia(ctx context.Context, id uuid.UUID) error
	FindCheckinTripID(ctx context.Context, mediaID uuid.UUID) (*uuid.UUID, error)
	ListByCheckinID(ctx context.Context, checkinID uuid.UUID) ([]*Media, error)
}

type postgresRepository struct {
	db *pgxpool.Pool
}

// NewRepository returns a Postgres-backed media repository.
func NewRepository(db *pgxpool.Pool) Repository {
	return &postgresRepository{db: db}
}

const mediaColumns = `id, checkin_id, owner_id, r2_key, mime, width, height, taken_at, lat, lng, created_at, updated_at`

func (r *postgresRepository) CreateMedia(ctx context.Context, p CreateMediaParams) (*Media, error) {
	row := r.db.QueryRow(ctx,
		`INSERT INTO media (owner_id, r2_key, mime)
		 VALUES ($1, $2, $3)
		 RETURNING `+mediaColumns,
		p.OwnerID, p.R2Key, p.Mime,
	)
	return scanMedia(row)
}

func (r *postgresRepository) FindByID(ctx context.Context, id uuid.UUID) (*Media, error) {
	row := r.db.QueryRow(ctx,
		`SELECT `+mediaColumns+` FROM media WHERE id = $1`, id,
	)
	m, err := scanMedia(row)
	if err != nil {
		return nil, fmt.Errorf("find media by id: %w", err)
	}
	return m, nil
}

func (r *postgresRepository) AttachMedia(ctx context.Context, id uuid.UUID, p AttachMediaParams) (*Media, error) {
	row := r.db.QueryRow(ctx,
		`UPDATE media
		 SET checkin_id = COALESCE($2, checkin_id),
		     width      = COALESCE($3, width),
		     height     = COALESCE($4, height),
		     taken_at   = COALESCE($5, taken_at),
		     lat        = COALESCE($6, lat),
		     lng        = COALESCE($7, lng),
		     updated_at = now()
		 WHERE id = $1
		 RETURNING `+mediaColumns,
		id, p.CheckinID, p.Width, p.Height, p.TakenAt, p.Lat, p.Lng,
	)
	m, err := scanMedia(row)
	if err != nil {
		return nil, fmt.Errorf("attach media: %w", err)
	}
	return m, nil
}

func (r *postgresRepository) DeleteMedia(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.Exec(ctx, `DELETE FROM media WHERE id = $1`, id)
	if err != nil {
		return fmt.Errorf("delete media: %w", err)
	}
	return nil
}

// FindCheckinTripID returns the trip_id for the checkin attached to a media item.
// Returns nil if the media has no checkin.
func (r *postgresRepository) FindCheckinTripID(ctx context.Context, mediaID uuid.UUID) (*uuid.UUID, error) {
	var tripID *uuid.UUID
	err := r.db.QueryRow(ctx,
		`SELECT c.trip_id FROM media m
		 JOIN checkins c ON c.id = m.checkin_id
		 WHERE m.id = $1`,
		mediaID,
	).Scan(&tripID)
	if err != nil {
		return nil, fmt.Errorf("find checkin trip id: %w", err)
	}
	return tripID, nil
}

func (r *postgresRepository) ListByCheckinID(ctx context.Context, checkinID uuid.UUID) ([]*Media, error) {
	rows, err := r.db.Query(ctx,
		`SELECT `+mediaColumns+` FROM media WHERE checkin_id = $1 ORDER BY created_at`,
		checkinID,
	)
	if err != nil {
		return nil, fmt.Errorf("list media: %w", err)
	}
	defer rows.Close()

	var items []*Media
	for rows.Next() {
		m, err := scanMedia(rows)
		if err != nil {
			return nil, fmt.Errorf("list media scan: %w", err)
		}
		items = append(items, m)
	}
	return items, rows.Err()
}

type rowScanner interface {
	Scan(dest ...any) error
}

func scanMedia(row rowScanner) (*Media, error) {
	m := &Media{}
	if err := row.Scan(
		&m.ID, &m.CheckinID, &m.OwnerID, &m.R2Key, &m.Mime,
		&m.Width, &m.Height, &m.TakenAt, &m.Lat, &m.Lng,
		&m.CreatedAt, &m.UpdatedAt,
	); err != nil {
		return nil, err
	}
	return m, nil
}
