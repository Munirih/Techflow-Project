# Techflow App

## Table of Contents
- [Running The App Locally](./Documentation/running_app_locally.md)
- [Creating a Dockerfile](./Documentation/create_dockerfile.md)
- [Provisioning AWS Infrastructure](./Documentation/aws_infrastructure.md)
- [CI/CD Workflow](./Documentation/workflow.md)

---

## Tech Stack

- GitHub Actions
- Docker
- DockerHub
- AWS
- GMAIL SMTP
- Bash Scripting

---

## Project Structure

```text
Techflow-project/
├── .github/workflows
│   └── pipeline.yml
├── Documentation/
│   ├──Images/
│   ├── image-1.png
│   └── image.png
│   ├── aws_infrastructure.md
│   ├── running_app_locally.py
│   └── workflow.md
├── scripts/
│   ├── health_check.sh
│   ├── rollback.sh
│   └── tag_stable.sh
├── .dockerignore
├── .gitignore
├── app.py 
├── Dockerfile
├── README.md
├── requirements.txt
└── test_app.py
```
---

## Live Application

![live app](./Documentation/images/image-1.png)