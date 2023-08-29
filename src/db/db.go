package db

import (
	"database/sql"
	"fmt"

	"github.com/automatedrcs/arcs-go/secrets"
	_ "github.com/lib/pq"
)

func ConnectToDatabase() (*sql.DB, error) {
	host, err := secrets.Get("CLOUD_SQL_PRIVATE_IP")
	if err != nil {
		return nil, fmt.Errorf("failed to retrieve cloud sql private IP: %v", err)
	}

	dbname := "arcs_db"
	user := "arcs_user"
	password, err := secrets.Get("arcs-db-password")
	if err != nil {
		return nil, fmt.Errorf("failed to retrieve db password: %v", err)
	}

	connStr := fmt.Sprintf("host=%s dbname=%s user=%s password=%s sslmode=disable",
		host, dbname, user, password)
	db, err := sql.Open("postgres", connStr)
	if err != nil {
		return nil, fmt.Errorf("failed to open database connection: %v", err)
	}

	return db, nil
}

type Database interface {
	Query(query string, args ...interface{}) (*sql.Rows, error)
	// add other methods you might need like QueryRow, Exec, etc.
}

type DBImplementation struct {
	db *sql.DB
}

func (dbi *DBImplementation) Query(query string, args ...interface{}) (*sql.Rows, error) {
	return dbi.db.Query(query, args...)
}
