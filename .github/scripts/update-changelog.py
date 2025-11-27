#!/usr/bin/env python3
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
CHANGELOG_PATH = REPO_ROOT / "CHANGELOG.md"

START_MARKER = "<!-- AUTO-CHANGELOG:START -->"
END_MARKER = "<!-- AUTO-CHANGELOG:END -->"


def get_git_log() -> str:
    """
    Return formatted commits with dates to insert into the changelog.

    Format example:
    - 2025-11-27: Fix overlay lock handling (#123)
    """
    # Adjust pretty format to taste
    log_format = "%ad %h %s"
    result = subprocess.run(
        [
            "git",
            "log",
            "--date=short",           # YYYY-MM-DD
            f"--pretty=format:{log_format}",
        ],
        capture_output=True,
        text=True,
        check=True,
    )

    lines = []
    for line in result.stdout.splitlines():
        if not line.strip():
            continue
        date, rest = line.split(" ", 1)
        lines.append(f"- {date}: {rest}")

    return "\n".join(lines)


def main() -> None:
    if not CHANGELOG_PATH.exists():
        raise SystemExit(f"{CHANGELOG_PATH} does not exist")

    contents = CHANGELOG_PATH.read_text(encoding="utf-8")

    if START_MARKER not in contents or END_MARKER not in contents:
        raise SystemExit("Missing changelog markers in CHANGELOG.md")

    before, rest = contents.split(START_MARKER, 1)
    _, after = rest.split(END_MARKER, 1)

    new_block = get_git_log()

    new_contents = (
        before
        + START_MARKER
        + "\n\n"
        + new_block
        + "\n\n"
        + END_MARKER
        + after
    )

    if new_contents != contents:
        CHANGELOG_PATH.write_text(new_contents, encoding="utf-8")
        print("CHANGELOG.md updated")
    else:
        print("No changes to CHANGELOG.md")


if __name__ == "__main__":
    main()
