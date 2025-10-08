# Hugo deployer

This Docker image provides a complete solution for deploying a Hugo website with
automatic update when calling a specific endpoint.

## Quick start

1. **Copy environment file:**

    ```bash
    cp .env.example .env
    ```

2. **Configure your environment:**

    ```bash
    # Edit .env with your values
    GIT_REPO_URL=github.com/yourusername/your-hugo-site.git
    GIT_USERNAME=yourusername
    GIT_TOKEN=your_github_token
    API_KEY=your_api_key
    PORT=8080
    ```

3. **Run with Docker Compose:**

    ```bash
    docker-compose up -d --env ./example/.env
    ```

4. **Initial site update:**

    ```bash
    curl -H "Authorization: Bearer your_api_key" \
          http://localhost:8080/update
    ```

## Environment variables

### Required

- `GIT_REPO_URL` - Git repository URL
- `GIT_USERNAME` - Git username
- `GIT_TOKEN` - Git personal access token
- `API_KEY` - API key for update endpoint protection

### Optional

- `PORT` - Port to serve on (default: random)
- `GIT_BRANCH` - Git branch to use (default: main)
- `PATH_PREFIX` - Subdirectory path within the repository where the Hugo project is located
(for example "docs" or "website"). If not set, the Hugo project is expected at the repository root.

## Hooks

You can add custom hooks that run before and after the Hugo build by creating a `hooks` directory in
your Hugo project (or at the repository root if `PATH_PREFIX` is not set):

```bash
your-hugo-site/
├── hooks/
│   ├── pre-build/
│   │   └── 01-prepare.sh
│   └── post-build/
│       └── 01-notify.sh
├── content/
├── themes/
└── hugo.toml
```

### Pre-build hooks

Scripts in `hooks/pre-build/` run after the repository is cloned/updated but before the Hugo build.
These hooks have access to the following environment variables:

- `BUILD_DIR` - Directory where the build output will be stored
- `BUILD_DATE` - Timestamp of the current build
- `SITE_SOURCE_DIR` - Path to the repository root
- `HUGO_PROJECT_DIR` - Path to the Hugo project directory
- `PATH_PREFIX` - The configured path prefix
- `GIT_REPO_URL` - Git repository URL
- `BRANCH` - Git branch being built

Hook scripts must have a `.sh` extension and will be executed using bash (no need to set executable
permissions). If a pre-build hook fails, the build is aborted.

### Post-build hooks

Scripts in `hooks/post-build/` run after the Hugo build completes successfully. They have access to
the same environment variables as pre-build hooks. Post-build hook failures are logged as warnings
but do not abort the build.

### Example hook

```bash
#!/bin/bash
# hooks/pre-build/01-prepare.sh

echo "Running custom preparation steps..."
cd "$HUGO_PROJECT_DIR"

# Install npm dependencies if package.json exists
if [ -f "package.json" ]; then
    npm install
fi

echo "Preparation complete!"
```

## Build arguments

You can customize versions during build:

```bash
docker build \
  --build-arg HUGO_VERSION=0.148.1 \
  --build-arg CADDY_VERSION=2.8.4 \
  --build-arg CADDY_EXEC_VERSION=v0.5.5 \
  -t hugo-site .
```

## API endpoints

### Update site

```bash
curl -H "Authorization: Bearer your_api_key" \
  http://localhost:8080/update
```

## Development setup

### Devcontainer

The dev container is designed for developing the Docker container itself, not for Hugo site development:

**With VS Code:**

1. Install the "Dev Containers" extension
2. Open the project in VS Code
3. Click "Reopen in Container" when prompted
4. Wait for the container to build (first time only)

## License

MIT
