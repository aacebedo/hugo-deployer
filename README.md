# Hugo Docker deployment

This Docker image provides a complete solution for hosting a Hugo website with automatic update
when calling a specific endpoint.

## Quick start

1. **Copy environment file:**

    ```bash
    cp .env.example .env
    ```

2. **Configure your environment:**

    ```bash
    # Edit .env with your values
    GIT_REPO_URL=https://github.com/yourusername/your-hugo-site.git
    GIT_USERNAME=yourusername
    GIT_TOKEN=your_github_token
    API_KEY=your_secure_api_key
    ```

3. **Run with Docker Compose:**

    ```bash
    docker-compose up -d
    ```

4. **Initial site update:**

    ```bash
    curl -H "Authorization: Bearer your_secure_api_key" \
          http://localhost/update
    ```

## Environment variables

### Required

- `GIT_REPO_URL` - GitHub repository URL
- `GIT_USERNAME` - GitHub username
- `GIT_TOKEN` - GitHub personal access token
- `API_KEY` - API key for update endpoint protection

### Optional

- `GIT_BRANCH` - Git branch to use (default: main)
- `DOMAIN` - Domain name (default: localhost)
- `PORT` - Port to serve on (default: 80)

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
  http://localhost/update
```

## Development setup

### Devcontainer

The dev container is designed for developing the Docker container itself, not for Hugo site development:

**With VS Code:**

1. Install the "Dev Containers" extension
2. Open the project in VS Code
3. Click "Reopen in Container" when prompted
4. Wait for the container to build (first time only)

### Using pre-built Images

Instead of building locally, you can use pre-built images:

```yaml
# docker-compose.yml
services:
  hugo-site:
    image: ghcr.io/yourusername/hugo-deployer:latest
    # ... rest of configuration
```

Or with a specific version:

```yaml
services:
  hugo-site:
    image: ghcr.io/yourusername/hugo-deployer:v1.0.0
    # ... rest of configuration
```

## License

MIT
