package users

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

// CreateUserParams carries the fields required to create a new user.
type CreateUserParams struct {
	Email        string
	PasswordHash string
	Handle       string
	DisplayName  string
}

// UpdateUserParams carries optional fields for user profile updates.
type UpdateUserParams struct {
	DisplayName *string
	AvatarURL   *string
}

// Repository defines the data access contract for user operations.
type Repository interface {
	CreateUser(ctx context.Context, params CreateUserParams) (*User, error)
	FindByID(ctx context.Context, id uuid.UUID) (*User, error)
	FindByEmail(ctx context.Context, email string) (*User, error)
	FindByHandle(ctx context.Context, handle string) (*User, error)
	UpdateUser(ctx context.Context, id uuid.UUID, params UpdateUserParams) (*User, error)
	SearchByHandle(ctx context.Context, prefix string, limit int) ([]*User, error)
}

type postgresRepository struct {
	db *pgxpool.Pool
}

// NewRepository returns a Postgres-backed users repository.
func NewRepository(db *pgxpool.Pool) Repository {
	return &postgresRepository{db: db}
}

const userColumns = `id, email, password_hash, handle, display_name, avatar_url, created_at, updated_at`

func (r *postgresRepository) CreateUser(ctx context.Context, p CreateUserParams) (*User, error) {
	row := r.db.QueryRow(ctx,
		`INSERT INTO users (email, password_hash, handle, display_name)
		 VALUES ($1, $2, $3, $4)
		 RETURNING `+userColumns,
		p.Email, p.PasswordHash, p.Handle, p.DisplayName,
	)
	return scanUser(row)
}

func (r *postgresRepository) FindByID(ctx context.Context, id uuid.UUID) (*User, error) {
	row := r.db.QueryRow(ctx,
		`SELECT `+userColumns+` FROM users WHERE id = $1`, id,
	)
	u, err := scanUser(row)
	if err != nil {
		return nil, fmt.Errorf("find user by id: %w", err)
	}
	return u, nil
}

func (r *postgresRepository) FindByEmail(ctx context.Context, email string) (*User, error) {
	row := r.db.QueryRow(ctx,
		`SELECT `+userColumns+` FROM users WHERE email = $1`, email,
	)
	u, err := scanUser(row)
	if err != nil {
		return nil, fmt.Errorf("find user by email: %w", err)
	}
	return u, nil
}

func (r *postgresRepository) FindByHandle(ctx context.Context, handle string) (*User, error) {
	row := r.db.QueryRow(ctx,
		`SELECT `+userColumns+` FROM users WHERE handle = $1`, handle,
	)
	u, err := scanUser(row)
	if err != nil {
		return nil, fmt.Errorf("find user by handle: %w", err)
	}
	return u, nil
}

func (r *postgresRepository) UpdateUser(ctx context.Context, id uuid.UUID, p UpdateUserParams) (*User, error) {
	row := r.db.QueryRow(ctx,
		`UPDATE users
		 SET display_name = COALESCE($2, display_name),
		     avatar_url   = COALESCE($3, avatar_url),
		     updated_at   = now()
		 WHERE id = $1
		 RETURNING `+userColumns,
		id, p.DisplayName, p.AvatarURL,
	)
	u, err := scanUser(row)
	if err != nil {
		return nil, fmt.Errorf("update user: %w", err)
	}
	return u, nil
}

func (r *postgresRepository) SearchByHandle(ctx context.Context, prefix string, limit int) ([]*User, error) {
	rows, err := r.db.Query(ctx,
		`SELECT `+userColumns+` FROM users WHERE handle LIKE $1 ORDER BY handle LIMIT $2`,
		prefix+"%", limit,
	)
	if err != nil {
		return nil, fmt.Errorf("search by handle: %w", err)
	}
	defer rows.Close()

	var users []*User
	for rows.Next() {
		u, err := scanUser(rows)
		if err != nil {
			return nil, fmt.Errorf("search by handle scan: %w", err)
		}
		users = append(users, u)
	}
	return users, rows.Err()
}

type scanner interface {
	Scan(dest ...any) error
}

func scanUser(row scanner) (*User, error) {
	u := &User{}
	if err := row.Scan(
		&u.ID, &u.Email, &u.PasswordHash, &u.Handle,
		&u.DisplayName, &u.AvatarURL, &u.CreatedAt, &u.UpdatedAt,
	); err != nil {
		return nil, err
	}
	return u, nil
}
