#!/usr/bin/env python3
"""
Enable PHP extensions in php.ini by uncommenting them.
"""

import sys
import re


EXTENSIONS_TO_ENABLE = [
    'mysqli',
    'pdo_mysql',
    'curl',
    'zip',
    'gd',
    'intl',
    'sqlite3',
    'pdo_sqlite',
]


def enable_extensions(filepath: str) -> None:
    with open(filepath, 'r') as f:
        content = f.read()

    enabled = []
    already_enabled = []

    for ext in EXTENSIONS_TO_ENABLE:
        # Pattern to match commented extension line
        pattern = rf'^;(extension={ext})\s*$'
        
        if re.search(pattern, content, re.MULTILINE):
            content = re.sub(pattern, r'\1', content, flags=re.MULTILINE)
            enabled.append(ext)
        elif re.search(rf'^extension={ext}\s*$', content, re.MULTILINE):
            already_enabled.append(ext)

    with open(filepath, 'w') as f:
        f.write(content)

    if enabled:
        print(f"Enabled extensions: {', '.join(enabled)}")
    if already_enabled:
        print(f"Already enabled: {', '.join(already_enabled)}")


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <php.ini path>")
        sys.exit(1)
    
    enable_extensions(sys.argv[1])
