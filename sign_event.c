#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

// Include uBitcoin headers
#include "Bitcoin.h"
#include "Conversion.h"
#include "Hash.h"
#include "BitcoinCurve.h"

// Utility function to fill a buffer with random bytes
int fill_random(unsigned char *buf, size_t len) {
    FILE *fp = fopen("/dev/urandom", "rb");
    if (!fp) {
        return 0;
    }
    size_t read_len = fread(buf, 1, len, fp);
    fclose(fp);
    if (read_len != len) {
        return 0;
    }
    return 1;
}

// Utility function to print a byte array as hex
void print_hex(const unsigned char *data, size_t len) {
    for (size_t i = 0; i < len; i++) {
        printf("%02x", data[i]);
    }
    printf("\n");
}

// Utility function to securely erase a buffer
void secure_erase(unsigned char *buf, size_t len) {
    memset(buf, 0, len);
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <message_hash> <private_key_hex>\n", argv[0]);
        return 1;
    }

    uint8_t msg_hash[32];
    uint8_t seckey[32];
    uint8_t signature[64];
    uint8_t auxiliary_rand[32];
    int return_val;

    // Convert the message hash and secret key from hex to binary
    for (int i = 0; i < 32; i++) {
        sscanf(&argv[1][2 * i], "%2hhx", &msg_hash[i]);
        sscanf(&argv[2][2 * i], "%2hhx", &seckey[i]);
    }

    // Initialize Bitcoin context
    BitcoinContext ctx;
    ctx.init();

    // Create keypair from the secret key
    Keypair keypair;
    if (!keypair.setPrivKey(seckey)) {
        fprintf(stderr, "Failed to create keypair\n");
        return 1;
    }

    // Generate auxiliary randomness for signing
    if (!fill_random(auxiliary_rand, sizeof(auxiliary_rand))) {
        fprintf(stderr, "Failed to generate randomness\n");
        return 1;
    }

    // Generate a Schnorr signature
    if (!keypair.signSchnorr(signature, msg_hash, auxiliary_rand)) {
        fprintf(stderr, "Failed to sign message\n");
        return 1;
    }

    // Print the signature as a hex string
    print_hex(signature, sizeof(signature));

    // Securely erase the secret key
    secure_erase(seckey, sizeof(seckey));
    return 0;
}

