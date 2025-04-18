# Server VPN SSH Manager

This repository contains a script that manages SSH and VPN tunnels for connecting to remote servers securely. The script allows you to easily configure multiple server connections, establish SSH sessions, and optionally create VPN tunnels. It provides a flexible mechanism for managing server connections through SSH port forwarding, including the ability to handle existing processes using specific ports.

## Features

- **Multiple Server Configurations**: Easily define multiple server connections with individual configurations.
- **SSH Key Authentication**: Supports SSH key-based authentication for secure and automated logins.
- **Port Forwarding**: Configure local and remote ports for seamless communication between your local machine and remote services.
- **VPN Tunnel Support**: Automatically establishes a VPN tunnel to securely route traffic for specific services.
- **Process Management**: Automatically detects and kills processes using specified ports to avoid conflicts before establishing connections.
- **Dynamic Server Selection**: Choose from a list of predefined servers and configurations dynamically during runtime.

## Requirements

- **Expect**: This script is written in Expect, which automates interactions with command-line tools like SSH.
- **Unix-based System**: This script is intended to run on Unix-like systems (macOS, Linux). The use of `lsof` and other Unix utilities are required.
- **SSH**: Ensure SSH is set up on the system, and keys are properly configured for authentication.
- **VPN Configuration**: Optionally, a VPN server and related configuration can be provided to securely route traffic.

## How It Works

### Step 1: Configure Servers
The script uses an array to store the configuration details for multiple servers, including:
- **`host`**: The server's IP address.
- **`user`**: The SSH user.
- **`ssh_port`**: The SSH port (default `22`, customizable).
- **`remote_ip`** and **`remote_port`**: Internal services to be accessed.
- **`local_port`**: Local port for communication.
- **`ssh_key`**: Path to the private SSH key for authentication.
- **`vpn_tunnel`** (optional): Configuration to establish a VPN tunnel.

Example of server configuration:

```tcl
array set servers {
    1 {
        name "Server 1"
        host "2.3.1.2"
        user "username"
        ssh_port "22"
        remote_ip "10.10.0.1"
        remote_port "3306"
        local_port "8888"
        password "password_here"
        ssh_key "~/.ssh/key_path"
        vpn_tunnel {
            password "vpn_server_password"
            ssh_key "~/.ssh/vpn_key.key"
            local_port "1235"
            remote_ip "2.2.4.6"
            remote_port "3422"
            user "vpn_user"
            host "2.2.5.9"
            ssh_port "22"
        }
    }
}
