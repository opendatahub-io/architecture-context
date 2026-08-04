package cmd

import (
	"encoding/json"
	"testing"

	"github.com/jctanner/arch-query/internal/types"
)

func TestFilteredWebhookJSONUsesEmptyArrays(t *testing.T) {
	filtered := filterWebhooks(nil)
	if filtered == nil {
		t.Fatal("filterWebhooks(nil) returned a nil slice")
	}

	result := struct {
		Webhooks         []types.Webhook    `json:"webhooks"`
		PlatformWebhooks []types.WebhookRef `json:"platform_webhooks,omitempty"`
		ExternalWebhooks []types.WebhookRef `json:"external_webhooks,omitempty"`
	}{Webhooks: filtered}

	payload, err := json.Marshal(result)
	if err != nil {
		t.Fatalf("marshal webhook result: %v", err)
	}
	if string(payload) != `{"webhooks":[]}` {
		t.Fatalf("expected empty webhook array, got %s", payload)
	}
}
