# Accept the Go version for the image to be set as a build argument.
# Default to Go 1.11
ARG GO_VERSION=1.12

# First stage: build the executable.
FROM golang:${GO_VERSION}-alpine AS builder

# Install the Certificate-Authority certificates for the app to be able to make
# calls to HTTPS endpoints.
RUN apk add --no-cache --update alpine-sdk git ca-certificates gcc

# Set the working directory outside $GOPATH to enable the support for modules.
WORKDIR /src

# Gets deps - these dont change much -> makes builds faster
COPY ./src/go.mod ./src/go.sum ./
RUN go mod download

COPY ./src ./

RUN make build

# everything http runs on here
EXPOSE 9998

# Run the compiled binary.
CMD rm -f /tmp/reva.pid && ./cmd/revad/revad -c /etc/revad/revad.toml -p /tmp/revad.pid
