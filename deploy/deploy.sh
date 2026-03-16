#!/usr/bin/env bash
set -Eeuo pipefail

umask 022

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR_DEFAULT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE_DEFAULT="$SCRIPT_DIR/deploy.env"

if [[ -f "$ENV_FILE_DEFAULT" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE_DEFAULT"
fi

: "${REPO_DIR:=$REPO_DIR_DEFAULT}"
: "${BRANCH:=}"
: "${DEPLOY_ROOT:=/var/www/qsz_academic}"
: "${KEEP_RELEASES:=5}"
: "${JEKYLL_CONFIG:=_config.yml,_config_prod.yml}"
: "${JEKYLL_ENV:=production}"
: "${FORCE_DEPLOY:=0}"
: "${ALLOW_DIRTY_WORKTREE:=1}"

log() {
  echo "[$(date '+%F %T')] $*"
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "Missing required command: $1"
    exit 1
  fi
}

retry_cmd() {
  local max_attempts="$1"
  local sleep_seconds="$2"
  shift 2

  local attempt=1
  while true; do
    if "$@"; then
      return 0
    fi

    if (( attempt >= max_attempts )); then
      return 1
    fi

    log "Command failed (attempt ${attempt}/${max_attempts}): $*"
    sleep "$sleep_seconds"
    attempt=$((attempt + 1))
  done
}

exec 9>"/tmp/qsz-academic-deploy.lock"
if ! flock -n 9; then
  log "Another deployment is running. Exiting."
  exit 0
fi

require_cmd git
require_cmd bundle
require_cmd npm
require_cmd flock
require_cmd ln
require_cmd mkdir

mkdir -p "$DEPLOY_ROOT/releases"

cd "$REPO_DIR"

if [[ ! -d .git ]]; then
  log "REPO_DIR is not a git repository: $REPO_DIR"
  exit 1
fi

if [[ -z "$BRANCH" ]]; then
  BRANCH="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || echo main)"
fi

retry_cmd 3 5 git fetch origin "$BRANCH"

local_sha="$(git rev-parse HEAD)"
remote_sha="$(git rev-parse "origin/$BRANCH")"

if [[ "$FORCE_DEPLOY" != "1" && "$local_sha" == "$remote_sha" ]]; then
  log "No new commits on origin/$BRANCH. Nothing to deploy."
  exit 0
fi

if [[ "$ALLOW_DIRTY_WORKTREE" != "1" ]]; then
  if ! git diff --quiet || ! git diff --cached --quiet; then
    log "Repository has local uncommitted changes. Refusing to deploy."
    exit 1
  fi
fi

git checkout "$BRANCH"
retry_cmd 3 5 git pull --ff-only origin "$BRANCH"

log "Installing Ruby gems"
bundle config set --local path vendor/bundle
bundle install

log "Installing Node packages"
if [[ -f package-lock.json ]]; then
  npm ci
else
  npm install
fi

log "Building JS assets"
npm run build:js

release_id="$(date '+%Y%m%d%H%M%S')"
release_dir="$DEPLOY_ROOT/releases/$release_id"

log "Building Jekyll site into $release_dir"
JEKYLL_ENV="$JEKYLL_ENV" bundle exec jekyll build --config "$JEKYLL_CONFIG" --destination "$release_dir"

ln -sfn "$release_dir" "$DEPLOY_ROOT/current"
log "Switched current release to $release_dir"

# Keep latest releases only.
mapfile -t releases < <(ls -1dt "$DEPLOY_ROOT"/releases/* 2>/dev/null || true)
for ((i = KEEP_RELEASES; i < ${#releases[@]}; i++)); do
  rm -rf "${releases[$i]}"
done

log "Deployment finished successfully"
