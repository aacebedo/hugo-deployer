#!/usr/bin/env bash
set -e

echo "Starting site update.."
echo "Building Hugo site..."

# Create timestamp for this build
BUILD_DATE=$(date +"%Y%m%d_%H%M%S")
BUILD_DIR="/app/builds/${BUILD_DATE}"

echo "Creating build directory: ${BUILD_DIR}"
mkdir -p "$BUILD_DIR"

echo "Running pre-build hooks..."

# Execute all pre-build hooks
PRE_BUILD_HOOKS_DIR="/app/config/hooks/pre-build"
if [ -d "$PRE_BUILD_HOOKS_DIR" ]; then
	echo "Found pre-build hooks directory: $PRE_BUILD_HOOKS_DIR"

	# Check if directory has any files
	if [ "$(find "$PRE_BUILD_HOOKS_DIR" -maxdepth 1 -type f | wc -l)" -gt 0 ]; then
		# Export useful variables for hooks
		export BUILD_DIR
		export BUILD_DATE
		export SITE_SOURCE_DIR="/app/site"
		export GIT_REPO_URL
		export BRANCH

		# Iterate through all files in pre-build hooks directory
		for hook_file in "$PRE_BUILD_HOOKS_DIR"/*; do
			if [ -f "$hook_file" ]; then
				echo "Executing pre-build hook: $(basename "$hook_file")"

				# Check if file is executable
				if [ -x "$hook_file" ]; then
					# Execute the hook
					if "$hook_file"; then
						echo "Hook $(basename "$hook_file") completed successfully"
					else
						echo "Error: Hook $(basename "$hook_file") failed with exit code $?"
						echo "Aborting build due to pre-build hook failure"
						rm -rf "$BUILD_DIR"
						exit 1
					fi
				else
					echo "Warning: Hook $(basename "$hook_file") is not executable, skipping"
				fi
			fi
		done

		echo "All pre-build hooks completed successfully"
	else
		echo "No pre-build hooks found in $PRE_BUILD_HOOKS_DIR"
	fi
else
	echo "Pre-build hooks directory not found: $PRE_BUILD_HOOKS_DIR"
fi

# check if required environment variables are set
if [ -z "$GIT_REPO_URL" ]; then
		echo "Error: GIT_REPO_URL environment variable is not set"
		exit 1
fi

if [ -z "$GIT_USERNAME" ] || [ -z "$GIT_TOKEN" ]; then
		echo "Error: GIT_USERNAME and GIT_TOKEN environment variables must be set"
		exit 1
fi
if [ -z "$UPDATE_API_KEY" ]; then
		echo "Error: UPDATE_API_KEY environment variable is not set"
		exit 1
fi

# Set branch (default to main)
BRANCH=${GIT_BRANCH:-main}

# Check if site directory exists
if [ ! -d "/app/site/.git" ]; then
		# Create credentials for HTTPS authentication
		GIT_DOMAIN=$(echo "$GIT_REPO_URL" | sed -n 's|\([^/]*\).*|\1|p')
		echo "https://${GIT_USERNAME}:${GIT_TOKEN}@${GIT_DOMAIN}" > "${HOME}/.git-credentials"
		git config --global credential.helper store
		echo "Cloning repository..."
		git clone --recurse-submodules "https://$GIT_REPO_URL" /app/site
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

		echo "Running post-build hooks..."

		# Execute all post-build hooks
		POST_BUILD_HOOKS_DIR="/app/config/hooks/post-build"
		if [ -d "$POST_BUILD_HOOKS_DIR" ]; then
			# Check if directory has any files
			if [ "$(find "$POST_BUILD_HOOKS_DIR" -maxdepth 1 -type f | wc -l)" -gt 0 ]; then
				# Export useful variables for hooks
				export BUILD_DIR
				export BUILD_DATE

				# Iterate through all files in post-build hooks directory
				for hook_file in "$POST_BUILD_HOOKS_DIR"/*; do
					if [ -f "$hook_file" ]; then
						echo "Executing post-build hook: $(basename "$hook_file")"

						# Check if file is executable
						if [ -x "$hook_file" ]; then
							# Execute the hook
							if "$hook_file"; then
								echo "Hook $(basename "$hook_file") completed successfully"
							else
								echo "Warning: Hook $(basename "$hook_file") failed with exit code $?"
							fi
						else
							echo "Warning: Hook $(basename "$hook_file") is not executable, skipping"
						fi
					fi
				done

				echo "All post-build hooks completed"
			else
				echo "No post-build hooks found in $POST_BUILD_HOOKS_DIR"
			fi
		fi

		echo "Build completed at: $(date)"
else
		echo "Error: Hugo build failed"
		# Clean up failed build directory
		rm -rf "$BUILD_DIR"
		exit 1
fi

# Clean up credentials
rm -f "${HOME}/.git-credentials"

echo "Site update completed successfully!"
