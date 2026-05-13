package auth

import "regexp"

// handlePattern enforces @handle format: lowercase alphanumeric + underscore, 3-30 chars.
var handlePattern = regexp.MustCompile(`^[a-z0-9_]{3,30}$`)
