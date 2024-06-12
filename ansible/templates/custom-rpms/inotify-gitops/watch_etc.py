{% raw %}
#!/usr/bin/env python3

import requests
import os
import subprocess
import time
import sys
import inotify.adapters

def source_environment(file_path):
    """Read and set environment variables from a file."""
    with open(file_path) as f:
        for line in f:
            if line.strip() and not line.startswith('#'):
                key, value = line.strip().split('=', 1)
                os.environ[key] = value

# Source environment variables from /etc/environment
source_environment('/etc/environment')

print(f"Waiting 15 secs...")

time.sleep(15)

# Define the directory to monitor
DIRECTORY = '/etc'

# Retrieve the eda_ip and eda_webhook_port environment variables
eda_ip = os.environ.get('eda_ip')
eda_webhook_port = os.environ.get('eda_port')
git_user= os.environ.get('git_user')
running_env= os.environ.get('running_env')

WEBHOOK_URL = "http://{}:{}".format(eda_ip, eda_webhook_port)

# Debug prints
print(f"eda_ip: {eda_ip}")
print(f"eda_webhook_port: {eda_webhook_port}")
print(f"git_user: {git_user}")
print(f"running_env: {running_env}")
print(f"WEBHOOK_URL: {WEBHOOK_URL}")

# Function to send a webhook with JSON data
def send_webhook(path, filename, event_type, user, inventory, running_env):
    json_data = {
        "user": user,
        "inventory": inventory,
        "path": path,
        "file_changed": filename,
        "event_type": event_type,
        "running_env": running_env
    }

    headers = {'Content-Type': 'application/json'}
    response = requests.post(WEBHOOK_URL, json=json_data, headers=headers)
    if response.status_code == 200:
        print(f'Webhook sent: {filename}')

# Check if the "/root/inotify-wait" file exists
def inotify_wait_exists():
    return os.path.exists('/root/inotify-wait')

try:
    conn_name = subprocess.check_output("nmcli con show | grep -v UUID | head -n 1 | awk '{{print $1}}'", shell=True)
    conn_name = conn_name.decode("utf-8").strip()
except subprocess.CalledProcessError as e:
    print(f"Error running the first shell command: {e}")
    conn_name = None

# Check if the connection name was retrieved successfully
if conn_name:
    # Run the second shell command to get the MAC address
    try:
        MAC_ADDRESS = subprocess.check_output(f"ip addr | grep {conn_name} -A 1 | grep link | awk '{{print $2}}' | sed 's/://g'", shell=True)
        MAC_ADDRESS = MAC_ADDRESS.decode("utf-8").strip()
    except subprocess.CalledProcessError as e:
        print(f"Error running the second shell command: {e}")
        MAC_ADDRESS = None

# Check if both variables are available
if conn_name and MAC_ADDRESS:
    inventory = f'edge-{MAC_ADDRESS}'

# Initialize the inotify watcher
i = inotify.adapters.InotifyTree(DIRECTORY)

for event in i.event_gen(yield_nones=False):
      (_, type_names, path, filename) = event
      # Check the file extension and skip unwanted extensions
      _, file_extension = os.path.splitext(filename)

      if file_extension not in ('.swp', '.swpx', '.ddf', '.db'):
        if '/etc/containers' not in path or '/etc/cni' not in path:
            #print("variable: {}".format(type_names))
            if any(event_type in ['IN_CREATE', 'IN_MODIFY', 'IN_DELETE', 'IN_MOVE'] for event_type in type_names):
                print("PATH=[{}] FILENAME=[{}] EVENT_TYPES={}".format(path, filename, type_names))
                # Check if the "/root/inotify-wait" file exists
                if not inotify_wait_exists():
                    # Send a webhook notification with JSON data
                    send_webhook(path, filename, type_names, git_user, inventory, running_env )
                    # Create the "/root/inotify-wait" file
                    open('/root/inotify-wait', 'w').close()

i.remove_watch(DIRECTORY)
{% endraw %}