package itinerary

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

// ReorderItemParam carries id and desired sort_order for a single item.
type ReorderItemParam struct {
	ID        uuid.UUID
	SortOrder int
}

// CreateItemParams carries required fields for item creation.
type CreateItemParams struct {
	TripID       uuid.UUID
	Day          int
	StartTime    *string
	EndTime      *string
	Title        string
	Description  *string
	LocationName *string
	Lat          *float64
	Lng          *float64
	Category     *string
	Source       string
}

// UpdateItemParams carries the full merged state for an item update.
type UpdateItemParams struct {
	Day          int
	StartTime    *string
	EndTime      *string
	Title        string
	Description  *string
	LocationName *string
	Lat          *float64
	Lng          *float64
	Category     *string
}

// Repository defines the data access contract for itinerary items.
type Repository interface {
	CreateItem(ctx context.Context, p CreateItemParams) (*Item, error)
	FindByID(ctx context.Context, id uuid.UUID) (*Item, error)
	ListByTripID(ctx context.Context, tripID uuid.UUID) ([]*Item, error)
	UpdateItem(ctx context.Context, id uuid.UUID, p UpdateItemParams) (*Item, error)
	DeleteItem(ctx context.Context, id uuid.UUID) error
	DeleteByTripIDAndSource(ctx context.Context, tripID uuid.UUID, source string) error
	ReorderItems(ctx context.Context, tripID uuid.UUID, items []ReorderItemParam) error
}

type postgresRepository struct {
	db *pgxpool.Pool
}

// NewRepository returns a Postgres-backed itinerary repository.
func NewRepository(db *pgxpool.Pool) Repository {
	return &postgresRepository{db: db}
}

const itemColumns = `id, trip_id, day, start_time, end_time, title, description, location_name, lat, lng, category, source, created_at, updated_at`

func (r *postgresRepository) CreateItem(ctx context.Context, p CreateItemParams) (*Item, error) {
	row := r.db.QueryRow(ctx,
		`INSERT INTO itinerary_items (trip_id, day, start_time, end_time, title, description, location_name, lat, lng, category, source)
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
		 RETURNING `+itemColumns,
		p.TripID, p.Day, p.StartTime, p.EndTime, p.Title, p.Description, p.LocationName, p.Lat, p.Lng, p.Category, p.Source,
	)
	return scanItem(row)
}

func (r *postgresRepository) FindByID(ctx context.Context, id uuid.UUID) (*Item, error) {
	row := r.db.QueryRow(ctx,
		`SELECT `+itemColumns+` FROM itinerary_items WHERE id = $1`, id,
	)
	item, err := scanItem(row)
	if err != nil {
		return nil, fmt.Errorf("find item by id: %w", err)
	}
	return item, nil
}

func (r *postgresRepository) ListByTripID(ctx context.Context, tripID uuid.UUID) ([]*Item, error) {
	rows, err := r.db.Query(ctx,
		`SELECT `+itemColumns+` FROM itinerary_items WHERE trip_id = $1 ORDER BY day, start_time NULLS LAST, created_at`,
		tripID,
	)
	if err != nil {
		return nil, fmt.Errorf("list items: %w", err)
	}
	defer rows.Close()

	var items []*Item
	for rows.Next() {
		item, err := scanItem(rows)
		if err != nil {
			return nil, fmt.Errorf("list items scan: %w", err)
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *postgresRepository) UpdateItem(ctx context.Context, id uuid.UUID, p UpdateItemParams) (*Item, error) {
	row := r.db.QueryRow(ctx,
		`UPDATE itinerary_items
		 SET day = $2, start_time = $3, end_time = $4, title = $5, description = $6,
		     location_name = $7, lat = $8, lng = $9, category = $10, updated_at = now()
		 WHERE id = $1
		 RETURNING `+itemColumns,
		id, p.Day, p.StartTime, p.EndTime, p.Title, p.Description, p.LocationName, p.Lat, p.Lng, p.Category,
	)
	item, err := scanItem(row)
	if err != nil {
		return nil, fmt.Errorf("update item: %w", err)
	}
	return item, nil
}

func (r *postgresRepository) DeleteItem(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.Exec(ctx, `DELETE FROM itinerary_items WHERE id = $1`, id)
	if err != nil {
		return fmt.Errorf("delete item: %w", err)
	}
	return nil
}

func (r *postgresRepository) DeleteByTripIDAndSource(ctx context.Context, tripID uuid.UUID, source string) error {
	_, err := r.db.Exec(ctx,
		`DELETE FROM itinerary_items WHERE trip_id = $1 AND source = $2`,
		tripID, source,
	)
	if err != nil {
		return fmt.Errorf("delete items by source: %w", err)
	}
	return nil
}

func (r *postgresRepository) ReorderItems(ctx context.Context, tripID uuid.UUID, items []ReorderItemParam) error {
	tx, err := r.db.Begin(ctx)
	if err != nil {
		return fmt.Errorf("reorder items begin tx: %w", err)
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	for _, item := range items {
		_, err := tx.Exec(ctx,
			`UPDATE itinerary_items SET sort_order = $2, updated_at = now() WHERE id = $1 AND trip_id = $3`,
			item.ID, item.SortOrder, tripID,
		)
		if err != nil {
			return fmt.Errorf("reorder item %s: %w", item.ID, err)
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("reorder items commit: %w", err)
	}
	return nil
}

type rowScanner interface {
	Scan(dest ...any) error
}

func scanItem(row rowScanner) (*Item, error) {
	item := &Item{}
	if err := row.Scan(
		&item.ID, &item.TripID, &item.Day, &item.StartTime, &item.EndTime,
		&item.Title, &item.Description, &item.LocationName, &item.Lat, &item.Lng,
		&item.Category, &item.Source, &item.CreatedAt, &item.UpdatedAt,
	); err != nil {
		return nil, err
	}
	return item, nil
}
