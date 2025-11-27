#!usrbinenv python3
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
OUTPUT = REPO_ROOT  SCRIPT_DATES.md

# Adjust file globsextensions as needed
FILE_PATTERNS = [.sh, .bash, .py, .js]


def git_ls_files(pattern str) - list[str]
    result = subprocess.run(
        [git, ls-files, pattern],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        check=True,
    )
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def git_last_date(path str) - str
    result = subprocess.run(
        [
            git,
            log,
            -1,
            --date=short,
            --pretty=format%ad,
            --,
            path,
        ],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout.strip() or NA


def main() - None
    files list[str] = []
    for pattern in FILE_PATTERNS
        files.extend(git_ls_files(pattern))

    # de-dupe and sort for stable output
    files = sorted(set(files))

    lines list[str] = []
    lines.append(# Script Last Modified Dates)
    lines.append()
    lines.append( File  Last Commit Date )
    lines.append(------------------------)

    for f in files
        date = git_last_date(f)
        lines.append(f `{f}`  {date} )

    text = n.join(lines) + n

    # Only rewrite if changed (helps avoid no-op diffs when run locally)
    if OUTPUT.exists()
        old = OUTPUT.read_text(encoding=utf-8)
        if old == text
            print(SCRIPT_DATES.md is already up to date)
            return

    OUTPUT.write_text(text, encoding=utf-8)
    print(fWrote {OUTPUT})


if __name__ == __main__
    main()
