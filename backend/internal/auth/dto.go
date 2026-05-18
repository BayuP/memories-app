package auth

// SignUpRequest is the payload for POST /api/v1/auth/signup.
type SignUpRequest struct {
	Email       string `json:"email"        validate:"required,email"`
	Password    string `json:"password"     validate:"required,min=8"`
	Handle      string `json:"handle"       validate:"required,min=3,max=30,handle"`
	DisplayName string `json:"display_name" validate:"required,min=1,max=100"`
}

// SignInRequest is the payload for POST /api/v1/auth/signin.
type SignInRequest struct {
	Email    string `json:"email"    validate:"required,email"`
	Password string `json:"password" validate:"required"`
}

// RefreshRequest is the payload for POST /api/v1/auth/refresh.
type RefreshRequest struct {
	RefreshToken string `json:"refresh_token" validate:"required"`
}

// LogoutRequest is the payload for POST /api/v1/auth/logout.
type LogoutRequest struct {
	RefreshToken string `json:"refresh_token" validate:"required"`
}

// TokenPair is returned on successful sign-up, sign-in, or token refresh.
type TokenPair struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
}
