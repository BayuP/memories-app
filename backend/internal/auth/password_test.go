package auth

import (
	"strings"
	"testing"
)

func TestHashAndCheckPassword(t *testing.T) {
	tests := []struct {
		name      string
		password  string
		check     string
		wantMatch bool
	}{
		{name: "correct password", password: "correcthorse", check: "correcthorse", wantMatch: true},
		{name: "wrong password", password: "correcthorse", check: "wrongpassword", wantMatch: false},
		{name: "empty check", password: "correcthorse", check: "", wantMatch: false},
		{name: "min length password", password: "12345678", check: "12345678", wantMatch: true},
		{name: "unicode password", password: "p4sswörd!", check: "p4sswörd!", wantMatch: true},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			hash, err := HashPassword(tc.password)
			if err != nil {
				t.Fatalf("HashPassword(%q) error: %v", tc.password, err)
			}
			if hash == tc.password {
				t.Fatal("hash must not equal plaintext")
			}
			if !strings.HasPrefix(hash, "$2") {
				t.Fatalf("expected bcrypt hash, got: %s", hash)
			}

			err = CheckPassword(tc.check, hash)
			if tc.wantMatch && err != nil {
				t.Errorf("CheckPassword expected match, got error: %v", err)
			}
			if !tc.wantMatch && err == nil {
				t.Error("CheckPassword expected mismatch, got nil error")
			}
		})
	}
}
