# Use an official Ubuntu as the base image
FROM ubuntu:latest

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV SCRIPT_DIR="/home/builduser/TollGateNostrToolKit"
ENV HOME="/home/builduser"

# Add all necessary tools and dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    git \
    wget \
    unzip \
    sudo \
    adduser \
    htop \
    && rm -rf /var/lib/apt/lists/*

# Create a user with sudo privileges
RUN useradd -m builduser && echo "builduser:builduser" | chpasswd && adduser builduser sudo

# Let the user switch to root temporarily if needed
RUN echo "builduser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/builduser

# Copy the current directory contents into the container at the expected location
COPY . $SCRIPT_DIR

# Ensure all scripts are executable
RUN chmod +x $SCRIPT_DIR/*.sh

# Set the owner of the directory to builduser
RUN chown -R builduser:builduser $SCRIPT_DIR

# Switch to the non-root user
USER builduser

# Set the working directory to the expected location
WORKDIR $SCRIPT_DIR

# Copy and add the spawn script
COPY spawn_build_in_container.sh $SCRIPT_DIR

# Make the spawn script executable
RUN chmod +x $SCRIPT_DIR/spawn_build_in_container.sh

# Set the default command to execute the spawn script
CMD ["./spawn_build_in_container.sh"]
