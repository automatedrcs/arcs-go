package auth

import (
	"context"
	"fmt"
	"net/http"

	"github.com/automatedrcs/arcs-go/secrets"
	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"
)

var googleOauthConfig *oauth2.Config

func init() {
	clientID, _ := secrets.Get("CLIENT_ID")
	clientSecret, _ := secrets.Get("CLIENT_SECRET")

	googleOauthConfig = &oauth2.Config{
		RedirectURL:  "http://localhost:8080/auth/google/callback",
		ClientID:     clientID,
		ClientSecret: clientSecret,
		Scopes:       []string{"https://www.googleapis.com/auth/calendar.readonly"},
		Endpoint:     google.Endpoint,
	}
}

// Exported function
func HandleGoogleAuth(w http.ResponseWriter, r *http.Request) {
	url := googleOauthConfig.AuthCodeURL("state", oauth2.AccessTypeOffline)
	http.Redirect(w, r, url, http.StatusTemporaryRedirect)
}

// Exported function
func HandleGoogleCallback(w http.ResponseWriter, r *http.Request) {
	code := r.FormValue("code")
	token, err := googleOauthConfig.Exchange(context.Background(), code) // Using context.Background() as per your feedback
	if err != nil {
		http.Error(w, "Failed to exchange token", http.StatusInternalServerError)
		return
	}

	// Print the token to the console for testing purposes.
	fmt.Printf("Retrieved token: %+v\n", token)

	// TODO: Use the token for other purposes, such as making authenticated API calls or storing it securely.
}
