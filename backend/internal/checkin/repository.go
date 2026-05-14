package checkin

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Repository defines the data access contract for check-ins and their layers.
type Repository interface {
	CreateCheckin(ctx context.Context, p CreateCheckinParams) (*Checkin, error)
	FindByID(ctx context.Context, id uuid.UUID) (*Checkin, error)

	UpsertMemory(ctx context.Context, checkinID uuid.UUID, p UpsertMemoryParams) (*Memory, error)
	FindMemory(ctx context.Context, checkinID uuid.UUID) (*Memory, error)

	UpsertLogistics(ctx context.Context, checkinID uuid.UUID, p UpsertLogisticsParams) (*Logistics, error)
	FindLogistics(ctx context.Context, checkinID uuid.UUID) (*Logistics, error)

	UpsertRecommendation(ctx context.Context, checkinID uuid.UUID, p UpsertRecommendationParams) (*Recommendation, error)
	FindRecommendation(ctx context.Context, checkinID uuid.UUID) (*Recommendation, error)

	ListMediaByCheckinID(ctx context.Context, checkinID uuid.UUID) ([]*MediaItem, error)
}

// CreateCheckinParams carries required fields for check-in creation.
type CreateCheckinParams struct {
	TripID          uuid.UUID
	AuthorID        uuid.UUID
	ItineraryItemID *uuid.UUID
	CapturedAt      time.Time
	Lat             *float64
	Lng             *float64
	Kind            string
}

// UpsertMemoryParams carries memory layer fields.
type UpsertMemoryParams struct {
	Note       *string
	Mood       *string
	SharedWith []string
}

// UpsertLogisticsParams carries logistics layer fields.
type UpsertLogisticsParams struct {
	Cost     *float64
	Currency *string
	Notes    *string
}

// UpsertRecommendationParams carries recommendation layer fields.
type UpsertRecommendationParams struct {
	Title  string
	Body   string
	Tags   []string
	Rating *int
}

type postgresRepository struct {
	db *pgxpool.Pool
}

// NewRepository returns a Postgres-backed checkin repository.
func NewRepository(db *pgxpool.Pool) Repository {
	return &postgresRepository{db: db}
}

func (r *postgresRepository) CreateCheckin(ctx context.Context, p CreateCheckinParams) (*Checkin, error) {
	row := r.db.QueryRow(ctx,
		`INSERT INTO checkins (trip_id, author_id, itinerary_item_id, captured_at, lat, lng, kind)
		 VALUES ($1, $2, $3, $4, $5, $6, $7)
		 RETURNING id, trip_id, author_id, itinerary_item_id, captured_at, lat, lng, kind, created_at, updated_at`,
		p.TripID, p.AuthorID, p.ItineraryItemID, p.CapturedAt, p.Lat, p.Lng, p.Kind,
	)
	return scanCheckin(row)
}

func (r *postgresRepository) FindByID(ctx context.Context, id uuid.UUID) (*Checkin, error) {
	row := r.db.QueryRow(ctx,
		`SELECT id, trip_id, author_id, itinerary_item_id, captured_at, lat, lng, kind, created_at, updated_at
		 FROM checkins WHERE id = $1`,
		id,
	)
	c, err := scanCheckin(row)
	if err != nil {
		return nil, fmt.Errorf("find checkin by id: %w", err)
	}
	return c, nil
}

func (r *postgresRepository) UpsertMemory(ctx context.Context, checkinID uuid.UUID, p UpsertMemoryParams) (*Memory, error) {
	sharedWith := p.SharedWith
	if sharedWith == nil {
		sharedWith = []string{}
	}
	row := r.db.QueryRow(ctx,
		`INSERT INTO checkin_memory (checkin_id, note, mood, shared_with)
		 VALUES ($1, $2, $3, $4)
		 ON CONFLICT (checkin_id) DO UPDATE
		   SET note = EXCLUDED.note, mood = EXCLUDED.mood, shared_with = EXCLUDED.shared_with, updated_at = now()
		 RETURNING id, checkin_id, note, mood, shared_with, created_at, updated_at`,
		checkinID, p.Note, p.Mood, sharedWith,
	)
	return scanMemory(row)
}

func (r *postgresRepository) FindMemory(ctx context.Context, checkinID uuid.UUID) (*Memory, error) {
	row := r.db.QueryRow(ctx,
		`SELECT id, checkin_id, note, mood, shared_with, created_at, updated_at
		 FROM checkin_memory WHERE checkin_id = $1`,
		checkinID,
	)
	return scanMemory(row)
}

func (r *postgresRepository) UpsertLogistics(ctx context.Context, checkinID uuid.UUID, p UpsertLogisticsParams) (*Logistics, error) {
	row := r.db.QueryRow(ctx,
		`INSERT INTO checkin_logistics (checkin_id, cost, currency, notes)
		 VALUES ($1, $2, $3, $4)
		 ON CONFLICT (checkin_id) DO UPDATE
		   SET cost = EXCLUDED.cost, currency = EXCLUDED.currency, notes = EXCLUDED.notes, updated_at = now()
		 RETURNING id, checkin_id, cost, currency, notes, created_at, updated_at`,
		checkinID, p.Cost, p.Currency, p.Notes,
	)
	return scanLogistics(row)
}

func (r *postgresRepository) FindLogistics(ctx context.Context, checkinID uuid.UUID) (*Logistics, error) {
	row := r.db.QueryRow(ctx,
		`SELECT id, checkin_id, cost, currency, notes, created_at, updated_at
		 FROM checkin_logistics WHERE checkin_id = $1`,
		checkinID,
	)
	return scanLogistics(row)
}

func (r *postgresRepository) UpsertRecommendation(ctx context.Context, checkinID uuid.UUID, p UpsertRecommendationParams) (*Recommendation, error) {
	tags := p.Tags
	if tags == nil {
		tags = []string{}
	}
	row := r.db.QueryRow(ctx,
		`INSERT INTO checkin_recommendations (checkin_id, title, body, tags, rating)
		 VALUES ($1, $2, $3, $4, $5)
		 ON CONFLICT (checkin_id) DO UPDATE
		   SET title = EXCLUDED.title, body = EXCLUDED.body, tags = EXCLUDED.tags, rating = EXCLUDED.rating, updated_at = now()
		 RETURNING id, checkin_id, title, body, tags, rating, created_at, updated_at`,
		checkinID, p.Title, p.Body, tags, p.Rating,
	)
	return scanRecommendation(row)
}

func (r *postgresRepository) FindRecommendation(ctx context.Context, checkinID uuid.UUID) (*Recommendation, error) {
	row := r.db.QueryRow(ctx,
		`SELECT id, checkin_id, title, body, tags, rating, created_at, updated_at
		 FROM checkin_recommendations WHERE checkin_id = $1`,
		checkinID,
	)
	return scanRecommendation(row)
}

func (r *postgresRepository) ListMediaByCheckinID(ctx context.Context, checkinID uuid.UUID) ([]*MediaItem, error) {
	rows, err := r.db.Query(ctx,
		`SELECT id, checkin_id, owner_id, r2_key, mime, width, height, taken_at, lat, lng, created_at
		 FROM media WHERE checkin_id = $1 ORDER BY created_at`,
		checkinID,
	)
	if err != nil {
		return nil, fmt.Errorf("list media: %w", err)
	}
	defer rows.Close()

	var items []*MediaItem
	for rows.Next() {
		m := &MediaItem{}
		if err := rows.Scan(
			&m.ID, &m.CheckinID, &m.OwnerID, &m.R2Key, &m.Mime,
			&m.Width, &m.Height, &m.TakenAt, &m.Lat, &m.Lng, &m.CreatedAt,
		); err != nil {
			return nil, fmt.Errorf("list media scan: %w", err)
		}
		items = append(items, m)
	}
	return items, rows.Err()
}

type rowScanner interface {
	Scan(dest ...any) error
}

func scanCheckin(row rowScanner) (*Checkin, error) {
	c := &Checkin{}
	if err := row.Scan(
		&c.ID, &c.TripID, &c.AuthorID, &c.ItineraryItemID,
		&c.CapturedAt, &c.Lat, &c.Lng, &c.Kind, &c.CreatedAt, &c.UpdatedAt,
	); err != nil {
		return nil, err
	}
	return c, nil
}

func scanMemory(row rowScanner) (*Memory, error) {
	m := &Memory{}
	if err := row.Scan(&m.ID, &m.CheckinID, &m.Note, &m.Mood, &m.SharedWith, &m.CreatedAt, &m.UpdatedAt); err != nil {
		return nil, err
	}
	if m.SharedWith == nil {
		m.SharedWith = []string{}
	}
	return m, nil
}

func scanLogistics(row rowScanner) (*Logistics, error) {
	l := &Logistics{}
	if err := row.Scan(&l.ID, &l.CheckinID, &l.Cost, &l.Currency, &l.Notes, &l.CreatedAt, &l.UpdatedAt); err != nil {
		return nil, err
	}
	return l, nil
}

func scanRecommendation(row rowScanner) (*Recommendation, error) {
	rec := &Recommendation{}
	if err := row.Scan(&rec.ID, &rec.CheckinID, &rec.Title, &rec.Body, &rec.Tags, &rec.Rating, &rec.CreatedAt, &rec.UpdatedAt); err != nil {
		return nil, err
	}
	if rec.Tags == nil {
		rec.Tags = []string{}
	}
	return rec, nil
}
