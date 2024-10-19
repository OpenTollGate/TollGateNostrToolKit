<?php
// captive_portal.php

// Include Cashu SDK (adjust the path as necessary)
// require_once 'vendor/autoload.php'; // Composer autoload

// Assuming you have a CashuClient class from the SDK
// use Cashu\CashuClient;

// Initialize Cashu client (if needed)
// $cashu = new CashuClient([
//     'api_key' => 'YOUR_CASHU_API_KEY', // Replace with your Cashu API key
//     'api_secret' => 'YOUR_CASHU_API_SECRET', // Replace with your Cashu API secret
//     // Add other necessary configurations
// ]);

// Ensure the script is being accessed via OpenNDS
if (!isset($_ENV['REMOTE_ADDR'])) {
    http_response_code(403);
    echo json_encode(['status' => 'error', 'message' => 'Access denied']);
    exit;
}

// Get the client's IP address
$client_ip = $_ENV['REMOTE_ADDR'];

// Handle POST requests
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';

    switch ($action) {
        case 'authorize':
            authorizeClient($client_ip);
            break;
        case 'status':
            getClientStatus($client_ip);
            break;
        case 'pay':
            processPayment($client_ip);
            break;
        case 'redeem_token':
            redeemToken($client_ip);
            break;
        default:
            echo json_encode(['status' => 'error', 'message' => 'Invalid action']);
    }
    exit;
}

// Default response
echo json_encode(['status' => 'ok', 'ip' => $client_ip]);
exit;

// Function to authorize a client
function authorizeClient($ip) {
    exec("/usr/lib/opennds/ndsctl auth $ip", $output, $return_var);
    if ($return_var === 0) {
        echo json_encode(['status' => 'authorized']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Authorization failed']);
    }
}

// Function to get client status
function getClientStatus($ip) {
    exec("/usr/lib/opennds/ndsctl status $ip", $output, $return_var);
    if ($return_var === 0 && !empty($output)) {
        echo json_encode(['status' => 'online', 'details' => $output]);
    } else {
        echo json_encode(['status' => 'offline']);
    }
}

// Function to process Cashu payment (placeholder, if needed)
function processPayment($ip) {
    // Implement payment processing if required
    echo json_encode(['status' => 'error', 'message' => 'Payment processing not implemented']);
}

// Function to redeem Cashu token
function redeemToken($ip) {
    $token = $_POST['token'] ?? '';
    $recipient_lnurl = $_POST['lnurl'] ?? '';

    if (empty($token) || empty($recipient_lnurl)) {
        echo json_encode(['status' => 'error', 'message' => 'Token and LNURL are required']);
        return;
    }

    try {
        // Decode the token
        $token_data = decodeToken($token);

        // Generate MINT_URL and LNURL
        list($mint_url, $lnurl) = generateUrls($recipient_lnurl);

        // Calculate total amount
        $total_amount = calculateTotalAmount($token_data);

        // Interact with the mint and LNURL
        $payment_request = getPaymentRequest($lnurl, $total_amount);
        redeemTokenWithMint($mint_url, $token_data, $payment_request, $total_amount);

        // Authorize the client upon successful redemption
        authorizeClient($ip);

        echo json_encode(['status' => 'success', 'message' => 'Token redeemed and client authorized']);
    } catch (Exception $e) {
        echo json_encode(['status' => 'error', 'message' => 'Error redeeming token', 'details' => $e->getMessage()]);
    }
}

// Helper function to decode the token
function decodeToken($token) {
    // Remove 'cashuA' prefix
    if (strpos($token, 'cashuA') !== 0) {
        throw new Exception('Invalid token prefix');
    }
    $base64_token = substr($token, 6);

    // Base64 decode
    $decoded_json = base64_decode($base64_token, true);
    if ($decoded_json === false) {
        throw new Exception('Invalid Base64 encoding in token');
    }

    // JSON decode
    $token_data = json_decode($decoded_json, true);
    if ($token_data === null) {
        throw new Exception('Invalid JSON in token');
    }

    return $token_data;
}

// Helper function to generate MINT_URL and LNURL
function generateUrls($recipient_lnurl) {
    // Extract username and domain
    if (!strpos($recipient_lnurl, '@')) {
        throw new Exception('Invalid LNURL format');
    }
    list($username, $domain) = explode('@', $recipient_lnurl);

    // Map domain to mint URL
    $mint_url = mapDomainToMint($domain);

    // Construct LNURL
    $lnurl = "https://$domain/.well-known/lnurlp/$username";

    return [$mint_url, $lnurl];
}

// Helper function to map domain to mint URL
function mapDomainToMint($domain) {
    switch ($domain) {
        case 'minibits.cash':
        case 'nimo.cash':
            return "https://mint.$domain/Bitcoin";
        case '8333.space':
            return "https://$domain";
        case 'umint.cash':
            return "https://stablenut.$domain";
        default:
            // Default to mint subdomain if unknown
            return "https://mint.$domain/Bitcoin";
    }
}

// Helper function to calculate total amount
function calculateTotalAmount($token_data) {
    $total_amount = 0;
    foreach ($token_data['token'][0]['proofs'] as $proof) {
        $total_amount += $proof['amount'];
    }
    return $total_amount;
}

// Helper function to get payment request
function getPaymentRequest($lnurl, $total_amount) {
    // Convert amount to millisats
    $amount_msat = $total_amount * 1000;

    // Fetch payment request details
    $lnurl_response = file_get_contents("$lnurl?amount=$amount_msat");
    if ($lnurl_response === false) {
        throw new Exception('Failed to fetch payment request from LNURL');
    }

    $lnurl_data = json_decode($lnurl_response, true);
    if (!isset($lnurl_data['pr'])) {
        throw new Exception('Invalid LNURL response');
    }

    return $lnurl_data['pr'];
}

// Helper function to redeem token with mint
function redeemTokenWithMint($mint_url, $token_data, $payment_request, $total_amount) {
    $proofs = $token_data['token'][0]['proofs'];

    // Prepare data for the melt request
    $postData = [
        'pr' => $payment_request,
        'proofs' => $proofs,
        'outputs' => [],
        'paid_amount' => $total_amount,
    ];

    // Make the melt request
    $ch = curl_init("$mint_url/melt");
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($postData));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
    ]);

    $response = curl_exec($ch);
    if ($response === false) {
        throw new Exception('CURL error: ' . curl_error($ch));
    }

    $http_status = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($http_status !== 200) {
        throw new Exception("Mint returned HTTP status $http_status: $response");
    }

    $response_data = json_decode($response, true);
    if ($response_data === null) {
        throw new Exception('Invalid response from mint');
    }

    // Check for errors in the response
    if (isset($response_data['error'])) {
        throw new Exception('Mint error: ' . $response_data['error']);
    }

    // Optionally, you can process the response_data further if needed
}

// Additional helper functions for interacting with the mint (if needed)
function getMintKeys($mint_url) {
    $response = file_get_contents("$mint_url/keys");
    if ($response === false) {
        throw new Exception('Failed to fetch mint keys');
    }
    $keys = json_decode($response, true);
    if ($keys === null) {
        throw new Exception('Invalid mint keys response');
    }
    return $keys;
}

function checkFees($mint_url, $payment_request) {
    $postData = ['pr' => $payment_request];

    $ch = curl_init("$mint_url/checkfees");
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($postData));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
    ]);

    $response = curl_exec($ch);
    if ($response === false) {
        throw new Exception('CURL error: ' . curl_error($ch));
    }

    $http_status = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($http_status !== 200) {
        throw new Exception("Mint returned HTTP status $http_status: $response");
    }

    $response_data = json_decode($response, true);
    if ($response_data === null) {
        throw new Exception('Invalid response from mint');
    }

    if (isset($response_data['fee'])) {
        return $response_data['fee'];
    } else {
        throw new Exception('Fee information not available');
    }
}

function checkToken($mint_url, $proofs) {
    $postData = ['proofs' => array_map(function($proof) {
        return ['secret' => $proof['secret']];
    }, $proofs)];

    $ch = curl_init("$mint_url/check");
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($postData));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
    ]);

    $response = curl_exec($ch);
    if ($response === false) {
        throw new Exception('CURL error: ' . curl_error($ch));
    }

    $http_status = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($http_status !== 200) {
        throw new Exception("Mint returned HTTP status $http_status: $response");
    }

    $response_data = json_decode($response, true);
    if ($response_data === null) {
        throw new Exception('Invalid response from mint');
    }

    // You can process response_data to check the validity of proofs
    return $response_data;
}
