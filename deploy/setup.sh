#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_EXAMPLE="$SCRIPT_DIR/deploy.env.example"
ENV_FILE="$SCRIPT_DIR/deploy.env"
SERVICE_NAME="qsz-academic-deploy.service"
TIMER_NAME="qsz-academic-deploy.timer"
SERVICE_SRC="$SCRIPT_DIR/systemd/$SERVICE_NAME"
TIMER_SRC="$SCRIPT_DIR/systemd/$TIMER_NAME"
NGINX_SITE="/etc/nginx/sites-available/qsz-academic.conf"
NGINX_ENABLED="/etc/nginx/sites-enabled/qsz-academic.conf"

DOMAIN=""
WWW_DOMAIN=""
EMAIL=""
DEPLOY_USER=""
BRANCH=""
DEPLOY_ROOT="/var/www/qsz_academic"
TIMER_INTERVAL="2min"
SKIP_CERT=0

usage() {
  cat <<'EOF'
Usage:
  sudo bash deploy/setup.sh \
    --domain qinsizhong.com \
    --email you@example.com \
    [--www-domain www.qinsizhong.com] \
    [--deploy-user ubuntu] \
    [--branch main] \
    [--deploy-root /var/www/qsz_academic] \
    [--timer-interval 2min] \
    [--skip-cert]

Notes:
- Must be run as root (sudo).
- Domain DNS must already point to this server before requesting HTTPS cert.
EOF
}

log() {
  echo "[$(date '+%F %T')] $*"
}

die() {
  log "ERROR: $*"
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --domain)
      DOMAIN="${2:-}"
      shift 2
      ;;
    --www-domain)
      WWW_DOMAIN="${2:-}"
      shift 2
      ;;
    --email)
      EMAIL="${2:-}"
      shift 2
      ;;
    --deploy-user)
      DEPLOY_USER="${2:-}"
      shift 2
      ;;
    --branch)
      BRANCH="${2:-}"
      shift 2
      ;;
    --deploy-root)
      DEPLOY_ROOT="${2:-}"
      shift 2
      ;;
    --timer-interval)
      TIMER_INTERVAL="${2:-}"
      shift 2
      ;;
    --skip-cert)
      SKIP_CERT=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

[[ $EUID -eq 0 ]] || die "Please run as root with sudo"
[[ -n "$DOMAIN" ]] || die "--domain is required"
if [[ "$SKIP_CERT" -ne 1 ]]; then
  [[ -n "$EMAIL" ]] || die "--email is required unless --skip-cert is used"
fi

require_cmd sed
require_cmd awk
require_cmd tee
require_cmd systemctl
require_cmd nginx

if [[ -z "$DEPLOY_USER" ]]; then
  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    DEPLOY_USER="$SUDO_USER"
  else
    DEPLOY_USER="ubuntu"
  fi
fi

if ! id "$DEPLOY_USER" >/dev/null 2>&1; then
  die "deploy user does not exist: $DEPLOY_USER"
fi

if [[ -z "$WWW_DOMAIN" ]]; then
  WWW_DOMAIN="www.$DOMAIN"
fi

if [[ ! -f "$ENV_EXAMPLE" ]]; then
  die "missing env example: $ENV_EXAMPLE"
fi

log "Installing required packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y nginx certbot python3-certbot-nginx ruby-full build-essential zlib1g-dev nodejs npm git

gem install bundler --no-document

log "Preparing deploy env"
if [[ ! -f "$ENV_FILE" ]]; then
  cp "$ENV_EXAMPLE" "$ENV_FILE"
fi

if [[ -z "$BRANCH" ]]; then
  BRANCH="$(su - "$DEPLOY_USER" -c "cd '$REPO_DIR' && git symbolic-ref --quiet --short HEAD 2>/dev/null || echo main")"
fi

ensure_kv() {
  local key="$1"
  local value="$2"
  if grep -q "^${key}=" "$ENV_FILE"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
  else
    echo "${key}=${value}" >> "$ENV_FILE"
  fi
}

ensure_kv "BRANCH" "$BRANCH"
ensure_kv "REPO_DIR" "$REPO_DIR"
ensure_kv "DEPLOY_ROOT" "$DEPLOY_ROOT"
ensure_kv "JEKYLL_CONFIG" "_config.yml,_config_prod.yml"
ensure_kv "JEKYLL_ENV" "production"

log "Updating production config for domain"
if [[ -f "$REPO_DIR/_config_prod.yml" ]]; then
  if grep -q '^url:' "$REPO_DIR/_config_prod.yml"; then
    sed -i "s|^url:.*|url: \"https://$DOMAIN\"|" "$REPO_DIR/_config_prod.yml"
  else
    echo "url: \"https://$DOMAIN\"" >> "$REPO_DIR/_config_prod.yml"
  fi
  if grep -q '^baseurl:' "$REPO_DIR/_config_prod.yml"; then
    sed -i 's|^baseurl:.*|baseurl: ""|' "$REPO_DIR/_config_prod.yml"
  else
    echo 'baseurl: ""' >> "$REPO_DIR/_config_prod.yml"
  fi
else
  cat > "$REPO_DIR/_config_prod.yml" <<EOF
url: "https://$DOMAIN"
baseurl: ""
EOF
fi

log "Ensuring deploy root permissions"
mkdir -p "$DEPLOY_ROOT/releases"
chown -R "$DEPLOY_USER":"$DEPLOY_USER" "$DEPLOY_ROOT"

log "Installing systemd units"
install -m 0644 "$SERVICE_SRC" "/etc/systemd/system/$SERVICE_NAME"
install -m 0644 "$TIMER_SRC" "/etc/systemd/system/$TIMER_NAME"

sed -i "s|^User=.*|User=$DEPLOY_USER|" "/etc/systemd/system/$SERVICE_NAME"
sed -i "s|^WorkingDirectory=.*|WorkingDirectory=$REPO_DIR|" "/etc/systemd/system/$SERVICE_NAME"
sed -i "s|^ExecStart=.*|ExecStart=$REPO_DIR/deploy/deploy.sh|" "/etc/systemd/system/$SERVICE_NAME"
sed -i "s|^OnUnitActiveSec=.*|OnUnitActiveSec=$TIMER_INTERVAL|" "/etc/systemd/system/$TIMER_NAME"

systemctl daemon-reload
systemctl enable --now "$TIMER_NAME"

log "Creating nginx site config"
cat > "$NGINX_SITE" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN $WWW_DOMAIN;

    root $DEPLOY_ROOT/current;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~* \\.(css|js|jpg|jpeg|png|gif|ico|svg|webp|ttf|otf|woff|woff2)$ {
        expires 7d;
        add_header Cache-Control "public, max-age=604800, immutable";
        try_files \$uri =404;
    }

    error_page 404 /404.html;
}
EOF

ln -sfn "$NGINX_SITE" "$NGINX_ENABLED"
nginx -t
systemctl reload nginx

log "Running initial deployment"
su - "$DEPLOY_USER" -c "cd '$REPO_DIR' && bash deploy/deploy.sh"

if [[ "$SKIP_CERT" -eq 1 ]]; then
  log "Skipping cert issuance (--skip-cert used). Site is available on HTTP only."
else
  log "Issuing HTTPS certificate via certbot"
  certbot --nginx -d "$DOMAIN" -d "$WWW_DOMAIN" -m "$EMAIL" --agree-tos --no-eff-email --redirect -n
  systemctl enable --now certbot.timer >/dev/null 2>&1 || true
fi

log "Done. Deployment + auto-update + HTTPS configuration completed."
