package main

import (
	"log"
	"net/http"

	"github.com/automatedrcs/arcs-go/auth"
	"github.com/automatedrcs/arcs-go/db"
)

// Global DBConnector
var connector db.DBConnector = &db.RealDBConnector{}

func main() {
	// Setup routes
	setupRoutes()

	// Listen and serve
	log.Println("Starting server on :8080...")
	log.Fatal(http.ListenAndServe(":8080", nil))
}

func setupRoutes() {
	http.HandleFunc("/auth/google/login", auth.HandleGoogleAuth)
	http.HandleFunc("/auth/google/callback", auth.HandleGoogleCallback)
	http.HandleFunc("/health", healthCheck)
}

// A simple health check endpoint
func healthCheck(w http.ResponseWriter, r *http.Request) {
	dbConnection, err := connector.ConnectToDatabase()
	if err != nil {
		http.Error(w, "Database connection error", http.StatusInternalServerError)
		return
	}
	defer dbConnection.Close()

	err = dbConnection.Ping()
	if err != nil {
		http.Error(w, "Database ping failed", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}
