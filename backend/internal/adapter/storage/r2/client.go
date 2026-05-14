package r2

import (
	"context"
	"fmt"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

// Config holds R2 connection parameters.
type Config struct {
	Endpoint  string
	Bucket    string
	AccessKey string
	SecretKey string
	Region    string
}

// Client wraps the AWS S3 client for Cloudflare R2 operations.
type Client struct {
	s3     *s3.Client
	presig *s3.PresignClient
	bucket string
}

// NewClient returns a Cloudflare R2 client using S3-compatible API.
func NewClient(cfg Config) *Client {
	region := cfg.Region
	if region == "" {
		region = "auto"
	}

	awsCfg := aws.Config{
		Region:      region,
		Credentials: credentials.NewStaticCredentialsProvider(cfg.AccessKey, cfg.SecretKey, ""),
	}

	s3Client := s3.NewFromConfig(awsCfg, func(o *s3.Options) {
		o.BaseEndpoint = aws.String(cfg.Endpoint)
		o.UsePathStyle = true
	})

	return &Client{
		s3:     s3Client,
		presig: s3.NewPresignClient(s3Client),
		bucket: cfg.Bucket,
	}
}

// PresignPutURL returns a presigned PUT URL for uploading a file to R2.
func (c *Client) PresignPutURL(ctx context.Context, key, mime string, expires time.Duration) (string, error) {
	req, err := c.presig.PresignPutObject(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(c.bucket),
		Key:         aws.String(key),
		ContentType: aws.String(mime),
	}, s3.WithPresignExpires(expires))
	if err != nil {
		return "", fmt.Errorf("presign put url: %w", err)
	}
	return req.URL, nil
}

// DeleteObject deletes a file from R2 by its key.
func (c *Client) DeleteObject(ctx context.Context, key string) error {
	_, err := c.s3.DeleteObject(ctx, &s3.DeleteObjectInput{
		Bucket: aws.String(c.bucket),
		Key:    aws.String(key),
	})
	if err != nil {
		return fmt.Errorf("delete object: %w", err)
	}
	return nil
}
