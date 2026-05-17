package itinerary_test

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/BayuP/memories-app/backend/internal/itinerary"
	"github.com/BayuP/memories-app/backend/internal/testdb"
	"github.com/BayuP/memories-app/backend/internal/trips"
)

// mustCreateTrip creates a trip owned by userID for itinerary tests.
func mustCreateTrip(t *testing.T, repo trips.Repository, userID uuid.UUID) *trips.Trip {
	t.Helper()
	trip, err := repo.CreateTrip(context.Background(), trips.CreateTripParams{
		OwnerID:     userID,
		Title:       "Test Trip",
		Destination: "Test Destination",
	})
	if err != nil {
		t.Fatalf("mustCreateTrip: %v", err)
	}
	return trip
}

func strPtr(s string) *string { return &s }

func TestItemRepo_CreateAndFind(t *testing.T) {
	pool := testdb.Connect(t)
	ctx := context.Background()

	user := testdb.MustCreateUser(t, pool, "itncreatuser")
	tripRepo := trips.NewRepository(pool)
	trip := mustCreateTrip(t, tripRepo, user.ID)

	repo := itinerary.NewRepository(pool)
	item, err := repo.CreateItem(ctx, itinerary.CreateItemParams{
		TripID:      trip.ID,
		Day:         1,
		Title:       "Visit Temple",
		Description: strPtr("Morning visit"),
		Source:      "user",
	})
	if err != nil {
		t.Fatalf("CreateItem: %v", err)
	}
	if item.ID == uuid.Nil {
		t.Error("expected non-nil item ID")
	}

	found, err := repo.FindByID(ctx, item.ID)
	if err != nil {
		t.Fatalf("FindByID: %v", err)
	}
	if found.Title != "Visit Temple" {
		t.Errorf("title: got %q, want %q", found.Title, "Visit Temple")
	}
	if found.Day != 1 {
		t.Errorf("day: got %d, want 1", found.Day)
	}
	if found.TripID != trip.ID {
		t.Errorf("trip_id: got %v, want %v", found.TripID, trip.ID)
	}
	if found.Description == nil || *found.Description != "Morning visit" {
		t.Errorf("description: got %v, want %q", found.Description, "Morning visit")
	}
	if found.Source != "user" {
		t.Errorf("source: got %q, want %q", found.Source, "user")
	}
}

func TestItemRepo_ListByTripID(t *testing.T) {
	pool := testdb.Connect(t)
	ctx := context.Background()

	user := testdb.MustCreateUser(t, pool, "itnlistuser")
	tripRepo := trips.NewRepository(pool)
	trip := mustCreateTrip(t, tripRepo, user.ID)

	repo := itinerary.NewRepository(pool)

	itemDefs := []struct {
		day   int
		start *string
		title string
	}{
		{1, strPtr("09:00"), "Breakfast"},
		{1, strPtr("14:00"), "Lunch"},
		{2, strPtr("10:00"), "Sightseeing"},
	}
	for _, d := range itemDefs {
		if _, err := repo.CreateItem(ctx, itinerary.CreateItemParams{
			TripID:    trip.ID,
			Day:       d.day,
			StartTime: d.start,
			Title:     d.title,
			Source:    "user",
		}); err != nil {
			t.Fatalf("CreateItem(%q): %v", d.title, err)
		}
	}

	list, err := repo.ListByTripID(ctx, trip.ID)
	if err != nil {
		t.Fatalf("ListByTripID: %v", err)
	}
	if len(list) != 3 {
		t.Fatalf("list len: got %d, want 3", len(list))
	}

	// Items must be ordered by (day, start_time).
	if list[0].Title != "Breakfast" {
		t.Errorf("[0] title: got %q, want %q", list[0].Title, "Breakfast")
	}
	if list[1].Title != "Lunch" {
		t.Errorf("[1] title: got %q, want %q", list[1].Title, "Lunch")
	}
	if list[2].Title != "Sightseeing" {
		t.Errorf("[2] title: got %q, want %q", list[2].Title, "Sightseeing")
	}
}

func TestItemRepo_Update(t *testing.T) {
	pool := testdb.Connect(t)
	ctx := context.Background()

	user := testdb.MustCreateUser(t, pool, "itnupdtuser")
	tripRepo := trips.NewRepository(pool)
	trip := mustCreateTrip(t, tripRepo, user.ID)

	repo := itinerary.NewRepository(pool)
	item, err := repo.CreateItem(ctx, itinerary.CreateItemParams{
		TripID: trip.ID,
		Day:    1,
		Title:  "Original Title",
		Source: "user",
	})
	if err != nil {
		t.Fatalf("CreateItem: %v", err)
	}

	updated, err := repo.UpdateItem(ctx, item.ID, itinerary.UpdateItemParams{
		Day:         2,
		Title:       "Updated Title",
		Description: strPtr("New description"),
	})
	if err != nil {
		t.Fatalf("UpdateItem: %v", err)
	}
	if updated.Title != "Updated Title" {
		t.Errorf("title: got %q, want %q", updated.Title, "Updated Title")
	}
	if updated.Day != 2 {
		t.Errorf("day: got %d, want 2", updated.Day)
	}
	if updated.Description == nil || *updated.Description != "New description" {
		t.Errorf("description: got %v, want %q", updated.Description, "New description")
	}
}

func TestItemRepo_Delete(t *testing.T) {
	pool := testdb.Connect(t)
	ctx := context.Background()

	user := testdb.MustCreateUser(t, pool, "itndeltuser")
	tripRepo := trips.NewRepository(pool)
	trip := mustCreateTrip(t, tripRepo, user.ID)

	repo := itinerary.NewRepository(pool)
	item, err := repo.CreateItem(ctx, itinerary.CreateItemParams{
		TripID: trip.ID,
		Day:    1,
		Title:  "To Be Deleted",
		Source: "user",
	})
	if err != nil {
		t.Fatalf("CreateItem: %v", err)
	}

	if err := repo.DeleteItem(ctx, item.ID); err != nil {
		t.Fatalf("DeleteItem: %v", err)
	}

	_, err = repo.FindByID(ctx, item.ID)
	if !errors.Is(err, pgx.ErrNoRows) {
		t.Errorf("after delete, FindByID: want pgx.ErrNoRows wrapped, got %v", err)
	}
}

func TestItemRepo_DeleteBySource(t *testing.T) {
	pool := testdb.Connect(t)
	ctx := context.Background()

	user := testdb.MustCreateUser(t, pool, "itnsrcuser")
	tripRepo := trips.NewRepository(pool)
	trip := mustCreateTrip(t, tripRepo, user.ID)

	repo := itinerary.NewRepository(pool)

	ai1, err := repo.CreateItem(ctx, itinerary.CreateItemParams{
		TripID: trip.ID,
		Day:    1,
		Title:  "AI Item 1",
		Source: "ai",
	})
	if err != nil {
		t.Fatalf("CreateItem AI 1: %v", err)
	}
	ai2, err := repo.CreateItem(ctx, itinerary.CreateItemParams{
		TripID: trip.ID,
		Day:    1,
		Title:  "AI Item 2",
		Source: "ai",
	})
	if err != nil {
		t.Fatalf("CreateItem AI 2: %v", err)
	}
	userItem, err := repo.CreateItem(ctx, itinerary.CreateItemParams{
		TripID: trip.ID,
		Day:    1,
		Title:  "User Item",
		Source: "user",
	})
	if err != nil {
		t.Fatalf("CreateItem user: %v", err)
	}

	if err := repo.DeleteByTripIDAndSource(ctx, trip.ID, "ai"); err != nil {
		t.Fatalf("DeleteByTripIDAndSource: %v", err)
	}

	_, err = repo.FindByID(ctx, ai1.ID)
	if !errors.Is(err, pgx.ErrNoRows) {
		t.Errorf("AI item 1 should be deleted, got %v", err)
	}
	_, err = repo.FindByID(ctx, ai2.ID)
	if !errors.Is(err, pgx.ErrNoRows) {
		t.Errorf("AI item 2 should be deleted, got %v", err)
	}

	kept, err := repo.FindByID(ctx, userItem.ID)
	if err != nil {
		t.Fatalf("user item should still exist: %v", err)
	}
	if kept.Source != "user" {
		t.Errorf("kept item source: got %q, want %q", kept.Source, "user")
	}
}
