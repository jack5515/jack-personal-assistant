#!/usr/bin/env python3
"""
Search and optionally download Pexels photos for deck / PPT workflows.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime
from pathlib import Path


API_BASE = "https://api.pexels.com/v1"
DEFAULT_VARIANT = "large2x"
WORKSPACE_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT_ROOT = WORKSPACE_ROOT / "media" / "pexels"


def resolve_api_key() -> str:
    key = os.environ.get("PEXELS_API_KEY", "").strip()
    if key:
        return key
    try:
        result = subprocess.run(
            ["launchctl", "getenv", "PEXELS_API_KEY"],
            check=False,
            capture_output=True,
            text=True,
        )
    except Exception:
        result = None
    if result and result.returncode == 0:
        key = result.stdout.strip()
        if key:
            return key
    raise SystemExit("PEXELS_API_KEY is not available in the current runtime.")


def api_get(path: str, params: dict[str, str | int | None], api_key: str) -> dict:
    query = urllib.parse.urlencode({k: v for k, v in params.items() if v not in (None, "")})
    url = f"{API_BASE}{path}"
    if query:
        url = f"{url}?{query}"
    request = urllib.request.Request(
        url,
        headers={
            "Authorization": api_key,
            "Accept": "application/json",
            "User-Agent": "jyxc-pexels-search/1.0 (+local-openclaw-deck-workflow)",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="ignore")
        try:
            payload = json.loads(body)
            error_text = payload.get("error") or payload.get("message") or body
        except Exception:
            error_text = body or str(exc)
        raise SystemExit(f"Pexels API request failed: {error_text}") from exc


def slugify(text: str, max_len: int = 48) -> str:
    normalized = re.sub(r"\s+", "-", text.strip().lower())
    normalized = re.sub(r"[^a-z0-9\u4e00-\u9fff_-]", "", normalized)
    normalized = normalized.strip("-_")
    return normalized[:max_len] or "image"


def choose_src(photo: dict, variant: str) -> str:
    src = photo.get("src") or {}
    return (
        src.get(variant)
        or src.get(DEFAULT_VARIANT)
        or src.get("large")
        or src.get("medium")
        or src.get("original")
        or ""
    )


def output_dir_for_download(query: str, explicit_dir: str | None) -> Path:
    if explicit_dir:
        path = Path(explicit_dir).expanduser().resolve()
        path.mkdir(parents=True, exist_ok=True)
        return path
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    path = DEFAULT_OUTPUT_ROOT / f"{stamp}-{slugify(query, 32)}"
    path.mkdir(parents=True, exist_ok=True)
    return path


def extension_from_url(url: str) -> str:
    parsed = urllib.parse.urlparse(url)
    suffix = Path(parsed.path).suffix.lower()
    return suffix if suffix in {".jpg", ".jpeg", ".png", ".webp"} else ".jpg"


def download_file(url: str, output_path: Path) -> None:
    request = urllib.request.Request(url, headers={"User-Agent": "jyxc-pexels-search/1.0"})
    with urllib.request.urlopen(request, timeout=120) as response:
        output_path.write_bytes(response.read())


def compact_photo(photo: dict, variant: str) -> dict:
    src = photo.get("src") or {}
    return {
        "id": photo.get("id"),
        "width": photo.get("width"),
        "height": photo.get("height"),
        "alt": photo.get("alt") or "",
        "avg_color": photo.get("avg_color"),
        "photographer": photo.get("photographer"),
        "photographer_url": photo.get("photographer_url"),
        "page_url": photo.get("url"),
        "src": {
            "original": src.get("original"),
            "large2x": src.get("large2x"),
            "large": src.get("large"),
            "medium": src.get("medium"),
            "chosen": choose_src(photo, variant),
        },
    }


def maybe_download(
    photos: list[dict],
    query: str,
    variant: str,
    download_top: int,
    download_ids: list[int],
    output_dir: str | None,
) -> list[dict]:
    if download_top <= 0 and not download_ids:
        return []

    targets: list[dict] = []
    selected_ids = {int(photo_id) for photo_id in download_ids}
    for index, photo in enumerate(photos, start=1):
        if download_top > 0 and index <= download_top:
            targets.append(photo)
            continue
        if int(photo.get("id", 0) or 0) in selected_ids:
            targets.append(photo)

    deduped: list[dict] = []
    seen: set[int] = set()
    for photo in targets:
        photo_id = int(photo.get("id", 0) or 0)
        if photo_id and photo_id not in seen:
            deduped.append(photo)
            seen.add(photo_id)

    if not deduped:
        return []

    destination = output_dir_for_download(query, output_dir)
    downloaded: list[dict] = []
    for index, photo in enumerate(deduped, start=1):
        photo_id = int(photo.get("id", 0) or 0)
        src_url = choose_src(photo, variant)
        if not src_url:
            continue
        base_name = f"{index:02d}-{photo_id}-{slugify(photo.get('alt') or query)}{extension_from_url(src_url)}"
        path = destination / base_name
        download_file(src_url, path)
        downloaded.append(
            {
                "id": photo_id,
                "path": str(path),
                "variant": variant,
                "photographer": photo.get("photographer"),
                "page_url": photo.get("url"),
            }
        )

    meta_path = destination / "_pexels-results.json"
    meta_path.write_text(
        json.dumps(
            {
                "query": query,
                "downloaded_at": datetime.now().isoformat(),
                "downloaded": downloaded,
            },
            ensure_ascii=False,
            indent=2,
        ),
        encoding="utf-8",
    )
    return downloaded


def format_text(result: dict) -> str:
    lines = [
        "Pexels search completed.",
        f"query: {result['query']}",
        f"results: {len(result['photos'])}",
    ]
    for index, photo in enumerate(result["photos"], start=1):
        dims = f"{photo['width']}x{photo['height']}" if photo["width"] and photo["height"] else "unknown"
        title = photo["alt"] or "untitled"
        lines.append(
            f"{index}. [{photo['id']}] {title} | {photo['photographer']} | {dims}"
        )
        lines.append(f"   chosen: {photo['src']['chosen']}")
    if result["downloaded"]:
        lines.append("downloaded:")
        for item in result["downloaded"]:
            lines.append(f"- {item['path']}")
    return "\n".join(lines)


def parse_download_ids(raw: str) -> list[int]:
    if not raw.strip():
        return []
    values: list[int] = []
    for token in raw.split(","):
        token = token.strip()
        if not token:
            continue
        values.append(int(token))
    return values


def main() -> int:
    parser = argparse.ArgumentParser(description="Search and optionally download Pexels photos.")
    parser.add_argument("--query", required=True, help="Photo search query")
    parser.add_argument("--per-page", type=int, default=6, help="Number of results to fetch")
    parser.add_argument("--page", type=int, default=1, help="Page number")
    parser.add_argument("--orientation", choices=["landscape", "portrait", "square"], default="")
    parser.add_argument("--size", choices=["large", "medium", "small"], default="")
    parser.add_argument("--color", default="", help="Optional color filter")
    parser.add_argument("--locale", default="zh-CN", help="Locale, default zh-CN")
    parser.add_argument("--download-top", type=int, default=0, help="Download top N results")
    parser.add_argument("--download-ids", default="", help="Comma-separated photo ids to download")
    parser.add_argument("--output-dir", default="", help="Directory for downloaded images")
    parser.add_argument("--variant", default=DEFAULT_VARIANT, help="Image variant such as large2x or original")
    parser.add_argument("--json", action="store_true", help="Return JSON instead of text")
    args = parser.parse_args()

    api_key = resolve_api_key()
    payload = api_get(
        "/search",
        {
            "query": args.query,
            "per_page": min(max(args.per_page, 1), 15),
            "page": max(args.page, 1),
            "orientation": args.orientation or None,
            "size": args.size or None,
            "color": args.color or None,
            "locale": args.locale or None,
        },
        api_key,
    )

    photos = [compact_photo(photo, args.variant) for photo in payload.get("photos", [])]
    downloaded = maybe_download(
        payload.get("photos", []),
        query=args.query,
        variant=args.variant,
        download_top=max(args.download_top, 0),
        download_ids=parse_download_ids(args.download_ids),
        output_dir=args.output_dir or None,
    )
    result = {
        "query": args.query,
        "page": payload.get("page"),
        "per_page": payload.get("per_page"),
        "total_results": payload.get("total_results"),
        "next_page": payload.get("next_page"),
        "photos": photos,
        "downloaded": downloaded,
    }
    if args.json:
        print(json.dumps(result, ensure_ascii=False))
    else:
        print(format_text(result))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
