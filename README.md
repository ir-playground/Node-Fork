# BuildSpec Configuration Instructions

This document provides instructions for modifying the `buildspec.yml` file to integrate InvisiRisk BAF startup and cleanup scripts into the AWS CodeBuild.

## Prerequisites

Ensure the `API_URL` and `APP_TOKEN` environment variable is set in your CodeBuild project environment variables before applying these changes.

## Modifying `buildspec.yml`

### 1. `pre_build` Phase

In the `pre_build` phase, under the `commands` section, add the following lines **after** any existing setup commands (e.g., dependency installation):

```yaml
pre_build:
  commands:
    - echo "InvisiRisk startup script..."
    - curl $API_URL/pse/bitbucket-setup/pse_startup | bash #Download the BAF setup script and execute it. 
    - . /etc/profile.d/pse-proxy.sh # Source the environment variables created by the setup script.
```

- `curl $API_URL/pse/bitbucket-setup/pse_startup | bash` — Downloads and executes the BAF startup script using the `API_URL` environment variable.
- `. /etc/profile.d/pse-proxy.sh` — Sources the BAF environment configuration so that subsequent build commands route traffic through the BAF.

### 2. `post_build` Phase

In the `post_build` phase, under the `commands` section, add the following line:

```yaml
post_build:
  commands:
    - echo "Build complete!"
    - bash /tmp/pse_cleanup/cleanup.sh #  script that also sends data to the InvisiRisk portal
```

- `bash /tmp/pse_cleanup/cleanup.sh` — Runs the BAF cleanup script to remove any BAF artifacts or temporary configuration created during the build and also sends data to the InvisiRisk portal.

## Example `buildspec.yml` After Changes

```yaml
version: 0.2

phases:
  pre_build:
    commands:
      - echo "Installing system dependencies..."
      - apt-get update
      - apt-get install -y build-essential curl git libssl-dev zlib1g-dev libyaml-dev libpq-dev
      - curl $API_URL/pse/bitbucket-setup/pse_startup | bash
      - . /etc/profile.d/pse-proxy.sh

  build:
    commands:
      - echo "Install dependencies..."
      - npm ci
      - npm run build --if-present

  post_build:
    commands:
      - echo "Build complete!"
      - bash /tmp/pse_cleanup/cleanup.sh
```

## Notes

- The `API_URL` and `APP_TOKEN` variable must be configured as an environment variable in your CodeBuild project settings, or passed via the pipeline.
- The BAF startup must complete before the `build` phase so that all network traffic during dependency installation is routed correctly.
- The cleanup script in `post_build` should always run, even if the build fails.
