#!/bin/bash
echo "Content-type: text/html"
echo ""

# Parse query string
IFS='&' read -ra PARAMS <<< "$QUERY_STRING"
for param in "${PARAMS[@]}"; do
    IFS='=' read -ra PAIR <<< "$param"
    if [[ ${PAIR[0]} == "bitcoin_payment" ]]; then
        PAYMENT="${PAIR[1]}"
    elif [[ ${PAIR[0]} == "tok" ]]; then
        TOKEN="${PAIR[1]}"
    elif [[ ${PAIR[0]} == "redir" ]]; then
        REDIR="${PAIR[1]}"
    fi
done

# Here you would add logic to validate the payment
# For now, we'll assume all payments are valid
PAYMENT_VALID=true

if [ "$PAYMENT_VALID" = true ]; then
    # Payment is valid, authorize the client
    # Replace ROUTER_IP with the IP of your OpenNDS router
    AUTH_RESULT=$(curl "http://ROUTER_IP:2050/opennds_auth/?token=$TOKEN")
    
    echo "<html><body>"
    echo "<h1>Payment Accepted</h1>"
    echo "<p>Bitcoin Payment: $PAYMENT</p>"
    echo "<p>You are now authorized. You will be redirected shortly.</p>"
    echo "<script>setTimeout(function() { window.location = '$REDIR'; }, 5000);</script>"
    echo "</body></html>"
else
    echo "<html><body>"
    echo "<h1>Payment Failed</h1>"
    echo "<p>Your payment could not be validated. Please try again.</p>"
    echo "</body></html>"
fi