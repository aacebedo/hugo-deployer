#!/bin/bash
set -e

echo "Starting site update..."

# Check if required environment variables are set
if [ -z "$GIT_REPO_URL" ]; then
		echo "Error: GIT_REPO_URL environment variable is not set"
		exit 1
fi

if [ -z "$GIT_USERNAME" ] || [ -z "$GIT_TOKEN" ]; then
		echo "Error: GIT_USERNAME and GIT_TOKEN environment variables must be set"
		exit 1
fi

# Create credentials for HTTPS authentication
echo "https://${GIT_USERNAME}:${GIT_TOKEN}@github.com" > /root/.git-credentials
git config --global credential.helper store

# Set branch (default to main)
BRANCH=${GIT_BRANCH:-main}

# Check if site directory exists
if [ ! -d "/app/site/.git" ]; then
		echo "Cloning repository..."
		git clone "$GIT_REPO_URL" /app/site
		cd /app/site
		git checkout "$BRANCH"
else
		echo "Updating existing repository..."
		cd /app/site
		git fetch origin
		git reset --hard "origin/$BRANCH"
		git checkout "$BRANCH"
		git pull origin "$BRANCH"
fi

echo "Repository updated successfully"

# Check if it's a Hugo site
if [ ! -f "/app/site/hugo.toml" ] && \
		[ ! -f "/app/site/config.toml" ] && \
		[ ! -f "/app/site/config.yaml" ] && \
		[ ! -f "/app/site/config.yml" ]; then
		echo "Warning: No Hugo configuration file found"
fi

# Build the Hugo site with versioned directory
echo "Building Hugo site..."
cd /app/site

# Create timestamp for this build
BUILD_DATE=$(date +"%Y%m%d_%H%M%S")
BUILD_DIR="/app/builds/${BUILD_DATE}"

echo "Creating build directory: ${BUILD_DIR}"
mkdir -p "$BUILD_DIR"

# Install Hugo modules if needed
if [ -f "go.mod" ]; then
		echo "Installing Hugo modules..."
		hugo mod get
fi

# Build the site to the timestamped directory
echo "Building site to: ${BUILD_DIR}"
hugo --minify --destination "$BUILD_DIR"

# Check if build was successful
# shellcheck disable=SC2181
if [ $? -eq 0 ]; then
		echo "Hugo site built successfully to ${BUILD_DIR}"

		# Run Pagefind to generate search index
		echo "Generating search index with Pagefind..."
		pagefind --site "$BUILD_DIR"

		# shellcheck disable=SC2181
		if [ $? -eq 0 ]; then
				echo "Pagefind search index generated successfully"
		else
				echo "Warning: Pagefind failed to generate search index"
		fi

		# Update symlink atomically
		echo "Updating symlink to new build..."
		ln -sfn "$BUILD_DIR" /app/builds/current

		echo "Symlink updated: /app/builds/current -> ${BUILD_DIR}"

		# Clean up old builds (keep last 5)
		echo "Cleaning up old builds..."
		cd /app/builds
		# shellcheck disable=SC2012
		ls -t | tail -n +6 | xargs -r rm -rf
		echo "Cleanup completed - kept last 5 builds"

		echo "Build completed at: $(date)"
else
		echo "Error: Hugo build failed"
		# Clean up failed build directory
		rm -rf "$BUILD_DIR"
		exit 1
fi

# Clean up credentials
rm -f /root/.git-credentials

echo "Site update completed successfully!"
