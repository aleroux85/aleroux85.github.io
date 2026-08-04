#!/bin/sh
# Generate ui/dist/sitemap.xml from the pages that are actually built.
#
# The URL list is derived from the source files, not hand-maintained: every
# candidate page is included unless its source declares a robots `noindex`
# tag. New articles therefore appear automatically, and noindexed pages
# (bom, unlog) are excluded without a second list to keep in sync.
#
# `lastmod` is each file's last git commit date, falling back to its
# filesystem mtime and then today. Accurate git dates require full history,
# so the production build checks out with fetch-depth: 0.
#
# Invoked by `make prd` only — the staging build ships no sitemap.
set -eu

BASE="https://anroleroux.co.za"
OUT="ui/dist/sitemap.xml"

# Map a source file to its production path (relative to BASE).
url_path() {
  case "$1" in
    ui/home.html)    echo "/" ;;
    ui/contact.html) echo "/contact.html" ;;
    ui/articles/*)   echo "/$(basename "$1")" ;;
  esac
}

# Priority by page role.
priority() {
  case "$1" in
    ui/home.html)    echo "1.0" ;;
    ui/contact.html) echo "0.5" ;;
    *)               echo "0.8" ;;
  esac
}

changefreq() {
  case "$1" in
    ui/contact.html) echo "yearly" ;;
    *)               echo "monthly" ;;
  esac
}

# Last-modified date: git commit date, else file mtime, else today (UTC).
lastmod() {
  d=$(git log -1 --format=%cs -- "$1" 2>/dev/null || true)
  [ -z "$d" ] && d=$(date -u -r "$1" +%F 2>/dev/null || true)
  [ -z "$d" ] && d=$(date -u +%F)
  echo "$d"
}

{
  echo '<?xml version="1.0" encoding="UTF-8"?>'
  echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
  for f in ui/home.html ui/contact.html ui/articles/*.html; do
    [ -f "$f" ] || continue
    # Skip pages that opt out of indexing.
    grep -qi 'name="robots"[^>]*noindex' "$f" && continue
    printf '  <url>\n'
    printf '    <loc>%s%s</loc>\n' "$BASE" "$(url_path "$f")"
    printf '    <lastmod>%s</lastmod>\n' "$(lastmod "$f")"
    printf '    <changefreq>%s</changefreq>\n' "$(changefreq "$f")"
    printf '    <priority>%s</priority>\n' "$(priority "$f")"
    printf '  </url>\n'
  done
  echo '</urlset>'
} > "$OUT"

echo "Generated $OUT"
