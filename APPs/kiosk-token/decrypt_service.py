import subprocess
import os
import socket
from flask import Flask, request, jsonify, render_template

os.environ['PYTHONUNBUFFERED'] = '1'

app = Flask(__name__)


def get_host_ip():
  return os.getenv('HOST_IP')

@app.route('/decrypt', methods=['POST'])
def decrypt():
    token = request.json.get('token')

    print("Token received:", token)
    
    # Run the decryption command
    try:
        subprocess.run(["openssl", "enc", "-d", "-aes-256-cbc", "-in", "/usr/share/rhde_encrypted.tar", "-out", "/tmp/rhde.tar", "-pass", "stdin", "-pbkdf2"], input=token.encode(), check=True)
        # Run the shell scripts
        tar_process = subprocess.run(["tar", "xvf", "/tmp/rhde.tar"], capture_output=True, text=True)
        print("Extracting files output:", tar_process.stdout)
        if tar_process.returncode != 0:
            # If tar command fails, raise an exception
            raise Exception("Error extracting files from the decrypted archive")
        tar_internal_process = subprocess.run(["tar", "xvfz", "rhde/rhde-automation.tar.gz"], capture_output=True, text=True)
        print("Extracting files output:", tar_internal_process.stdout)
        if tar_internal_process.returncode != 0:
            # If tar command fails, raise an exception
            raise Exception("Error extracting files from the decrypted archive")
        # Add execute permissions to shell scripts
        subprocess.run(f'chmod +x rhde-automation/*.sh', shell=True)
        script_process = subprocess.run('find rhde-automation -type f -name "*.sh" -exec {} \;', shell=True, capture_output=True, text=True)
        print("Shell scripts output:", script_process.stdout)
        if script_process.returncode != 0:
            # If shell scripts fail, raise an exception
            raise Exception("Error running shell scripts")
   
        print("Executing post-success command...")
        subprocess.run(['touch', '/var/tmp/activation_done'])

        print("Returning success message...")
        # If decryption and execution were successful, return a success message
        return jsonify({"message": "Your service is now active"}), 200
    except subprocess.CalledProcessError as e:
        # If OpenSSL or tar command fails, return an error message
        return jsonify({"error": f"Error: {e.stderr.decode()}"}), 400
    except Exception as e:
        # If any other error occurs, return a generic error message
        return jsonify({"error": f"Unexpected error: {e}"}), 500


@app.route('/', methods=['GET'])
def serve_web_interface():
    # Get the host IP address
    host_ip = get_host_ip()
    # Render the HTML template with the host IP address
    return render_template('index.html', host_ip=host_ip)

if __name__ == '__main__':
    # Change directory to where index.html is located
    os.chdir('/usr/src/app/')
    app.run(host='0.0.0.0', port=8080)
