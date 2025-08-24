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
    GIT_REPO_URL=https://github.com/yourusername/your-hugo-site.git
    GIT_USERNAME=yourusername
    GIT_TOKEN=your_github_token
    API_KEY=your_api_key
    PORT=8080
    ```

3. **Run with Docker Compose:**

    ```bash
    docker-compose up -d
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
