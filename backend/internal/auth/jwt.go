package auth

import (
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

// JWTManager issues and verifies JWTs.
type JWTManager struct {
	secret        []byte
	accessExpiry  time.Duration
	refreshExpiry time.Duration
}

func NewJWTManager(secret string, accessExpiry, refreshExpiry time.Duration) *JWTManager {
	return &JWTManager{
		secret:        []byte(secret),
		accessExpiry:  accessExpiry,
		refreshExpiry: refreshExpiry,
	}
}

type claims struct {
	jwt.RegisteredClaims
	TokenType string `json:"type"`
}

func (m *JWTManager) IssueAccessToken(userID uuid.UUID) (string, error) {
	return m.issue(userID, "access", m.accessExpiry)
}

func (m *JWTManager) IssueRefreshToken(userID uuid.UUID) (string, error) {
	return m.issue(userID, "refresh", m.refreshExpiry)
}

func (m *JWTManager) issue(userID uuid.UUID, tokenType string, expiry time.Duration) (string, error) {
	now := time.Now()
	c := claims{
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID.String(),
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(expiry)),
			ID:        uuid.New().String(),
		},
		TokenType: tokenType,
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, c)
	signed, err := token.SignedString(m.secret)
	if err != nil {
		return "", fmt.Errorf("sign token: %w", err)
	}
	return signed, nil
}

// VerifyAccessToken validates an access token and returns the subject (user ID).
// Implements httpx.TokenVerifier.
func (m *JWTManager) VerifyAccessToken(tokenStr string) (string, error) {
	return m.verify(tokenStr, "access")
}

// VerifyRefreshToken validates a refresh token and returns the subject (user ID).
func (m *JWTManager) VerifyRefreshToken(tokenStr string) (string, error) {
	return m.verify(tokenStr, "refresh")
}

func (m *JWTManager) verify(tokenStr, expectedType string) (string, error) {
	token, err := jwt.ParseWithClaims(tokenStr, &claims{}, func(t *jwt.Token) (any, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
		}
		return m.secret, nil
	})
	if err != nil {
		return "", fmt.Errorf("parse token: %w", err)
	}

	c, ok := token.Claims.(*claims)
	if !ok || !token.Valid {
		return "", fmt.Errorf("invalid token claims")
	}

	if c.TokenType != expectedType {
		return "", fmt.Errorf("wrong token type: got %s want %s", c.TokenType, expectedType)
	}

	return c.Subject, nil
}

func (m *JWTManager) RefreshExpiry() time.Duration {
	return m.refreshExpiry
}
