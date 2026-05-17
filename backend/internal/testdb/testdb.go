package testdb

import (
	"context"
	"os"
	"testing"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/BayuP/memories-app/backend/internal/db"
	"github.com/BayuP/memories-app/backend/internal/users"
)

// Connect returns a pool connected to TEST_DATABASE_URL, or skips the test if unset.
// A cleanup is registered to truncate all tables and close the pool after the test.
func Connect(t *testing.T) *pgxpool.Pool {
	t.Helper()

	url := os.Getenv("TEST_DATABASE_URL")
	if url == "" {
		t.Skip("TEST_DATABASE_URL not set")
	}

	pool, err := db.Connect(context.Background(), url)
	if err != nil {
		t.Fatalf("testdb.Connect: %v", err)
	}

	t.Cleanup(func() {
		Truncate(t, pool)
		pool.Close()
	})

	return pool
}

// Truncate removes all rows from every table, respecting FK constraints by
// deleting children before parents.
func Truncate(t *testing.T, pool *pgxpool.Pool) {
	t.Helper()

	_, err := pool.Exec(context.Background(), `
		TRUNCATE TABLE
			media,
			checkin_recommendations,
			checkin_logistics,
			checkin_memory,
			checkins,
			itinerary_items,
			trip_members,
			trips,
			refresh_tokens,
			users
		RESTART IDENTITY CASCADE
	`)
	if err != nil {
		t.Fatalf("testdb.Truncate: %v", err)
	}
}

// MustCreateUser inserts a test user with email "<handle>@test.com" and returns
// the created *users.User. The test is fatally failed on any error.
func MustCreateUser(t *testing.T, pool *pgxpool.Pool, handle string) *users.User {
	t.Helper()

	repo := users.NewRepository(pool)
	u, err := repo.CreateUser(context.Background(), users.CreateUserParams{
		Email:        handle + "@test.com",
		PasswordHash: "$2a$10$placeholder_hash_for_tests_only",
		Handle:       handle,
		DisplayName:  handle,
	})
	if err != nil {
		t.Fatalf("testdb.MustCreateUser(%q): %v", handle, err)
	}
	return u
}
