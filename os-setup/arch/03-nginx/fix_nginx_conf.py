#!/usr/bin/env python3
"""
Fix nginx.conf for Arch Linux to include sites-enabled inside http block.
Comments out any sites-enabled include outside http block and adds it inside.
"""

import sys
import re


def fix_nginx_conf(filepath: str) -> None:
    with open(filepath, 'r') as f:
        lines = f.readlines()

    include_directive = '    include /etc/nginx/sites-enabled/*;\n'
    include_pattern = re.compile(r'^\s*include\s+/etc/nginx/sites-enabled/\*\s*;')
    
    # Track brace depth and http block position
    in_http_block = False
    brace_depth = 0
    http_start_depth = 0
    http_closing_line = -1
    include_found_in_http = False
    includes_outside_http = []
    
    # First pass: find http block boundaries and existing includes
    for i, line in enumerate(lines):
        stripped = line.strip()
        
        # Count braces
        brace_depth += line.count('{')
        brace_depth -= line.count('}')
        
        # Detect http block start
        if re.match(r'^http\s*\{', stripped) or (stripped == 'http' and i + 1 < len(lines) and '{' in lines[i + 1]):
            in_http_block = True
            http_start_depth = brace_depth
            continue
        
        if in_http_block:
            # Check for include inside http block
            if include_pattern.match(line):
                include_found_in_http = True
            
            # Check if we're closing the http block
            if brace_depth < http_start_depth:
                http_closing_line = i
                in_http_block = False
        else:
            # Check for include outside http block
            if include_pattern.match(line):
                includes_outside_http.append(i)

    # Second pass: modify the file
    result_lines = []
    for i, line in enumerate(lines):
        # Comment out includes outside http block
        if i in includes_outside_http:
            result_lines.append(f'# {line.rstrip()}  # Commented: was outside http block\n')
            continue
        
        # Add include before http block closing brace if not present
        if i == http_closing_line and not include_found_in_http:
            result_lines.append(include_directive)
        
        result_lines.append(line)

    # Write back
    with open(filepath, 'w') as f:
        f.writelines(result_lines)

    if includes_outside_http:
        print(f"Commented out {len(includes_outside_http)} include(s) outside http block")
    if not include_found_in_http and http_closing_line >= 0:
        print(f"Added sites-enabled include inside http block")
    elif include_found_in_http:
        print(f"sites-enabled include already exists inside http block")


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <nginx.conf path>")
        sys.exit(1)
    
    fix_nginx_conf(sys.argv[1])
