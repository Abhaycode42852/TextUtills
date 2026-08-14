# ---------- Stage 1: Build the webhook binary from source ----------
# We build directly from the tool's actual GitHub source (adnanh/webhook)
# rather than trusting a prebuilt third-party Docker Hub image. This
# matters more here than usual: this container will later get access to
# the Docker socket (effectively root-level control of your machine), so
# knowing exactly what's inside it end-to-end is worth the extra step.
FROM golang:1.23-alpine AS build

RUN apk add --no-cache git

# Fetches the source from GitHub and compiles it - "go install" both
# downloads and builds in one step, placing the binary in $GOPATH/bin.
RUN go install github.com/adnanh/webhook@latest


# ---------- Stage 2: Runtime image ----------
# A normal Alpine base (unlike the "scratch" image used by some
# prebuilt options) so we can install the Docker CLI alongside it.
FROM alpine:3.20

# Docker CLI (client only, not a full Docker daemon) - this is what lets
# deploy.sh's docker commands reach the host's real Docker Engine, once
# the socket is mounted in when we run this container.
RUN apk add --no-cache docker-cli

# Copy the compiled webhook binary from the build stage
COPY --from=build /go/bin/webhook /usr/local/bin/webhook

# Copy our webhook rules and the deploy script into the image
COPY hooks.json /etc/webhook/hooks.json
COPY deploy.sh /scripts/deploy.sh
RUN chmod +x /scripts/deploy.sh

EXPOSE 9000

# -verbose gives us useful logs; -hooks points at our config file
ENTRYPOINT ["/usr/local/bin/webhook", "-hooks=/etc/webhook/hooks.json", "-verbose"]
