# Use an official Ubuntu as the base image
FROM ubuntu:latest

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Add all necessary tools and dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    git \
    wget \
    unzip \
    sudo \
    adduser \
    && rm -rf /var/lib/apt/lists/*

apt-get update && apt-get install -y htop
htop

# Create a user (e.g., builduser) with sudo privileges
RUN useradd -m builduser && echo "builduser:builduser" | chpasswd && adduser builduser sudo

# Copy the current directory contents into the container at /app
COPY . /app

# Ensure all scripts have the necessary permissions
RUN chmod +x /app/*.sh

# Set the owner of the /app directory to builduser
RUN chown -R builduser:builduser /app

# Switch to the non-root user
USER builduser

# Set the working directory inside the container
WORKDIR /app

# Set the default command to execute your build process
CMD ["./build_coordinator.sh"]
