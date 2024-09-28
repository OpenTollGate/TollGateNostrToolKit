#!/bin/bash
echo "Content-type: text/html"
echo ""

# Parse query string
IFS='=' read -ra PARAMS <<< "$QUERY_STRING"
PAYMENT="${PARAMS[1]}"

echo "<html><body>"
echo "<h1>Payment Received</h1>"
echo "<p>Bitcoin Payment: $PAYMENT</p>"
echo "<p>Auth successful. You should be redirected to the internet shortly.</p>"
echo "</body></html>"

# Here you would add logic to validate the payment and authorize the client
