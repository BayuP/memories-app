package users

import "testing"

func TestValidHandle(t *testing.T) {
	tests := []struct {
		handle string
		valid  bool
	}{
		{"bayu", true},
		{"bayu_p", true},
		{"user123", true},
		{"abc", true},
		{"a1_2b3_4c5_6d7_8e9_10f11g12h13", true},  // 30 chars exactly
		{"ab", false},                               // too short
		{"a", false},                                // too short
		{"", false},                                 // empty
		{"Uppercase", false},                        // uppercase not allowed
		{"has-hyphen", false},                       // hyphen not allowed
		{"has space", false},                        // space not allowed
		{"has.dot", false},                          // dot not allowed
		{"toolonghandle12345toolong12345x", false},  // 31 chars
		{"_underscore_start", true},                 // underscore at start ok
	}

	for _, tc := range tests {
		t.Run(tc.handle, func(t *testing.T) {
			if got := ValidHandle(tc.handle); got != tc.valid {
				t.Errorf("ValidHandle(%q) = %v, want %v", tc.handle, got, tc.valid)
			}
		})
	}
}
