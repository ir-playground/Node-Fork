# BuildSpec Configuration Instructions

This document provides instructions for modifying the `buildspec.yml` file to integrate PSE (Proxy Security Engine) startup and cleanup scripts into the build pipeline.

## Prerequisites

Ensure the `API_URL` environment variable is set in your CodeBuild project environment variables before applying these changes.

## Modifying `buildspec.yml`

### 1. `pre_build` Phase

In the `pre_build` phase, under the `commands` section, add the following lines **after** any existing setup commands (e.g., dependency installation):

```yaml
pre_build:
  commands:
    # ... existing commands ...
    - curl $API_URL/pse/bitbucket-setup/pse_startup | bash
    - . /etc/profile.d/pse-proxy.sh
```

- `curl $API_URL/pse/bitbucket-setup/pse_startup | bash` — Downloads and executes the PSE startup script using the `API_URL` environment variable.
- `. /etc/profile.d/pse-proxy.sh` — Sources the PSE proxy environment configuration so that subsequent build commands route traffic through the proxy.

### 2. `post_build` Phase

In the `post_build` phase, under the `commands` section, add the following line:

```yaml
post_build:
  commands:
    # ... existing commands ...
    - bash /tmp/pse_cleanup/cleanup.sh
```

- `bash /tmp/pse_cleanup/cleanup.sh` — Runs the PSE cleanup script to remove any proxy artifacts or temporary files created during the build.

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

- The `API_URL` variable must be configured as an environment variable in your CodeBuild project settings, or passed via the pipeline.
- The PSE proxy startup must complete before the `build` phase so that all network traffic during dependency installation is routed correctly.
- The cleanup script in `post_build` should always run, even if the build fails. Consider using a `finally` block or setting `run-as` appropriately if guaranteed execution is required.
