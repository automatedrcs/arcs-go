package main

import (
	"database/sql"
	"errors"
	"testing"

	"github.com/automatedrcs/arcs-go/db"
	"github.com/automatedrcs/arcs-go/mocks"
	"github.com/golang/mock/gomock"
)

func TestMainFunc(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockDB := mocks.NewMockDB(ctrl)

	// Mock the ConnectToDatabase function to return a mock database without error
	db.ConnectToDatabase = func() (*sql.DB, error) {
		return mockDB, nil
	}

	// Mock the Ping function to simulate successful pinging of the database
	mockDB.EXPECT().Ping().Return(nil)

	// We can't easily test http.ListenAndServe as it will start a server and block,
	// but we can at least test up to that point.
	main()
}

func TestMainFuncWithDBError(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockDB := mocks.NewMockDB(ctrl)

	// Mock the ConnectToDatabase function to return an error
	db.ConnectToDatabase = func() (*sql.DB, error) {
		return nil, errors.New("Mocked DB Error")
	}

	// This test will call the main function expecting it to panic due to the mocked DB error.
	// Therefore, we recover from the panic to pass the test.
	defer func() {
		if r := recover(); r == nil {
			t.Errorf("The code did not panic when expected")
		}
	}()

	main()
}
