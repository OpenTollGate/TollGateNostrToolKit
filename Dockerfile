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
    # Add any other dependencies needed by your scripts
    && rm -rf /var/lib/apt/lists/*

# Copy the current directory contents into the container at /app
COPY . /app

# Set the working directory inside the container
WORKDIR /app

# Make sure all scripts are executable
RUN chmod +x *.sh

# Set the default command to execute your build process
CMD ["./build_coordinator.sh"]