package publish

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Repository defines the data access contract for public trip reads.
type Repository interface {
	FindPublishedTrip(ctx context.Context, id uuid.UUID) (*PublicTrip, error)
	ListItemsByTripID(ctx context.Context, tripID uuid.UUID) ([]*PublicItem, error)
	ListPublicCheckinsByTripID(ctx context.Context, tripID uuid.UUID) ([]*PublicCheckin, error)
}

type postgresRepository struct {
	db *pgxpool.Pool
}

// NewRepository returns a Postgres-backed publish repository.
func NewRepository(db *pgxpool.Pool) Repository {
	return &postgresRepository{db: db}
}

func (r *postgresRepository) FindPublishedTrip(ctx context.Context, id uuid.UUID) (*PublicTrip, error) {
	row := r.db.QueryRow(ctx,
		`SELECT id, title, destination, start_date, end_date, vibes, status
		 FROM trips WHERE id = $1 AND status = 'published'`,
		id,
	)

	t := &PublicTrip{}
	var startDate, endDate pgtype.Date
	if err := row.Scan(&t.ID, &t.Title, &t.Destination, &startDate, &endDate, &t.Vibes, &t.Status); err != nil {
		return nil, err
	}
	if startDate.Valid {
		sd := startDate.Time
		t.StartDate = &sd
	}
	if endDate.Valid {
		ed := endDate.Time
		t.EndDate = &ed
	}
	if t.Vibes == nil {
		t.Vibes = []string{}
	}
	return t, nil
}

func (r *postgresRepository) ListItemsByTripID(ctx context.Context, tripID uuid.UUID) ([]*PublicItem, error) {
	rows, err := r.db.Query(ctx,
		`SELECT id, trip_id, day, start_time, title, description, location_name, lat, lng, source
		 FROM itinerary_items WHERE trip_id = $1 ORDER BY day, start_time NULLS LAST, created_at`,
		tripID,
	)
	if err != nil {
		return nil, fmt.Errorf("list items: %w", err)
	}
	defer rows.Close()

	var items []*PublicItem
	for rows.Next() {
		item := &PublicItem{}
		if err := rows.Scan(
			&item.ID, &item.TripID, &item.Day, &item.StartTime,
			&item.Title, &item.Description, &item.LocationName,
			&item.Lat, &item.Lng, &item.Source,
		); err != nil {
			return nil, fmt.Errorf("list items scan: %w", err)
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *postgresRepository) ListPublicCheckinsByTripID(ctx context.Context, tripID uuid.UUID) ([]*PublicCheckin, error) {
	rows, err := r.db.Query(ctx,
		`SELECT c.id, c.captured_at, c.lat, c.lng, c.kind,
		        r.title, r.body, r.tags, r.rating
		 FROM checkins c
		 LEFT JOIN checkin_recommendations r ON r.checkin_id = c.id
		 WHERE c.trip_id = $1
		 ORDER BY c.captured_at`,
		tripID,
	)
	if err != nil {
		return nil, fmt.Errorf("list checkins: %w", err)
	}
	defer rows.Close()

	var checkins []*PublicCheckin
	for rows.Next() {
		c := &PublicCheckin{}
		var recTitle, recBody *string
		var recTags []string
		var recRating *int
		if err := rows.Scan(
			&c.ID, &c.CapturedAt, &c.Lat, &c.Lng, &c.Kind,
			&recTitle, &recBody, &recTags, &recRating,
		); err != nil {
			return nil, fmt.Errorf("list checkins scan: %w", err)
		}
		c.RecTitle = recTitle
		c.RecBody = recBody
		c.RecTags = recTags
		c.RecRating = recRating
		checkins = append(checkins, c)
	}
	return checkins, rows.Err()
}
