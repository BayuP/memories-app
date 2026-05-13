package config

import (
	"time"

	"github.com/caarlos0/env/v11"
)

// Config holds all runtime configuration loaded from environment variables.
type Config struct {
	Env  string `env:"ENV" envDefault:"development"`
	Port int    `env:"PORT" envDefault:"8080"`

	DatabaseURL string `env:"DATABASE_URL,required"`

	JWTSecret        string        `env:"JWT_SECRET,required"`
	JWTAccessExpiry  time.Duration `env:"JWT_ACCESS_EXPIRY" envDefault:"15m"`
	JWTRefreshExpiry time.Duration `env:"JWT_REFRESH_EXPIRY" envDefault:"720h"`

	S3Endpoint  string `env:"S3_ENDPOINT"`
	S3Bucket    string `env:"S3_BUCKET"`
	S3AccessKey string `env:"S3_ACCESS_KEY"`
	S3SecretKey string `env:"S3_SECRET_KEY"`
	S3Region    string `env:"S3_REGION" envDefault:"auto"`

	GoogleClientID     string `env:"GOOGLE_CLIENT_ID"`
	GoogleClientSecret string `env:"GOOGLE_CLIENT_SECRET"`

	AnthropicAPIKey string `env:"ANTHROPIC_API_KEY"`
}

func (c *Config) IsProd() bool {
	return c.Env == "production"
}

// Load parses Config from environment variables.
func Load() (*Config, error) {
	cfg := &Config{}
	if err := env.Parse(cfg); err != nil {
		return nil, err
	}
	return cfg, nil
}
