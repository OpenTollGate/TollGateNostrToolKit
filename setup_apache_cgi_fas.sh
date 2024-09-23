#!/bin/bash

# Exit on any error
set -e

# Variables
USERNAME=$(whoami)
DOMAIN="helsinki.orangesync.tech"
CGI_SCRIPT="bitcoin-fas.cgi"

# Function to print steps
print_step() {
    echo "----------------------------------------------------"
    echo "Step: $1"
    echo "----------------------------------------------------"
}

# Install Apache if not already installed
print_step "Installing Apache"
sudo apt update
sudo apt install -y apache2

# Enable necessary Apache modules
print_step "Enabling Apache modules"
sudo a2enmod cgi

# Create CGI directory if it doesn't exist
print_step "Creating CGI directory"
mkdir -p ~/cgi-bin

# Create or update the CGI script
print_step "Creating CGI script"
cat << EOF > ~/cgi-bin/$CGI_SCRIPT
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
    <form method="GET" action="/cgi-bin/bitcoin_auth.cgi">
        <label for="bitcoin_payment">Enter Bitcoin Payment String:</label><br>
        <input type="text" id="bitcoin_payment" name="bitcoin_payment" required><br>
        <input type="submit" value="Submit Payment">
    </form>
</body>
</html>
HTML
EOF

# Set correct permissions
print_step "Setting permissions"
chmod 755 ~/cgi-bin/$CGI_SCRIPT
sudo chmod o+x /home /home/$USERNAME
sudo chmod 755 /home/$USERNAME/cgi-bin

# Create Apache configuration
print_step "Creating Apache configuration"
sudo tee /etc/apache2/sites-available/$DOMAIN.conf > /dev/null << EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html

    <Directory "/home/$USERNAME/cgi-bin">
        Options +ExecCGI
        AddHandler cgi-script .cgi
        Require all granted
    </Directory>

    ScriptAlias /cgi-bin/ /home/$USERNAME/cgi-bin/

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# Enable the new site and disable the default
print_step "Enabling new site and disabling default"
sudo a2ensite $DOMAIN.conf
sudo a2dissite 000-default.conf

# Restart Apache
print_step "Restarting Apache"
sudo systemctl restart apache2

print_step "Setup complete!"
echo "You can now access your CGI script at: http://$DOMAIN/cgi-bin/$CGI_SCRIPT"
echo "Make sure your domain's DNS is properly configured to point to this server."
