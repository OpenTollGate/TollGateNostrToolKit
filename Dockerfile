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

RUN apt-get update && apt-get install -y htop

# Create a user with sudo privileges
RUN useradd -m builduser && echo "builduser:builduser" | chpasswd && adduser builduser sudo

# Copy application code
COPY . /app

# Set permissions and ownerships
RUN chmod +x /app/*.sh && chown -R builduser:builduser /app

# Let the user switch to root temporarily if needed
RUN echo "builduser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/builduser

# Switch to the non-root user
USER builduser

# Set the working directory
WORKDIR /app

# Set the default command to execute your build process
CMD ["./build_coordinator.sh"]
