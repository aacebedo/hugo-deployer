#!/usr/bin/env bash
set -e

# Run every *.sh hook in a directory.
# on_failure: "abort" cleans up BUILD_DIR and exits the script; "warn" logs and continues.
run_hooks() {
	local hooks_dir="$1"
	local phase="$2"
	local on_failure="$3"

	if [ ! -d "$hooks_dir" ]; then
		echo "${phase} hooks directory not found: $hooks_dir (skipping)"
		return 0
	fi

	echo "Found ${phase} hooks directory: $hooks_dir"

	if [ "$(find "$hooks_dir" -maxdepth 1 \( -type f -o -type l \) -name "*.sh" | wc -l)" -eq 0 ]; then
		echo "No ${phase} hooks found in $hooks_dir"
		return 0
	fi

	export BUILD_DIR BUILD_DATE SITE_SOURCE_DIR PATH_PREFIX GIT_REPO_URL BRANCH HUGO_PROJECT_DIR

	for hook_file in "$hooks_dir"/*.sh; do
		if [ -f "$hook_file" ] || [ -L "$hook_file" ]; then
			echo "Executing ${phase} hook: $(basename "$hook_file")"

			if bash "$hook_file"; then
				echo "Hook $(basename "$hook_file") completed successfully"
			else
				local exit_code=$?
				if [ "$on_failure" = "abort" ]; then
					echo "Error: Hook $(basename "$hook_file") failed with exit code $exit_code"
					echo "Aborting build due to ${phase} hook failure"
					rm -rf "$BUILD_DIR"
					exit 1
				else
					echo "Warning: Hook $(basename "$hook_file") failed with exit code $exit_code"
				fi
			fi
		fi
	done

	echo "All ${phase} hooks completed"
}

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

git config --global --add safe.directory /app/site

# Check if site directory exists
if [ ! -d "/app/site/.git" ]; then
	# Create credentials for HTTPS authentication
	GIT_DOMAIN=$(echo "$GIT_REPO_URL" | sed -n 's|\([^/]*\).*|\1|p')
	echo "https://${GIT_USERNAME}:${GIT_TOKEN}@${GIT_DOMAIN}" >"${HOME}/.git-credentials"
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

PRE_BUILD_HOOKS_DIR="${HUGO_PROJECT_DIR}/hooks/pre-build"
run_hooks "$PRE_BUILD_HOOKS_DIR" "pre-build" "abort"

# Check if it's a Hugo site
if [ ! -f "${HUGO_PROJECT_DIR}/hugo.toml" ] &&
	[ ! -f "${HUGO_PROJECT_DIR}/config.toml" ] &&
	[ ! -f "${HUGO_PROJECT_DIR}/config.yaml" ] &&
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

	POST_BUILD_HOOKS_DIR="${HUGO_PROJECT_DIR}/hooks/post-build"
	run_hooks "$POST_BUILD_HOOKS_DIR" "post-build" "warn"

	echo "Build completed at: $(date)"
else
	echo "Error: Hugo build failed"
	# Clean up failed build directory
	rm -rf "$BUILD_DIR"
	exit 1
fi

echo "Site update completed successfully!"
