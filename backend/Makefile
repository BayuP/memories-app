.PHONY: build run test fmt lint migrate-up migrate-down docker-build docker-up docker-down docker-logs

DATABASE_URL ?= postgres://memories:memories@localhost:5432/memories_app?sslmode=disable
MIGRATIONS_DIR ?= migrations

build:
	go build -o bin/server ./cmd/server

run:
	go run ./cmd/server -migrate

test:
	go test -race ./...

fmt:
	gofmt -w .
	goimports -w .

lint:
	golangci-lint run ./...

migrate-up:
	migrate -path $(MIGRATIONS_DIR) -database "$(DATABASE_URL)" up

migrate-down:
	migrate -path $(MIGRATIONS_DIR) -database "$(DATABASE_URL)" down

docker-build:
	docker compose -f ../docker-compose.yml build

docker-up:
	docker compose -f ../docker-compose.yml up -d

docker-down:
	docker compose -f ../docker-compose.yml down

docker-logs:
	docker compose -f ../docker-compose.yml logs -f backend
