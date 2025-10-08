#!/usr/bin/env bash
set -e

echo "Starting site update.."
echo "Building Hugo site..."

# Create timestamp for this build
BUILD_DATE=$(date +"%Y%m%d_%H%M%S")
BUILD_DIR="/app/builds/${BUILD_DATE}"
SITE_SOURCE_DIR="/app/site"
PATH_PREFIX=${PATH_PREFIX:-""}

echo "Creating build directory: ${BUILD_DIR}"
mkdir -p "$BUILD_DIR"

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
HUGO_PROJECT_DIR="/app/site"

if [ -n "$PATH_PREFIX" ]; then
		HUGO_PROJECT_DIR="/app/site/${PATH_PREFIX}"
fi

if [ ! -d "$HUGO_PROJECT_DIR" ]; then
		echo "Error: Path '${HUGO_PROJECT_DIR}' does not exist "
		exit 1
fi

echo "Running pre-build hooks..."

# Execute all pre-build hooks from repository
PRE_BUILD_HOOKS_DIR="${HUGO_PROJECT_DIR}/hooks/pre-build"
if [ -d "$PRE_BUILD_HOOKS_DIR" ]; then
	echo "Found pre-build hooks directory: $PRE_BUILD_HOOKS_DIR"

	# Check if directory has any files
	if [ "$(find "$PRE_BUILD_HOOKS_DIR" -maxdepth 1 \( -type f -o -type l \) -name "*.sh" | wc -l)" -gt 0 ]; then
		# Export useful variables for hooks
		export BUILD_DIR
		export BUILD_DATE
		export SITE_SOURCE_DIR
		export PATH_PREFIX
		export GIT_REPO_URL
		export BRANCH
		export HUGO_PROJECT_DIR

		# Iterate through all files in pre-build hooks directory
		for hook_file in "$PRE_BUILD_HOOKS_DIR"/*.sh; do
			if [ -f "$hook_file" ] || [ -L "$hook_file" ]; then
				echo "Executing pre-build hook: $(basename "$hook_file")"

				# Execute the hook using bash
				if bash "$hook_file"; then
					echo "Hook $(basename "$hook_file") completed successfully"
				else
					echo "Error: Hook $(basename "$hook_file") failed with exit code $?"
					echo "Aborting build due to pre-build hook failure"
					rm -rf "$BUILD_DIR"
					exit 1
				fi
			fi
		done

		echo "All pre-build hooks completed successfully"
	else
		echo "No pre-build hooks found in $PRE_BUILD_HOOKS_DIR"
	fi
else
	echo "Pre-build hooks directory not found: $PRE_BUILD_HOOKS_DIR (skipping)"
fi

# Check if it's a Hugo site
if [ ! -f "${HUGO_PROJECT_DIR}/hugo.toml" ] && \
		[ ! -f "${HUGO_PROJECT_DIR}/config.toml" ] && \
		[ ! -f "${HUGO_PROJECT_DIR}/config.yaml" ] && \
		[ ! -f "${HUGO_PROJECT_DIR}/config.yml" ]; then
		echo "Warning: No Hugo configuration file found in ${HUGO_PROJECT_DIR}"
fi

# Build the Hugo site with versioned directory
echo "Building Hugo site..."
cd "$HUGO_PROJECT_DIR"

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

		# Execute all post-build hooks from repository
		POST_BUILD_HOOKS_DIR="${HUGO_PROJECT_DIR}/hooks/post-build"
		if [ -d "$POST_BUILD_HOOKS_DIR" ]; then
			echo "Found post-build hooks directory: $POST_BUILD_HOOKS_DIR"

			# Check if directory has any files
			if [ "$(find "$POST_BUILD_HOOKS_DIR" -maxdepth 1 \( -type f -o -type l \) -name "*.sh" | wc -l)" -gt 0 ]; then
				# Export useful variables for hooks
				export BUILD_DIR
				export BUILD_DATE
				export SITE_SOURCE_DIR
				export PATH_PREFIX
				export GIT_REPO_URL
				export BRANCH
				export HUGO_PROJECT_DIR

				# Iterate through all files in post-build hooks directory
				for hook_file in "$POST_BUILD_HOOKS_DIR"/*.sh; do
					if [ -f "$hook_file" ] || [ -L "$hook_file" ]; then
						echo "Executing post-build hook: $(basename "$hook_file")"

						# Execute the hook using bash
						if bash "$hook_file"; then
							echo "Hook $(basename "$hook_file") completed successfully"
						else
							echo "Warning: Hook $(basename "$hook_file") failed with exit code $?"
						fi
					fi
				done

				echo "All post-build hooks completed"
			else
				echo "No post-build hooks found in $POST_BUILD_HOOKS_DIR"
			fi
		else
			echo "Post-build hooks directory not found: $POST_BUILD_HOOKS_DIR (skipping)"
		fi

		echo "Build completed at: $(date)"
else
		echo "Error: Hugo build failed"
		# Clean up failed build directory
		rm -rf "$BUILD_DIR"
		exit 1
fi

echo "Site update completed successfully!"
