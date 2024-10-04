#!/bin/sh

# Function to mine a proof-of-work
mine() {
    difficulty_target=$1
    epoch_time=$(date +%s)
    nonce=0

    echo "Starting mining with epoch time: $epoch_time"
    echo "Difficulty Target: $difficulty_target leading zeros"

    while true; do
        input="${epoch_time}:${nonce}"
        # Compute double SHA256 hash
        hash=$(printf '%s' "${input}" | openssl dgst -sha256 -binary | openssl dgst -sha256 -hex)
        hash=${hash##*= }  # Extract hash from output
        hash=$(echo -n "$hash")  # Remove any trailing newline

        # Count the number of leading zeros using parameter expansion
        leading_zeros="${hash%%[!0]*}"
        leading_zeros_length=${#leading_zeros}

        if [ "$leading_zeros_length" -ge "$difficulty_target" ]; then
            echo "Proof of work found!"
            echo "Epoch Time: $epoch_time"
            echo "Nonce: $nonce"
            echo "Hash: $hash"
            echo "Proof: ${epoch_time}:${nonce}"
            echo "To verify the proof, run:"
            echo "./pow.sh verify ${epoch_time}:${nonce} $difficulty_target"
            break
        fi

        nonce=$((nonce + 1))
    done
}

# Function to verify the proof-of-work
verify() {
    proof=$1
    difficulty_target=$2
    TIME_LIMIT=600  # Default to 10 minutes

    # Split proof into epoch_time and nonce based on separator ":"
    epoch_time=${proof%%:*}
    nonce=${proof#*:}

    if [ -z "$epoch_time" ] || [ -z "$nonce" ] || [ "$epoch_time" = "$proof" ]; then
        echo "Invalid proof format. Expected format: epoch_time:nonce"
        exit 1
    fi

    # Check if the epoch time is within the allowed time window
    current_time=$(date +%s)
    time_difference=$((current_time - epoch_time))

    if [ "$time_difference" -gt "$TIME_LIMIT" ] || [ "$time_difference" -lt 0 ]; then
        echo "Proof of work is invalid due to epoch time being outside the allowed time window."
        exit 1
    fi

    # Reconstruct the input and compute the hash
    input="${epoch_time}:${nonce}"
    hash=$(printf '%s' "${input}" | openssl dgst -sha256 -binary | openssl dgst -sha256 -hex)
    hash=${hash##*= }  # Extract hash from output
    hash=$(echo -n "$hash")  # Remove any trailing newline

    # Count the number of leading zeros using parameter expansion
    leading_zeros="${hash%%[!0]*}"
    leading_zeros_length=${#leading_zeros}

    if [ -z "$difficulty_target" ]; then
        # Output the difficulty as the number of leading zeros
        echo "Proof of work verified."
        echo "Epoch Time: $epoch_time"
        echo "Nonce: $nonce"
        echo "Hash: $hash"
        echo "Difficulty (number of leading zeros): $leading_zeros_length"
    else
        if [ "$leading_zeros_length" -ge "$difficulty_target" ]; then
            echo "Proof of work is valid."
            echo "Epoch Time: $epoch_time"
            echo "Nonce: $nonce"
            echo "Hash: $hash"
        else
            echo "Proof of work is invalid."
            exit 1
        fi
    fi
}

# Main script logic to decide whether to mine or verify
if [ "$1" = "mine" ]; then
    # Mining mode: provide difficulty target as the second argument
    if [ -z "$2" ]; then
        echo "Usage: $0 mine <difficulty_target>"
        exit 1
    fi
    mine "$2"

elif [ "$1" = "verify" ]; then
    # Verification mode: provide proof and optional difficulty target
    if [ -z "$2" ]; then
        echo "Usage: $0 verify <proof> [difficulty_target]"
        exit 1
    fi
    verify "$2" "$3"

else
    echo "Usage: $0 <mine|verify> [arguments...]"
    exit 1
fi
