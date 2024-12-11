#!/bin/bash

curl -s https://raw.githubusercontent.com/CryptoBureau01/logo/main/logo.sh | bash
sleep 5

# Function to print info messages
print_info() {
    echo -e "\e[32m[INFO] $1\e[0m"
}

# Function to print error messages
print_error() {
    echo -e "\e[31m[ERROR] $1\e[0m"
}




folder_path="/root/brinx"
file_path="$folder_path/data-brinx.txt"


# Function to install dependencies
install_dependency(){

    print_info "<=========== Install Dependency ==============>"
    print_info "Updating and upgrading system packages, and installing curl..."

    # Update and install dependencies
    if ! sudo apt update && sudo apt upgrade -y && sudo apt install git ufw wget curl -y; then
        print_error "Failed to update/upgrade or install basic dependencies."
        exit 1
    fi

    # Check if Docker is already installed
    if ! command -v docker &> /dev/null; then
        print_info "Docker is not installed. Installing Docker..."
        
        # Install Docker
        if ! sudo apt install docker.io -y; then
            print_error "Failed to install Docker. Please check your system for issues."
            exit 1
        fi
    else
        print_info "Docker is already installed."
    fi

    # Check if Docker Compose is installed and install it if missing
    if ! command -v docker-compose &> /dev/null; then
        print_info "Docker Compose is not installed. Installing Docker Compose..."
        
        # Install Docker Compose
        if ! sudo apt install docker-compose -y; then
            print_error "Failed to install Docker Compose. Please check your system for issues."
            exit 1
        fi
    else
        print_info "Docker Compose is already installed."
    fi

    print_info "All dependencies installed successfully."

    # Enable UFW firewall
    print_info "Enabling UFW firewall..."
    sudo ufw enable

    # Allow port 1194/udp for VPN or other services
    print_info "Allowing port 1194/udp..."
    sudo ufw allow 1194/udp
    sudo ufw allow 1194/tcp

    print_info "UFW firewall enabled and port 1194/udp allowed."

    # Call the master function to display the menu
    master
}



new_user() {
    print_info "<=========== Setting Up Brinx Relay Node for New User ==============>"

    folder_path="/root/brinx"
    file_path="$folder_path/data-brinx.txt"

    # Prompt the user to enter a new node name
    read -p "Enter your new Node Name: " new_node_name

    # Check if the brinx folder exists, create if not
    if [ ! -d "$folder_path" ]; then
        print_info "Creating new /root/brinx folder..."
        mkdir -p "$folder_path"
    fi

    # Save the new node name to the file
    echo "$new_node_name" > "$file_path"
    print_info "Node name saved to data-brinx.txt: $new_node_name"

    # Run the Docker container with the new node name
    print_info "Starting a new Docker container with the name: $new_node_name..."
    if ! sudo docker run -d --name "$new_node_name" --cap-add=NET_ADMIN -p 1194:1194/udp admier/brinxai_nodes-relay:latest; then
        print_error "Failed to run the BrinxAI relay Docker container with name $new_node_name. Please check Docker setup or image availability."
        exit 1
    fi

    print_info "BrinxAI relay node is running successfully with the name: $new_node_name."
}




run_relay() {
    # Define folder and file paths
    folder_path="/root/brinx"
    file_path="$folder_path/data-brinx.txt"

    print_info "<=========== Running Brinx Relay Node ==============>"

    # Check if the node name is already set in data-brinx.txt
    if [ -f "$file_path" ]; then
        node_name=$(cat "$file_path") # Read the node name from the file
        print_info "Node name already set: $node_name"

        # Replace name for old user call function
        print_info "You have already registered this ID address in the node!"

    else
        # Call new user function to set a new name
        new_user
        
        # The new user function will handle saving the name, so no need to do it here
    fi

    # Call the master function or next step if needed
    master
}



check_logs() {
    print_info "<=========== Checking Logs for Brinx Relay Node ==============>"
    
    # Define the path to the data-brinx.txt file
    file_path="/root/brinx/data-brinx.txt"

    # Check if the data-brinx.txt file exists
    if [ -f "$file_path" ]; then
        # Read the node name from the file
        node_name=$(cat "$file_path")
    else
        print_error "The data-brinx.txt file does not exist. Please run the setup first."
        exit 1
    fi

    # Check if the BrinxAI relay container is running with the retrieved name
    if sudo docker ps --filter "name=$node_name" --format '{{.Names}}' | grep -q "$node_name"; then
        print_info "BrinxAI relay node '$node_name' is running. Fetching logs..."
        
        # Fetch and display the logs
        sudo docker logs "$node_name" --tail 100 -f
    else
        print_error "BrinxAI relay node '$node_name' is not running. Please make sure the container is started."
    fi

    # Call the master function or next step if needed
    master
}


refresh() {
    print_info "Please wait ... "
    sudo docker restart brinxai_relay
    echo "Node Restart Successfully!"
}
    


register_node() {
    print_info "<=========== Register Your Relay Node ==============>"
    print_info ""
    print_info "1. Go to workers.brinxai.com."
    print_info ""
    print_info "2. Create an account using your email and password."
    print_info ""
    print_info "3. Log in to your account."

    # Fetch the IP address
    user_ip=$(hostname -I | awk '{print $1}') # Get the first IP address

    print_info "4. Your IP address is: $user_ip."
    print_info ""
    print_info "   Alternatively, you can find your IP address by visiting What Is My IP Address or using the 'ifconfig' command in the terminal."

    # Read the node name from the data-brinx.txt file
    file_path="/root/brinx/data-brinx.txt"
    
    if [ -f "$file_path" ]; then
        node_name=$(cat "$file_path")
    else
        node_name="YourNodeName"  # Default name if file doesn't exist
    fi

    print_info "5. Enter your Node Name: $node_name and $user_ip in the Worker Dashboard and click 'Add Node'."
    print_info ""
    print_info "-------------------------------------------------------"
    print_info "Ensure you follow these steps carefully to register your relay node successfully."
    
    # Call the master function or next step if needed
    master
}


# Function to stop and remove the Docker container
delete() {
    folder_path="/root/brinx"

    print_info "Please wait ... "
    sudo docker stop brinxai_relay

    sleep 1

    print_info "Please wait ... "
    sudo docker rm brinxai_relay

    sleep 1

    print_info "Please wait ... "
    rm -rf $folder_path
    
    echo "Docker container 'brinxai_relay' has been stopped and removed."
}


# Function to display menu and prompt user for input
master() {
    print_info "==============================="
    print_info "    BrinxAi-Relay Node Tool Menu    "
    print_info "==============================="
    print_info ""
    print_info "1. Install-Dependency"
    print_info "2. Setup-Node"
    print_info "3. Logs-Checker"
    print_info "4. Refresh-Node"
    print_info "5. Register-Your-Relay-Node"
    print_info "6. Delete-Node"
    print_info "7. Exit"
    print_info ""
    print_info "==============================="
    print_info " Created By : CryptoBuroMaster "
    print_info "==============================="
    print_info ""
    
    read -p "Enter your choice (1 or 4): " user_choice

    case $user_choice in
        1)
            install_dependency
            ;;
        2)
            run_relay
            ;;
        3) 
            check_logs
            ;;
        4)
            refresh
            ;;
        5)
            register_node
            ;;
        6)
            delete
            ;;
        7)
            exit 0  # Exit the script after breaking the loop
            ;;
        *)
            print_error "Invalid choice. Please enter 1 or 4 : "
            ;;
    esac
}

# Call the master function to display the menu
master


