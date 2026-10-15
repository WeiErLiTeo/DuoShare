#!/usr/bin/env python3
"""Download checked anime GIF sources into ./image and switch README links to local files."""
from pathlib import Path
from urllib.request import Request, urlopen
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
README = ROOT / "README.md"
IMAGE_DIR = ROOT / "image"
USER_AGENT = "Mozilla/5.0 (compatible; DuoShareAnimeGifMirror/1.0; +https://github.com/WeiErLiTeo/DuoShare)"

# Every URL below was taken from a live Tenor GIF page or the linked public GitHub GIF collection.
ASSETS = [
    ("violet-evergarden.gif", "https://media1.tenor.com/m/T9RtbdMBUOgAAAAd/violet-evergarden.gif"),
    ("frieren.gif", "https://media1.tenor.com/m/B7nG9UfpJE4AAAAd/frieren-anime.gif"),
    ("fern.gif", "https://media1.tenor.com/m/VI_QvzG5jWsAAAAd/fern-fern-frieren.gif"),
    ("rem.gif", "https://media1.tenor.com/m/6CrIknBZoY8AAAAd/rem.gif"),
    ("ram.gif", "https://media1.tenor.com/m/pmnx4wxHw94AAAAd/ram-rezero-ram-re-zero.gif"),
    ("rem-ram.gif", "https://media1.tenor.com/m/V4ochBF1P9gAAAAd/rem-ram.gif"),
    ("bocchi-the-rock.gif", "https://media1.tenor.com/m/CmSjEaLL3vEAAAAd/bocchi-the-rock.gif"),
    ("hatsune-miku.gif", "https://media1.tenor.com/m/mK1_fyk9_YIAAAAd/anime-hatsune-miku.gif"),
    ("marin-kitagawa.gif", "https://media1.tenor.com/m/2_obEvGek24AAAAd/marin-kitagawa.gif"),
    ("anya-forger.gif", "https://media1.tenor.com/m/BncuCq2Z9GAAAAAd/anya-forger-anya.gif"),
    ("chika-fujiwara.gif", "https://media1.tenor.com/m/vjmRKtrLcMoAAAAd/chika-fujiwara.gif"),
    ("nezuko.gif", "https://media1.tenor.com/m/xPH19hU9w8cAAAAd/nezuko.gif"),
]


def download(url: str, destination: Path) -> bool:
    try:
        request = Request(url, headers={"User-Agent": USER_AGENT, "Accept": "image/gif,*/*;q=0.8"})
        with urlopen(request, timeout=45) as response:
            data = response.read(20 * 1024 * 1024 + 1)
        if len(data) > 20 * 1024 * 1024:
            print(f"SKIP: {url} exceeds 20 MiB", file=sys.stderr)
            return False
        if not (data.startswith(b"GIF87a") or data.startswith(b"GIF89a")):
            print(f"SKIP: response is not a GIF: {url}", file=sys.stderr)
            return False
        destination.write_bytes(data)
        return True
    except Exception as exc:  # keep remote URL as a fallback if one provider is unavailable
        print(f"WARN: could not mirror {url}: {exc}", file=sys.stderr)
        return False


def main() -> int:
    if not README.exists():
        print("README.md not found", file=sys.stderr)
        return 2
    IMAGE_DIR.mkdir(parents=True, exist_ok=True)
    readme_text = README.read_text(encoding="utf-8")
    mirrored = []
    for filename, url in ASSETS:
        local = IMAGE_DIR / filename
        if local.exists() and local.stat().st_size > 6:
            ok = local.read_bytes()[:6] in (b"GIF87a", b"GIF89a")
        else:
            ok = download(url, local)
        if ok:
            readme_text = readme_text.replace(url, f"./image/{filename}")
            mirrored.append(filename)
    README.write_text(readme_text, encoding="utf-8")
    print(f"Mirrored {len(mirrored)}/{len(ASSETS)} GIFs.")
    print("README image links now point to local files for every successfully mirrored GIF.")
    print("Any failed download stays linked to its original hosted GIF.")
    return 0 if mirrored else 1


if __name__ == "__main__":
    raise SystemExit(main())
