package anthropicadapter

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"

	"github.com/anthropics/anthropic-sdk-go"
	"github.com/anthropics/anthropic-sdk-go/option"
)

// Client wraps the Anthropic SDK for itinerary generation.
type Client struct {
	inner *anthropic.Client
}

// NewClient returns an Anthropic client authenticated with the given API key.
func NewClient(apiKey string) *Client {
	c := anthropic.NewClient(option.WithAPIKey(apiKey))
	return &Client{inner: &c}
}

// GenerateItineraryInput carries trip details for itinerary generation.
type GenerateItineraryInput struct {
	Title       string
	Destination string
	StartDate   string
	EndDate     string
	Vibes       []string
}

// GeneratedItem is one AI-generated itinerary entry.
type GeneratedItem struct {
	Day          int     `json:"day"`
	Title        string  `json:"title"`
	Description  string  `json:"description"`
	StartTime    *string `json:"start_time"`
	LocationName string  `json:"location_name"`
	Lat          float64 `json:"lat"`
	Lng          float64 `json:"lng"`
}

// ChatMessage is a single turn in a refinement conversation.
type ChatMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

// GenerateItinerary calls Claude to produce a day-by-day itinerary JSON array.
func (c *Client) GenerateItinerary(ctx context.Context, in GenerateItineraryInput) ([]GeneratedItem, error) {
	vibes := strings.Join(in.Vibes, ", ")
	if vibes == "" {
		vibes = "general travel"
	}

	userPrompt := fmt.Sprintf(
		"Trip: %s\nDestination: %s\nDates: %s to %s\nVibes: %s\n\n"+
			"Generate a day-by-day itinerary. For each activity output a JSON object:\n"+
			`{"day": <int>, "title": <str>, "description": <str>, "start_time": <"HH:MM" or null>, `+
			`"location_name": <str>, "lat": <float>, "lng": <float>}`+"\n\n"+
			"Return ONLY a valid JSON array with no markdown or preamble.",
		in.Title, in.Destination, in.StartDate, in.EndDate, vibes,
	)

	resp, err := c.inner.Messages.New(ctx, anthropic.MessageNewParams{
		Model:     anthropic.ModelClaudeSonnet4_6,
		MaxTokens: 4096,
		System: []anthropic.TextBlockParam{
			{
				Type: "text",
				Text: "You are a travel planner. Return only valid JSON, no markdown, no preamble. Never invent places — use real, verifiable locations.",
			},
		},
		Messages: []anthropic.MessageParam{
			anthropic.NewUserMessage(anthropic.NewTextBlock(userPrompt)),
		},
	})
	if err != nil {
		return nil, fmt.Errorf("generate itinerary: %w", err)
	}

	raw := extractText(resp)
	var items []GeneratedItem
	if err := json.Unmarshal([]byte(raw), &items); err != nil {
		return nil, fmt.Errorf("parse itinerary response: %w (raw: %.200s)", err, raw)
	}
	return items, nil
}

// RefineItinerary sends a chat refinement message and returns updated items.
// history is the prior conversation (role: user/assistant, content: string).
// PRIVACY: never pass logistics fields in currentItems or history.
func (c *Client) RefineItinerary(ctx context.Context, history []ChatMessage, userMessage string) (string, error) {
	messages := make([]anthropic.MessageParam, 0, len(history)+1)
	for _, h := range history {
		block := anthropic.NewTextBlock(h.Content)
		if h.Role == "assistant" {
			messages = append(messages, anthropic.NewAssistantMessage(block))
		} else {
			messages = append(messages, anthropic.NewUserMessage(block))
		}
	}
	messages = append(messages, anthropic.NewUserMessage(anthropic.NewTextBlock(userMessage)))

	resp, err := c.inner.Messages.New(ctx, anthropic.MessageNewParams{
		Model:     anthropic.ModelClaudeSonnet4_6,
		MaxTokens: 4096,
		System: []anthropic.TextBlockParam{
			{
				Type: "text",
				Text: "You are a travel planner helping refine an itinerary. When asked to change the itinerary, return a valid JSON array of items using the same schema as before. For conversational replies, return plain text.",
			},
		},
		Messages: messages,
	})
	if err != nil {
		return "", fmt.Errorf("refine itinerary: %w", err)
	}

	return extractText(resp), nil
}

func extractText(msg *anthropic.Message) string {
	for _, block := range msg.Content {
		if block.Type == "text" {
			return block.Text
		}
	}
	return ""
}
