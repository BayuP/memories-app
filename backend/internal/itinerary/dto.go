package itinerary

// CreateItemRequest is the POST /trips/:id/items body.
type CreateItemRequest struct {
	Day          int     `json:"day"`
	StartTime    *string `json:"start_time"`
	EndTime      *string `json:"end_time"`
	Title        string  `json:"title"`
	Description  *string `json:"description"`
	LocationName *string `json:"location_name"`
	Lat          *float64 `json:"lat"`
	Lng          *float64 `json:"lng"`
}

// UpdateItemRequest is the PATCH /trips/:id/items/:itemId body.
type UpdateItemRequest struct {
	Day          *int     `json:"day"`
	StartTime    *string  `json:"start_time"`
	EndTime      *string  `json:"end_time"`
	Title        *string  `json:"title"`
	Description  *string  `json:"description"`
	LocationName *string  `json:"location_name"`
	Lat          *float64 `json:"lat"`
	Lng          *float64 `json:"lng"`
}

// ItemResponse is the public item representation.
type ItemResponse struct {
	ID           string   `json:"id"`
	TripID       string   `json:"trip_id"`
	Day          int      `json:"day"`
	StartTime    *string  `json:"start_time"`
	EndTime      *string  `json:"end_time"`
	Title        string   `json:"title"`
	Description  *string  `json:"description"`
	LocationName *string  `json:"location_name"`
	Lat          *float64 `json:"lat"`
	Lng          *float64 `json:"lng"`
	Source       string   `json:"source"`
	CreatedAt    string   `json:"created_at"`
	UpdatedAt    string   `json:"updated_at"`
}

// ReorderItem carries a single item's new sort order.
type ReorderItem struct {
	ID        string `json:"id"`
	SortOrder int    `json:"sort_order"`
}

// ReorderRequest is the PATCH /trips/:id/items/reorder body.
type ReorderRequest struct {
	Items []ReorderItem `json:"items"`
}

// AIItemInput is used by the AI generator to bulk-insert items.
type AIItemInput struct {
	Day          int      `json:"day"`
	Title        string   `json:"title"`
	Description  string   `json:"description"`
	StartTime    *string  `json:"start_time"`
	LocationName string   `json:"location_name"`
	Lat          float64  `json:"lat"`
	Lng          float64  `json:"lng"`
}

func toItemResponse(item *Item) ItemResponse {
	return ItemResponse{
		ID:           item.ID.String(),
		TripID:       item.TripID.String(),
		Day:          item.Day,
		StartTime:    item.StartTime,
		EndTime:      item.EndTime,
		Title:        item.Title,
		Description:  item.Description,
		LocationName: item.LocationName,
		Lat:          item.Lat,
		Lng:          item.Lng,
		Source:       item.Source,
		CreatedAt:    item.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		UpdatedAt:    item.UpdatedAt.Format("2006-01-02T15:04:05Z07:00"),
	}
}
