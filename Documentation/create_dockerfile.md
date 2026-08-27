
## Creating the Dockerfile

This section walks through building a `Dockerfile` for the app, so it can be containerized and deployed the same way it runs in production (EC2, via the CI/CD pipeline).

### 1. Create a file named `dockerfile` in the project root



### 2. Basic structure

```dockerfile
# Use a lightweight official Python image as the base
FROM python:3.15-slim

# Set the working directory inside the container
WORKDIR /app

# Update packages and curl
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy dependency file first (better layer caching)
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY app.py .

# Create a user to access app folder inside docker
RUN useradd -m -u 1000 appuser \
    && chown -R appuser:appuser /app

USER appuser

# Expose the port the app listens on
EXPOSE 5000

# Command to run when the container starts
CMD ["python", "app.py"]
```

### 3. Build the image locally (to test before pushing)

```bash
docker build -t techflow-app .
```

### 4. Run the container locally

```bash
docker run -d --name techflow-container -p 5000:5000 techflow-app
```

### 5. Verify it's working

```bash
curl http://localhost:5000/health
```

### 6. Stop and remove the local test container

```bash
docker stop techflow-app
docker rm techflow-app
```


> In the actual CI/CD pipeline, this build-and-push step happens automatically via GitHub Actions (`docker/build-push-action`) on every push to `main`, tagging the image with both `:latest` and the commit SHA.

### Optional: `.dockerignore`

To keep the image small and avoid copying unnecessary files (virtual environments, git history, caches), add a `.dockerignore` file in the project root:

```
venv/
__pycache__/
*.pyc
.git/
.gitignore
README.md
.github/
```

---

## Quick Reference

| Task | Command |
|---|---|
| Run tests locally | `pytest test_app.py -v` |
| Run app locally | `python app.py` |
| Check health locally | `curl http://localhost:5000/health` |
| Build Docker image | `docker build -t techflow-app .` |
| Run Docker container | `docker run -d --name techflow-app -p 5000:5000 techflow-app` |
| Check health in container | `curl http://localhost:5000/health` |
