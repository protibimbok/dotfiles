#!/usr/bin/env python3
"""
Update phpMyAdmin config.inc.php to allow no password authentication.
"""

import sys
import re


def update_phpmyadmin_config(config_path):
    """
    Update phpMyAdmin config to allow no password.
    If AllowNoPassword line exists (even if commented), update/uncomment it.
    Otherwise, insert it after the host definition.
    """
    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        new_line = "$cfg['Servers'][$i]['AllowNoPassword'] = true;\n"
        pattern = re.compile(r"^[#;\/ ]*\$cfg\['Servers'\]\[\$i\]\['AllowNoPassword'\]")
        host_pattern = re.compile(r"\$cfg\['Servers'\]\[\$i\]\['host'\]")
        
        # Check if AllowNoPassword line exists
        found_allow_no_password = False
        for i, line in enumerate(lines):
            if pattern.match(line):
                # Replace the existing line (even if commented)
                lines[i] = new_line
                found_allow_no_password = True
                break
        
        # If not found, insert after host definition
        if not found_allow_no_password:
            for i, line in enumerate(lines):
                if host_pattern.search(line):
                    # Insert after this line
                    lines.insert(i + 1, new_line)
                    break
        
        with open(config_path, 'w', encoding='utf-8') as f:
            f.writelines(lines)
            
    except Exception as e:
        print(f"Error updating phpMyAdmin config: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: update_phpmyadmin_config.py <config_path>", file=sys.stderr)
        sys.exit(1)
    
    update_phpmyadmin_config(sys.argv[1])

