package story

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

// UpsertStoryParams carries fields for creating or updating a story.
type UpsertStoryParams struct {
	Title  *string
	Body   *string
	Status *string
}

// Repository defines the data access contract for trip stories.
type Repository interface {
	UpsertStory(ctx context.Context, tripID uuid.UUID, p UpsertStoryParams) (*Story, error)
	FindByTripID(ctx context.Context, tripID uuid.UUID) (*Story, error)
}

type postgresRepository struct {
	db *pgxpool.Pool
}

// NewRepository returns a Postgres-backed story repository.
func NewRepository(db *pgxpool.Pool) Repository {
	return &postgresRepository{db: db}
}

// UpsertStory inserts or updates the single story row for a trip.
func (r *postgresRepository) UpsertStory(ctx context.Context, tripID uuid.UUID, p UpsertStoryParams) (*Story, error) {
	row := r.db.QueryRow(ctx,
		`INSERT INTO trip_stories (trip_id, title, body, status)
		 VALUES ($1, $2, $3, $4)
		 ON CONFLICT (trip_id) DO UPDATE
		   SET title = EXCLUDED.title,
		       body = EXCLUDED.body,
		       status = EXCLUDED.status,
		       updated_at = now()
		 RETURNING id, trip_id, title, body, status, created_at, updated_at`,
		tripID, p.Title, p.Body, p.Status,
	)
	return scanStory(row)
}

// FindByTripID returns the story for a trip, or pgx.ErrNoRows if none exists.
func (r *postgresRepository) FindByTripID(ctx context.Context, tripID uuid.UUID) (*Story, error) {
	row := r.db.QueryRow(ctx,
		`SELECT id, trip_id, title, body, status, created_at, updated_at
		 FROM trip_stories WHERE trip_id = $1`,
		tripID,
	)
	s, err := scanStory(row)
	if err != nil {
		return nil, fmt.Errorf("find story by trip id: %w", err)
	}
	return s, nil
}

type rowScanner interface {
	Scan(dest ...any) error
}

func scanStory(row rowScanner) (*Story, error) {
	s := &Story{}
	if err := row.Scan(
		&s.ID, &s.TripID, &s.Title, &s.Body, &s.Status, &s.CreatedAt, &s.UpdatedAt,
	); err != nil {
		return nil, err
	}
	return s, nil
}
