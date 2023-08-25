package main

import (
	"database/sql" // Import sql package
	"log"
	"net/http"

	"github.com/automatedrcs/arcs-go/auth"
	"github.com/automatedrcs/arcs-go/db"
)

var dbConnection *sql.DB

func main() {
	var err error
	dbConnection, err := db.ConnectToDatabase()
	if err != nil {
		log.Fatalf("Failed to connect to the database: %v", err)
	}
	defer dbConnection.Close()

	// Test the database connection
	err = dbConnection.Ping()
	if err != nil {
		log.Fatalf("Failed to ping the database: %v", err)
	}

	http.HandleFunc("/auth/google/login", auth.HandleGoogleAuth)
	http.HandleFunc("/auth/google/callback", auth.HandleGoogleCallback)

	http.ListenAndServe(":8080", nil)
}
