package trips_test

import (
	"context"
	"errors"
	"testing"

	"github.com/jackc/pgx/v5"

	"github.com/BayuP/memories-app/backend/internal/testdb"
	"github.com/BayuP/memories-app/backend/internal/trips"
)

func TestTripRepo_CreateAndFind(t *testing.T) {
	pool := testdb.Connect(t)
	ctx := context.Background()

	user := testdb.MustCreateUser(t, pool, "tripcreator")
	repo := trips.NewRepository(pool)

	trip, err := repo.CreateTrip(ctx, trips.CreateTripParams{
		OwnerID:     user.ID,
		Title:       "Bali Escape",
		Destination: "Bali, Indonesia",
		Vibes:       []string{"beach", "relax"},
	})
	if err != nil {
		t.Fatalf("CreateTrip: %v", err)
	}
	if trip.ID.String() == "" {
		t.Error("expected non-empty trip ID")
	}

	found, err := repo.FindByID(ctx, trip.ID)
	if err != nil {
		t.Fatalf("FindByID: %v", err)
	}
	if found.Title != "Bali Escape" {
		t.Errorf("title: got %q, want %q", found.Title, "Bali Escape")
	}
	if found.Destination != "Bali, Indonesia" {
		t.Errorf("destination: got %q, want %q", found.Destination, "Bali, Indonesia")
	}
	if found.OwnerID != user.ID {
		t.Errorf("owner_id: got %v, want %v", found.OwnerID, user.ID)
	}
	if len(found.Vibes) != 2 {
		t.Errorf("vibes len: got %d, want 2", len(found.Vibes))
	}
}

func TestTripRepo_ListByUserID(t *testing.T) {
	pool := testdb.Connect(t)
	ctx := context.Background()

	user := testdb.MustCreateUser(t, pool, "triplister")
	repo := trips.NewRepository(pool)

	for _, title := range []string{"Trip One", "Trip Two"} {
		trip, err := repo.CreateTrip(ctx, trips.CreateTripParams{
			OwnerID:     user.ID,
			Title:       title,
			Destination: "Somewhere",
		})
		if err != nil {
			t.Fatalf("CreateTrip(%q): %v", title, err)
		}
		if _, err := repo.AddMember(ctx, trip.ID, user.ID, "owner"); err != nil {
			t.Fatalf("AddMember: %v", err)
		}
	}

	list, err := repo.ListByUserID(ctx, user.ID)
	if err != nil {
		t.Fatalf("ListByUserID: %v", err)
	}
	if len(list) != 2 {
		t.Errorf("list len: got %d, want 2", len(list))
	}
}

func TestTripRepo_Update(t *testing.T) {
	pool := testdb.Connect(t)
	ctx := context.Background()

	user := testdb.MustCreateUser(t, pool, "tripupdater")
	repo := trips.NewRepository(pool)

	trip, err := repo.CreateTrip(ctx, trips.CreateTripParams{
		OwnerID:     user.ID,
		Title:       "Old Title",
		Destination: "Old Dest",
		Vibes:       []string{"old"},
	})
	if err != nil {
		t.Fatalf("CreateTrip: %v", err)
	}

	updated, err := repo.UpdateTrip(ctx, trip.ID, trips.UpdateTripParams{
		Title:       "New Title",
		Destination: "New Dest",
		Vibes:       []string{"new", "fresh"},
		Status:      "planning",
	})
	if err != nil {
		t.Fatalf("UpdateTrip: %v", err)
	}
	if updated.Title != "New Title" {
		t.Errorf("title: got %q, want %q", updated.Title, "New Title")
	}
	if updated.Destination != "New Dest" {
		t.Errorf("destination: got %q, want %q", updated.Destination, "New Dest")
	}
	if len(updated.Vibes) != 2 {
		t.Errorf("vibes len: got %d, want 2", len(updated.Vibes))
	}
	if updated.Status != "planning" {
		t.Errorf("status: got %q, want %q", updated.Status, "planning")
	}
}

func TestTripRepo_Delete(t *testing.T) {
	pool := testdb.Connect(t)
	ctx := context.Background()

	user := testdb.MustCreateUser(t, pool, "tripdeleter")
	repo := trips.NewRepository(pool)

	trip, err := repo.CreateTrip(ctx, trips.CreateTripParams{
		OwnerID:     user.ID,
		Title:       "Doomed Trip",
		Destination: "Nowhere",
	})
	if err != nil {
		t.Fatalf("CreateTrip: %v", err)
	}

	if err := repo.DeleteTrip(ctx, trip.ID); err != nil {
		t.Fatalf("DeleteTrip: %v", err)
	}

	_, err = repo.FindByID(ctx, trip.ID)
	if !errors.Is(err, pgx.ErrNoRows) {
		t.Errorf("after delete, FindByID: want pgx.ErrNoRows wrapped, got %v", err)
	}
}

func TestTripRepo_Members(t *testing.T) {
	pool := testdb.Connect(t)
	ctx := context.Background()

	owner := testdb.MustCreateUser(t, pool, "memberowner")
	editor := testdb.MustCreateUser(t, pool, "membereditor")
	repo := trips.NewRepository(pool)

	trip, err := repo.CreateTrip(ctx, trips.CreateTripParams{
		OwnerID:     owner.ID,
		Title:       "Member Test Trip",
		Destination: "Somewhere",
	})
	if err != nil {
		t.Fatalf("CreateTrip: %v", err)
	}

	if _, err := repo.AddMember(ctx, trip.ID, owner.ID, "owner"); err != nil {
		t.Fatalf("AddMember owner: %v", err)
	}
	if _, err := repo.AddMember(ctx, trip.ID, editor.ID, "editor"); err != nil {
		t.Fatalf("AddMember editor: %v", err)
	}

	t.Run("IsMember_true_for_both", func(t *testing.T) {
		ok, err := repo.IsMember(ctx, trip.ID, owner.ID)
		if err != nil {
			t.Fatalf("IsMember owner: %v", err)
		}
		if !ok {
			t.Error("owner should be a member")
		}

		ok, err = repo.IsMember(ctx, trip.ID, editor.ID)
		if err != nil {
			t.Fatalf("IsMember editor: %v", err)
		}
		if !ok {
			t.Error("editor should be a member")
		}
	})

	t.Run("ListMembers_returns_2", func(t *testing.T) {
		members, err := repo.ListMembers(ctx, trip.ID)
		if err != nil {
			t.Fatalf("ListMembers: %v", err)
		}
		if len(members) != 2 {
			t.Errorf("members len: got %d, want 2", len(members))
		}
	})

	t.Run("RemoveMember_editor", func(t *testing.T) {
		if err := repo.RemoveMember(ctx, trip.ID, editor.ID); err != nil {
			t.Fatalf("RemoveMember: %v", err)
		}

		ok, err := repo.IsMember(ctx, trip.ID, editor.ID)
		if err != nil {
			t.Fatalf("IsMember after remove: %v", err)
		}
		if ok {
			t.Error("editor should no longer be a member")
		}
	})
}
