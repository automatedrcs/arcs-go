package secrets

import (
	"context"
	"fmt"

	secretmanager "cloud.google.com/go/secretmanager/apiv1"
	secretmanagerpb "google.golang.org/genproto/googleapis/cloud/secretmanager/v1"
)

func Get(secretName string) (string, error) {
	ctx := context.Background()
	client, err := secretmanager.NewClient(ctx)
	if err != nil {
		return "", err
	}

	secretRequest := &secretmanagerpb.AccessSecretVersionRequest{
		Name: fmt.Sprintf("projects/arcs-391022/secrets/%s/versions/latest", secretName),
	}

	result, err := client.AccessSecretVersion(ctx, secretRequest)
	if err != nil {
		return "", err
	}

	return string(result.Payload.Data), nil
}
