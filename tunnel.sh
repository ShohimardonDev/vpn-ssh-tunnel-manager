#!/usr/bin/expect

# Define servers and their configurations
array set servers {
    1 {
        name "Server name"
        host "2.3.1.2"          # IP of the main server to SSH into
        user "username"         # SSH user to log in with
        ssh_port "22"           # SSH port (default 22 in this case)
        remote_ip "10.10.0.1"   # Internal IP of a service the server will connect to
        remote_port "1234"      # Port of the remote service (e.g., MySQL)
        local_port "1234"       # Local port for communication
        password "password_here" # Password for SSH authentication (not recommended for production)
        ssh_key "~/.ssh/key_path"  # Path to the SSH private key for authentication (recommended)

        vpn_tunnel {            # optional VPN configuration
            password "vpn_server_password"  # VPN password (for VPN authentication)
            ssh_key "~/.ssh/vpn_key.key"  # SSH key for VPN authentication
            local_port "1235"             # Local port for VPN tunnel
            remote_ip "2.2.4.6"          # Remote VPN gateway IP
            remote_port "3422"           # Remote VPN gateway port
            user "username"              # VPN user
            host "2.2.5.9"               # VPN host IP
            ssh_port "22"                # VPN SSH port
        }
    }
}


# Set common variables
set timeout -1

# Procedure to establish background VPN tunnel

# Set trap to clean up on exit (SIGINT or SIGTERM)
#trap cleanup_vpn SIGINT SIGTERM
#trap cleanup_vpn SIGINT SIGTERM EXIT

#signal trap SIGINT cleanup_vpn
#signal trap SIGTERM cleanup_vpn
proc kill_processes_using_port {local_port} {
    puts "Checking for existing processes using port $local_port..."
    set found_processes 0

    # Try lsof first (works on macOS and many Unix systems)
    if {[catch {
        set existing_pids [exec lsof -i tcp:$local_port -t 2>/dev/null]
        if {[string length $existing_pids] > 0} {
            set found_processes 1

            # Get more detailed information about the processes
            set process_details [exec lsof -i tcp:$local_port 2>/dev/null]
            puts "Found the following processes using port $local_port:"
            puts "$process_details"

            # Ask for confirmation
            puts -nonewline "Do you want to kill these processes? (y/n): "
            flush stdout
            gets stdin answer

            if {[string tolower $answer] == "y" || [string tolower $answer] == "yes"} {
                foreach pid [split $existing_pids "\n"] {
                    if {[string length $pid] > 0} {
                        puts "Killing process PID $pid"
                        exec kill -9 $pid
                    }
                }
                puts "Processes terminated."
            } else {
                puts "Operation cancelled. Port $local_port remains in use."
                return 0
            }
        } else {
            puts "No processes found using port $local_port."
        }
    } err]} {
        puts "lsof command failed: $err"
    }

    # Verify the port is now available
    if {![catch {socket -server {} $local_port} sock]} {
        close $sock
        puts "Port $local_port is now available."
        return 1
    } else {
        puts "Port $local_port is still in use."
        return 0
    }
}

#trap cleanup SIGINT SIGTERM EXIT
proc establish_vpn_tunnel {host user ssh_port local_port remote_ip remote_port ssh_key password} {
    global vpn_pid
    kill_processes_using_port $local_port
    spawn ssh -i $ssh_key -L $local_port:$remote_ip:$remote_port $user@$host -p $ssh_port -N -f
    set vpn_pid [pid $spawn_id]
    expect {
        "Enter passphrase for key" {
            send "$password\r"
            exp_continue
        }
        "password:" {
            send "$password\r"
            exp_continue
        }
        default {
            # No further interaction; let it run in background
        }
    }
}
# Display detailed menu
puts "\nAvailable Servers:"
puts "=================="

# Collect all IDs and sort them numerically, filtering out non-integer keys
set keys [array names servers]
set integer_keys [lsearch -all -inline -regexp $keys {^\d+$}]
set sorted_ids [lsort -integer $integer_keys]

# Debug: Print all keys for verification
puts "Debug: All server keys: [array names servers]"
puts "Debug: Integer keys: $integer_keys"

# Iterate over sorted IDs and print details, checking for required keys
foreach id $sorted_ids {
    if {![dict exists $servers($id) name]} {
        puts "\n$id. Server Details: (Invalid or missing configuration)"
        continue
    }
    puts "\n$id. Server Details:"
    puts "   - Name: [dict get $servers($id) name]"
    puts "   - Host: [dict get $servers($id) host]"
    puts "   - User: [dict get $servers($id) user]"
    puts "   - Port: [dict get $servers($id) ssh_port]"
    puts "   - Local Port: [dict get $servers($id) local_port]"
    puts "   - VPN Tunnel: [expr {[dict exists $servers($id) vpn_tunnel] ? "Enabled" : "Disabled"}]"
}

# Get user choice
puts -nonewline "\nEnter server number (1-[array size servers]): "
flush stdout
gets stdin choice

# Validate choice
if {![info exists servers($choice)]} {
    puts "Invalid selection. Exiting."
    exit 1
}

# Get selected server configuration
set selected_server $servers($choice)
set host [dict get $selected_server host]
set user [dict get $selected_server user]
set ssh_port [dict get $selected_server ssh_port]
set remote_ip [dict get $selected_server remote_ip]
set remote_port [dict get $selected_server remote_port]
set local_port [dict get $selected_server local_port]
set password [dict get $selected_server password]
set ssh_key [dict get $selected_server ssh_key]

# Display connection details
puts "\nConnecting with these details:"
puts "=============================="
puts "Server Name: [dict get $selected_server name]"
puts "Username: $user"
puts "Host: $host"
puts "SSH Port: $ssh_port"
puts "Local Port: $local_port -> Remote Port: $remote_port"
puts "\nEstablishing connection...\n"

# Check for VPN tunnel and establish it in the background if present
if {[dict exists $selected_server vpn_tunnel]} {
    puts "\nStarting VPN tunnel in background..."
    set vpn_config [dict get $selected_server vpn_tunnel]
    set vpn_host [dict get $vpn_config host]
    set vpn_user [dict get $vpn_config user]
    set vpn_ssh_port [dict get $vpn_config ssh_port]
    set vpn_remote_ip [dict get $vpn_config remote_ip]
    set vpn_remote_port [dict get $vpn_config remote_port]
    set vpn_local_port [dict get $vpn_config local_port]
    set vpn_password [dict get $vpn_config password]
    set vpn_ssh_key [dict get $vpn_config ssh_key]

    establish_vpn_tunnel $vpn_host $vpn_user $vpn_ssh_port $vpn_local_port \
        $vpn_remote_ip $vpn_remote_port $vpn_ssh_key $vpn_password
    puts "VPN tunnel started in background."
}
# Procedure to kill processes using a specific port

kill_processes_using_port $local_port


# Spawn the SSH command with port forwarding
spawn ssh -i $ssh_key -L $local_port:$remote_ip:$remote_port $user@$host -p $ssh_port

# Handle different possible prompts
expect {
    "Enter passphrase for key" {
        send "$password\r"
        exp_continue
    }
    "password:" {
        send "$password\r"
        exp_continue
    }
    "Permission denied" {
        puts "\nError: Permission denied. Please check your SSH key and permissions."
        exit 1
    }
    "Connection refused" {
        puts "\nError: Connection refused. Please check if the server is accessible."
        exit 1
    }
    timeout {
        puts "\nError: Connection timed out."
        exit 1
    }
    eof {
        puts "\nError: Connection failed."
        exit 1
    }
    "Last login:" {
        # Successfully connected
    }
}

# Interact with the SSH session if needed
interact
