#!/bin/bash
set -e

# Start Caddy first (backgrounded, not exec'd) so it's already serving when the initial build's post-build hooks
# run - e.g. generate-pdf.sh needs a live server to render the freshly built pages against.
echo "Starting Caddy web server..."
caddy run --config /app/config/Caddyfile &
CADDY_PID=$!

# Caddy is no longer PID 1 (it's backgrounded, not exec'd), so Kubernetes' SIGTERM on pod termination would
# otherwise only reach this wrapper script, leaving Caddy orphaned until the terminationGracePeriodSeconds
# SIGKILL. Forward it explicitly so Caddy still gets a clean shutdown.
trap 'kill -TERM "$CADDY_PID" 2>/dev/null; wait "$CADDY_PID"; exit $?' TERM INT

echo "Starting Hugo site container..."

# Create initial build directory if none exists
if [ ! -L "/app/builds/current" ] && [ ! -d "/app/builds/current" ]; then
	echo "No build directory found. Performing initial build..."

	# Run the update script to build the site initially
	/usr/local/bin/update-site.sh
	echo "Initial site build completed"
fi

wait "$CADDY_PID"
