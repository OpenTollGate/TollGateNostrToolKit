#!/bin/sh

echo "Content-type: text/html"
echo ""

cat << HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Bitcoin Payment</title>
</head>
<body>
    <h1>Bitcoin Payment Portal</h1>
    <form method="GET" action="/cgi-bin/bitcoin-auth-opennds.cgi">
        <label for="bitcoin_payment">Enter Bitcoin Payment String:</label><br>
        <input type="text" id="bitcoin_payment" name="bitcoin_payment" required><br>
        <input type="submit" value="Submit Payment">
    </form>
</body>
</html>
HTML
