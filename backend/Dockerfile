FROM golang:1.25-alpine AS builder

WORKDIR /app

COPY go.mod ./
COPY go.su[m] ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /server ./cmd/server

FROM alpine:3.20
RUN apk --no-cache add ca-certificates tzdata
WORKDIR /app
COPY --from=builder /server /app/server

EXPOSE 8080
USER nobody
ENTRYPOINT ["/app/server"]
