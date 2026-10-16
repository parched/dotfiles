has() { command -v "$1" >/dev/null 2>&1; }

fetch() {
  local url="$1"
  if has curl; then
    curl -fsSL "$url"
  elif has wget; then
    wget -qO- "$url"
  else
    echo "To continue, install curl or wget." >&2
    return 1
  fi
}
