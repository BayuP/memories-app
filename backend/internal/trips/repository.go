package trips

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

// CreateTripParams carries required fields for trip creation.
type CreateTripParams struct {
	OwnerID     uuid.UUID
	Title       string
	Destination string
	StartDate   *time.Time
	EndDate     *time.Time
	Vibes       []string
}

// UpdateTripParams carries the full merged state for a trip update.
type UpdateTripParams struct {
	Title       string
	Destination string
	StartDate   *time.Time
	EndDate     *time.Time
	Vibes       []string
	Status      string
}

// Repository defines the data access contract for trips and members.
type Repository interface {
	CreateTrip(ctx context.Context, p CreateTripParams) (*Trip, error)
	FindByID(ctx context.Context, id uuid.UUID) (*Trip, error)
	ListByUserID(ctx context.Context, userID uuid.UUID) ([]*Trip, error)
	UpdateTrip(ctx context.Context, id uuid.UUID, p UpdateTripParams) (*Trip, error)
	DeleteTrip(ctx context.Context, id uuid.UUID) error

	AddMember(ctx context.Context, tripID, userID uuid.UUID, role string) (*Member, error)
	FindMember(ctx context.Context, tripID, userID uuid.UUID) (*Member, error)
	ListMembers(ctx context.Context, tripID uuid.UUID) ([]*Member, error)
	RemoveMember(ctx context.Context, tripID, userID uuid.UUID) error
	IsMember(ctx context.Context, tripID, userID uuid.UUID) (bool, error)
}

type postgresRepository struct {
	db *pgxpool.Pool
}

// NewRepository returns a Postgres-backed trips repository.
func NewRepository(db *pgxpool.Pool) Repository {
	return &postgresRepository{db: db}
}

const tripColumns = `id, owner_id, title, destination, start_date, end_date, vibes, status, created_at, updated_at`

func (r *postgresRepository) CreateTrip(ctx context.Context, p CreateTripParams) (*Trip, error) {
	row := r.db.QueryRow(ctx,
		`INSERT INTO trips (owner_id, title, destination, start_date, end_date, vibes)
		 VALUES ($1, $2, $3, $4, $5, $6)
		 RETURNING `+tripColumns,
		p.OwnerID, p.Title, p.Destination, p.StartDate, p.EndDate, p.Vibes,
	)
	return scanTrip(row)
}

func (r *postgresRepository) FindByID(ctx context.Context, id uuid.UUID) (*Trip, error) {
	row := r.db.QueryRow(ctx,
		`SELECT `+tripColumns+` FROM trips WHERE id = $1`, id,
	)
	t, err := scanTrip(row)
	if err != nil {
		return nil, fmt.Errorf("find trip by id: %w", err)
	}
	return t, nil
}

func (r *postgresRepository) ListByUserID(ctx context.Context, userID uuid.UUID) ([]*Trip, error) {
	rows, err := r.db.Query(ctx,
		`SELECT DISTINCT `+tripCols("t")+`
		 FROM trips t
		 JOIN trip_members tm ON tm.trip_id = t.id
		 WHERE tm.user_id = $1
		 ORDER BY t.created_at DESC`,
		userID,
	)
	if err != nil {
		return nil, fmt.Errorf("list trips: %w", err)
	}
	defer rows.Close()

	var trips []*Trip
	for rows.Next() {
		t, err := scanTrip(rows)
		if err != nil {
			return nil, fmt.Errorf("list trips scan: %w", err)
		}
		trips = append(trips, t)
	}
	return trips, rows.Err()
}

func (r *postgresRepository) UpdateTrip(ctx context.Context, id uuid.UUID, p UpdateTripParams) (*Trip, error) {
	row := r.db.QueryRow(ctx,
		`UPDATE trips
		 SET title = $2, destination = $3, start_date = $4, end_date = $5,
		     vibes = $6, status = $7, updated_at = now()
		 WHERE id = $1
		 RETURNING `+tripColumns,
		id, p.Title, p.Destination, p.StartDate, p.EndDate, p.Vibes, p.Status,
	)
	t, err := scanTrip(row)
	if err != nil {
		return nil, fmt.Errorf("update trip: %w", err)
	}
	return t, nil
}

func (r *postgresRepository) DeleteTrip(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.Exec(ctx, `DELETE FROM trips WHERE id = $1`, id)
	if err != nil {
		return fmt.Errorf("delete trip: %w", err)
	}
	return nil
}

func (r *postgresRepository) AddMember(ctx context.Context, tripID, userID uuid.UUID, role string) (*Member, error) {
	row := r.db.QueryRow(ctx,
		`WITH ins AS (
			INSERT INTO trip_members (trip_id, user_id, role)
			VALUES ($1, $2, $3)
			RETURNING id, trip_id, user_id, role, created_at, updated_at
		 )
		 SELECT ins.id, ins.trip_id, ins.user_id, ins.role, ins.created_at, ins.updated_at, u.handle, u.display_name
		 FROM ins JOIN users u ON u.id = ins.user_id`,
		tripID, userID, role,
	)
	return scanMember(row)
}

func (r *postgresRepository) FindMember(ctx context.Context, tripID, userID uuid.UUID) (*Member, error) {
	row := r.db.QueryRow(ctx,
		`SELECT `+memberCols+`
		 FROM trip_members tm JOIN users u ON u.id = tm.user_id
		 WHERE tm.trip_id = $1 AND tm.user_id = $2`,
		tripID, userID,
	)
	m, err := scanMember(row)
	if err != nil {
		return nil, fmt.Errorf("find member: %w", err)
	}
	return m, nil
}

func (r *postgresRepository) ListMembers(ctx context.Context, tripID uuid.UUID) ([]*Member, error) {
	rows, err := r.db.Query(ctx,
		`SELECT `+memberCols+`
		 FROM trip_members tm JOIN users u ON u.id = tm.user_id
		 WHERE tm.trip_id = $1 ORDER BY tm.created_at`,
		tripID,
	)
	if err != nil {
		return nil, fmt.Errorf("list members: %w", err)
	}
	defer rows.Close()

	var members []*Member
	for rows.Next() {
		m, err := scanMember(rows)
		if err != nil {
			return nil, fmt.Errorf("list members scan: %w", err)
		}
		members = append(members, m)
	}
	return members, rows.Err()
}

func (r *postgresRepository) RemoveMember(ctx context.Context, tripID, userID uuid.UUID) error {
	_, err := r.db.Exec(ctx,
		`DELETE FROM trip_members WHERE trip_id = $1 AND user_id = $2`,
		tripID, userID,
	)
	if err != nil {
		return fmt.Errorf("remove member: %w", err)
	}
	return nil
}

func (r *postgresRepository) IsMember(ctx context.Context, tripID, userID uuid.UUID) (bool, error) {
	var exists bool
	err := r.db.QueryRow(ctx,
		`SELECT EXISTS(SELECT 1 FROM trip_members WHERE trip_id = $1 AND user_id = $2)`,
		tripID, userID,
	).Scan(&exists)
	if err != nil {
		return false, fmt.Errorf("is member: %w", err)
	}
	return exists, nil
}

type rowScanner interface {
	Scan(dest ...any) error
}

func scanTrip(row rowScanner) (*Trip, error) {
	t := &Trip{}
	var startDate, endDate pgtype.Date
	if err := row.Scan(
		&t.ID, &t.OwnerID, &t.Title, &t.Destination,
		&startDate, &endDate, &t.Vibes, &t.Status,
		&t.CreatedAt, &t.UpdatedAt,
	); err != nil {
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
	return t, nil
}

func scanMember(row rowScanner) (*Member, error) {
	m := &Member{}
	if err := row.Scan(
		&m.ID, &m.TripID, &m.UserID, &m.Role, &m.CreatedAt, &m.UpdatedAt,
		&m.Handle, &m.DisplayName,
	); err != nil {
		return nil, err
	}
	return m, nil
}

// memberCols are the trip_members + joined user columns, in scanMember order.
const memberCols = `tm.id, tm.trip_id, tm.user_id, tm.role, tm.created_at, tm.updated_at, u.handle, u.display_name`

// tripCols prefixes all trip column names with the given alias.
func tripCols(alias string) string {
	return alias + ".id, " + alias + ".owner_id, " + alias + ".title, " + alias + ".destination, " +
		alias + ".start_date, " + alias + ".end_date, " + alias + ".vibes, " + alias + ".status, " +
		alias + ".created_at, " + alias + ".updated_at"
}
