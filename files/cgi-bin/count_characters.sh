#!/bin/bash

# Function to count characters in a string
count_characters() {
    local input_string="$1"
    local length=${#input_string}
    echo "The number of characters in the string is: $length"
}

# Read input string from the user
echo "Enter a string:"
read input_string

# Call the function with the input string
count_characters "$input_string"
