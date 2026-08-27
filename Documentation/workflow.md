# CI/CD Pipeline Documentation

This document explains how the GitHub Actions workflow (`.github/workflows/pipeline.yml`) builds, tests, deploys, and monitors the Techflow App on AWS EC2.

---

## Overview

The pipeline is defined in a single workflow file and runs three sequential jobs:

```
test  →  build-and-push  →  deploy
```
Each job only runs if the one(s) it depends on succeed. The `deploy` job is the most complex — it provisions no infrastructure itself, but connects to an **already-running** EC2 instance, snapshots the current stable docker image, deploys the new one, health-checks it, rolls back automatically on failure, and sends an email summary regardless of outcome.

---

## Trigger Conditions

```yaml
on:
  push:
    branches:
      - main
  pull_request:
    branches:
        - main
```

---

## Required Secrets

Configured under **Settings → Secrets and variables → Actions** in the repository.

| Secret | Used By | Purpose |
|---|---|---|
| `DOCKERHUB_USERNAME` | `build-and-push`, `deploy` | DockerHub login |
| `DOCKERHUB_TOKEN` | `build-and-push`, `deploy` | DockerHub access token (not your account password) |
| `AWS_ACCESS_KEY_ID` | `deploy` | AWS API authentication |
| `AWS_SECRET_ACCESS_KEY` | `deploy` | AWS API authentication |
| `AWS_REGION` | `deploy` | Region your EC2 instance runs in |
| `EC2_USERNAME` | `deploy` | SSH username for the EC2 instance (e.g. `ubuntu`) |
| `EC2_SSH_KEY` | `deploy` | Private key used to SSH into the instance |
| `EMAIL_USERNAME` | `deploy` | Gmail address used to send notification emails |
| `EMAIL_APP_PASSWORD` | `deploy` | Gmail App Password (not your regular Gmail password) |
| `EMAIL_RECIPIENT` | `deploy` | Address the deployment summary email is sent to |

Also defined at the workflow level (not a secret, just a plain value):

```yaml
env:
    IMAGE_NAME: your-dockerhub-username/techflow-app
```

---

## Jobs

### 1. `test`

Runs the Python test suite before anything else is allowed to proceed.

| Step | What it does |
|---|---|
| Checkout code | Pulls the repo onto the runner |
| Set up Python | Installs Python 3.13 |
| Install dependencies | `pip install -r requirements.txt` |
| Run tests | `pytest test_app.py -v` |

If any test fails, the entire pipeline stops here — neither `build-and-push` nor `deploy` will run.

### 2. `build-and-push`

**Depends on:** `test`

Builds the Docker image and pushes it to DockerHub with two tags.

| Step | What it does |
|---|---|
| Checkout code | Pulls the repo |
| Login to Docker Hub | Authenticates using `DOCKERHUB_USERNAME` / `DOCKERHUB_TOKEN` |
| Set up QEMU / Buildx | Enables multi-platform image builds |
| Build and push | Builds the image from the `Dockerfile`, tags it, and pushes both: `IMAGE_NAME:latest` and `IMAGE_NAME:<commit-sha>` |

Tagging with the commit SHA (not just `latest`) means the exact image deployed later can always be traced back to a specific commit.

### 3. `deploy`

**Depends on:** `test`, `build-and-push`

This job connects to the EC2 instance and performs the actual deployment. Steps run in this order:

| Step | What it does |
|---|---|
| Checkout code | Pulls the repo (needed for the `scripts/` folder) |
| Configure AWS credentials | Authenticates the AWS CLI for this job |
| Get EC2 Instance IP | Looks up the running instance's public IP by its `Name` tag, fails the job if the instance isn't running |
| Copy scripts to EC2 | Copies `scripts/*` (via `scp`) onto the instance |
| Execute SSH commands | Runs `tag_stable.sh`, pulls the new image, replaces the running container |
| Application health check | Runs `health_check.sh`; triggers `rollback.sh` on failure |
| Send confirmation mail | Sends a summary email regardless of outcome |

---

## Deployment Scripts

Located in `scripts/` in the repo, copied onto EC2 before execution.

### `tag_stable.sh`
Runs **before** the new image is pulled. Finds the image currently in use by the running container (via `docker inspect`) and tags it `previous_stable` on DockerHub, so it exists as a fallback if the new deployment turns out to be broken. On a first-ever deploy (no container running yet), it exits cleanly without treating that as an error.

### `health_check.sh`
Runs **after** the new container has started. Polls `http://localhost:5000/health` up to 5 times, 5 seconds apart. Exits `0` if it ever gets a `200` response, or `1` if all attempts fail. Runs against `localhost` because the script executes directly on the EC2 instance, in the same session as the container — not from an external machine.

### `rollback.sh`
Only runs if `health_check.sh` reports failure. Pulls the `previous_stable` image, stops and removes the broken container, and starts a new one from the last known-good image.

---

## Rollback Mechanism

```
tag_stable.sh (snapshot current image)
      ↓
pull new image, replace running container
      ↓
health_check.sh (poll /health, 5 retries)
      ↓
   ┌──── success ────┐        ┌──── failure ────┐
   │  deploy stands   │        │  rollback.sh runs │
   │                  │        │  job marked failed │
   └──────────────────┘        └────────────────────┘
      ↓                                ↓
         Email notification sent either way
```

## Email Notifications

Sent via `dawidd6/action-send-mail`, using `if: always()` so it fires whether the deployment succeeded, failed, or was rolled back. The subject line and body both reflect `job.status` dynamically.

**Contents:**
- Success/failure status (with emoji)
- Commit SHA
- Author (`github.actor`)
- Branch
- Application URL
- Link to the GitHub Actions run

**Gmail setup required:**
1. Enable 2-Step Verification on the sending Gmail account
2. Generate an **App Password** (Google Account → Security → App Passwords)
3. Store the Gmail address as `EMAIL_USERNAME` and the generated app password as `EMAIL_APP_PASSWORD`


---

