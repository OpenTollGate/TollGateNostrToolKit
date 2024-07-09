#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include <secp256k1.h>
#include <secp256k1_extrakeys.h>
#include <secp256k1_schnorrsig.h>

// Utility function to fill a buffer with random bytes
int fill_random(unsigned char *buf, size_t len) {
    FILE *fp = fopen("/dev/urandom", "rb");
    if (!fp) {
        return 0;
    }
    fread(buf, 1, len, fp);
    fclose(fp);
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

    unsigned char msg_hash[32];
    unsigned char seckey[32];
    unsigned char signature[64];
    unsigned char auxiliary_rand[32];
    int return_val;
    secp256k1_keypair keypair;

    // Convert the message hash and secret key from hex to binary
    for (int i = 0; i < 32; i++) {
        sscanf(&argv[1][2 * i], "%2hhx", &msg_hash[i]);
        sscanf(&argv[2][2 * i], "%2hhx", &seckey[i]);
    }

    // Create a context for signing and verification
    secp256k1_context* ctx = secp256k1_context_create(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY);

    // Randomizing the context (here we use the message hash as randomization data)
    return_val = secp256k1_context_randomize(ctx, msg_hash);
    assert(return_val);

    // Create keypair from the secret key
    if (!secp256k1_keypair_create(ctx, &keypair, seckey)) {
        fprintf(stderr, "Failed to create keypair\n");
        secp256k1_context_destroy(ctx);
        return 1;
    }

    // Generate auxiliary randomness for signing
    if (!fill_random(auxiliary_rand, sizeof(auxiliary_rand))) {
        fprintf(stderr, "Failed to generate randomness\n");
        secp256k1_context_destroy(ctx);
        return 1;
    }

    // Generate a Schnorr signature
    if (!secp256k1_schnorrsig_sign32(ctx, signature, msg_hash, &keypair, auxiliary_rand)) {
        fprintf(stderr, "Failed to sign message\n");
        secp256k1_context_destroy(ctx);
        return 1;
    }

    // Print the signature as a hex string
    print_hex(signature, sizeof(signature));

    // Clear everything from the context and free the memory
    secp256k1_context_destroy(ctx);

    // Securely erase the secret key
    secure_erase(seckey, sizeof(seckey));
    return 0;
}

