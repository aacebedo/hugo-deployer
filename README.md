# Hugo deployer

This Docker image provides a complete solution for deploying a Hugo website with automatic update when calling a
specific endpoint.

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
   docker-compose -f example/docker-compose.yaml up -d --env ./example/.env
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

- `PORT` - Port to serve on; defaults to a random port
- `GIT_BRANCH` - Git branch to use; defaults to main
- `PATH_PREFIX` - Subdirectory path within the repository that holds the Hugo project, for example "docs" or "website."
  If unset, the tool expects the Hugo project at the repository root.

## Hooks

You can add custom hooks that run before and after the Hugo build by creating a `hooks` directory in your Hugo project
(or at the repository root if `PATH_PREFIX` isn't set):

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

Scripts in `hooks/pre-build/` run after the deployer clones or updates the repository but before the Hugo build. These
hooks have access to the following environment variables:

- `BUILD_DIR` - Directory that stores the build output
- `BUILD_DATE` - Timestamp of the current build
- `SITE_SOURCE_DIR` - Path to the repository root
- `HUGO_PROJECT_DIR` - Path to the Hugo project directory
- `PATH_PREFIX` - The configured path prefix
- `GIT_REPO_URL` - Git repository URL
- `BRANCH` - Git branch that the build uses

Hook scripts must have a `.sh` extension. Bash executes them, so you don't need to set executable permissions. If a
pre-build hook fails, the build stops.

### Post-build hooks

Scripts in `hooks/post-build/` run after the Hugo build completes successfully. They have access to the same environment
variables as pre-build hooks. Post-build hook failures log as warnings but don't stop the build.

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
  -f src/Dockerfile \
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

The dev container targets development of the Docker container itself, not Hugo site development:

**With VS Code:**

1. Install the "Dev Containers" extension
2. Open the project in VS Code
3. Click "Reopen in Container" when prompted
4. Wait for VS Code to pull and bootstrap the image; this happens only on the first run

## License

Massachusetts Institute of Technology (MIT) License
