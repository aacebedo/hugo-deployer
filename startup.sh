#!/bin/bash
set -e

echo "Starting Hugo site container..."

# Create initial build directory if none exists
if [ ! -L "/app/builds/current" ] && [ ! -d "/app/builds/current" ]; then
		echo "No build directory found. Performing initial build..."

		# Run the update script to build the site initially
		/usr/local/bin/update-site.sh
		echo "Initial site build completed"
fi

echo "Starting Caddy web server..."
exec "$@"
