package users

import "regexp"

var handleRegex = regexp.MustCompile(`^[a-z0-9_]{3,30}$`)

// ValidHandle reports whether h is a valid @handle.
func ValidHandle(h string) bool {
	return handleRegex.MatchString(h)
}
