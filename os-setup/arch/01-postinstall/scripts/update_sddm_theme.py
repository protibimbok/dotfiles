#!/usr/bin/env python3
"""Update SDDM theme configuration.

Usage: update_sddm_theme.py <conf_path> <theme_name>

Checks if the theme is already set; if not, updates the config file.
"""

import pathlib
import sys


def update_sddm_theme(conf_path: pathlib.Path, theme: str) -> bool:
    """Update SDDM theme config. Returns True if file was changed."""
    if conf_path.exists():
        text = conf_path.read_text()
    else:
        text = ""

    lines = text.splitlines()
    if not lines:
        lines = ["[Theme]"]

    if not any(line.strip().lower() == "[theme]" for line in lines):
        lines.insert(0, "[Theme]")

    updated = False
    new_lines = []
    in_theme = False
    current_set = False

    for line in lines:
        stripped = line.strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            in_theme = stripped.lower() == "[theme]"
            new_lines.append(line)
            continue
        if in_theme and stripped.lower().startswith("current="):
            if stripped != f"Current={theme}":
                new_lines.append(f"Current={theme}")
                updated = True
            else:
                new_lines.append(line)
            current_set = True
        else:
            new_lines.append(line)

    if not current_set:
        # Find [Theme] section and insert after it
        for i, line in enumerate(new_lines):
            if line.strip().lower() == "[theme]":
                new_lines.insert(i + 1, f"Current={theme}")
                updated = True
                break
        else:
            new_lines.append(f"Current={theme}")
            updated = True

    if updated or not conf_path.exists():
        conf_path.parent.mkdir(parents=True, exist_ok=True)
        conf_path.write_text("\n".join(new_lines).rstrip() + "\n")
        print(f"updated: {conf_path}")
        return True

    print(f"unchanged: {conf_path}")
    return False


def main() -> None:
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <conf_path> <theme_name>", file=sys.stderr)
        sys.exit(1)

    conf_path = pathlib.Path(sys.argv[1])
    theme = sys.argv[2]
    update_sddm_theme(conf_path, theme)


if __name__ == "__main__":
    main()
