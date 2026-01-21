#!/usr/bin/env python3
import sys
import os
import re
import glob

def update_nginx_configs(old_version, new_version):
    nginx_sites_path = os.environ.get('NGINX_SITES_PATH', "/etc/nginx/sites-available")
    if not os.path.exists(nginx_sites_path):
        print(f"Nginx sites directory not found at {nginx_sites_path}. Skipping Nginx config update.")
        return False

    old_sock_pattern = f"php{old_version}-fpm.sock"
    new_sock_pattern = f"php{new_version}-fpm.sock"
    
    files_updated = False
    
    # Iterate over all files in sites-available
    for config_file in glob.glob(os.path.join(nginx_sites_path, "*")):
        if not os.path.isfile(config_file):
            continue
            
        try:
            with open(config_file, 'r') as f:
                content = f.read()
            
            # Check if the file contains the old socket
            if old_sock_pattern in content:
                print(f"Updating {config_file}...")
                new_content = content.replace(old_sock_pattern, new_sock_pattern)
                
                with open(config_file, 'w') as f:
                    f.write(new_content)
                
                files_updated = True
                print(f"  Changed {old_sock_pattern} to {new_sock_pattern}")
                
        except Exception as e:
            print(f"Error processing {config_file}: {e}")

    return files_updated

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: update_nginx_php.py <old_version> <new_version>")
        sys.exit(1)

    old_version = sys.argv[1]
    new_version = sys.argv[2]

    print(f"Checking Nginx configurations for PHP upgrade from {old_version} to {new_version}...")
    
    if update_nginx_configs(old_version, new_version):
        print("Nginx configurations updated.")
        sys.exit(0) # 0 indicates success/changes made might be useful, but caller logic relies on this for now just to run.
    else:
        print("No Nginx configurations needed updating.")
        sys.exit(0)
