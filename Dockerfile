# Use the official Golang image as a builder
FROM golang:1.21 AS builder

# Set the current working directory inside the container
WORKDIR /app

# Copy the Go source files into the container
COPY src/ .

# Get the dependencies and build the application
RUN go mod download && \
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o arcs-go .

# Use a lightweight alpine image for the runnable container
FROM alpine:latest

# Set the current working directory
WORKDIR /root/

# Copy the compiled Go binary into this container
COPY --from=builder /app/arcs-go .

# Expose the port the app runs on
EXPOSE 8080

# Command to run when starting the container
CMD ["./arcs-go"]
