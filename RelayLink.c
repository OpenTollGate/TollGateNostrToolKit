#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <libwebsockets.h>
#include <signal.h>
#include <regex.h>
#include <openssl/ssl.h>
#include <arpa/inet.h>


static struct lws_context *context;
static volatile int force_exit = 0;
static volatile int eose_received = 0; // Flag for EOSE
static volatile int event_published = 0; // Flag for event published

static const char *relay_url;
static const char *event_json;
static const char *public_key;

void sigint_handler(int sig) {
    force_exit = 1;
    lws_cancel_service(context);
}

static int callback_websockets(struct lws *wsi, enum lws_callback_reasons reason,
                               void *user, void *in, size_t len) {
    switch (reason) {
        case LWS_CALLBACK_CLIENT_ESTABLISHED:
            // printf("Client connected to relay\n");
            if (event_json) {
                lws_write(wsi, (unsigned char *)event_json, strlen(event_json), LWS_WRITE_TEXT);
            } else {
                char buffer[256];
                snprintf(buffer, sizeof(buffer), "[\"REQ\", \"sub1\", {\"authors\": [\"%s\"]}]", public_key);
                lws_write(wsi, (unsigned char *)buffer, strlen(buffer), LWS_WRITE_TEXT);
            }
            break;
        case LWS_CALLBACK_CLIENT_WRITEABLE:
            if (event_json) {
                lws_write(wsi, (unsigned char *)event_json, strlen(event_json), LWS_WRITE_TEXT);
                // No need to set event_published flag here since we'll check for the response
            }
            break;
        case LWS_CALLBACK_CLIENT_RECEIVE:
            printf("%s\n", (char *)in);
            if (strstr((char *)in, "\"EOSE\"")) {
                eose_received = 1; // Set the flag when EOSE is received
                lws_cancel_service(context); // Exit the service loop
            } else if (strstr((char *)in, "\"OK\"")) {
                event_published = 1; // Set the flag when the event is acknowledged
                lws_cancel_service(context); // Exit the service loop
            }
            break;
        case LWS_CALLBACK_CLIENT_CONNECTION_ERROR:
            fprintf(stderr, "Client connection error\n");
            force_exit = 1;
            break;
        case LWS_CALLBACK_CLIENT_CLOSED:
            // fprintf(stderr, "Client disconnected from relay\n");
            force_exit = 1;
            break;
        default:
            break;
    }
    return 0;
}

static struct lws_protocols protocols[] = {
    {"example-protocol", callback_websockets, 0, 4096},
    {NULL, NULL, 0, 0} /* terminator */
};

void parse_url(const char *url, char *hostname, char *path, int *port, int *use_ssl) {
    regex_t regex;
    regmatch_t pmatch[6];

    const char *pattern = "^(wss?)://([^:/]+)(:([0-9]+))?(/.*)?$";
    regcomp(&regex, pattern, REG_EXTENDED);

    if (regexec(&regex, url, 6, pmatch, 0) == 0) {
        if (strncmp(url + pmatch[1].rm_so, "wss", 3) == 0) {
            *use_ssl = 1;
        } else {
            *use_ssl = 0;
        }
        snprintf(hostname, pmatch[2].rm_eo - pmatch[2].rm_so + 1, "%.*s", (int)(pmatch[2].rm_eo - pmatch[2].rm_so), url + pmatch[2].rm_so);
        if (pmatch[4].rm_so != -1) {
            *port = atoi(url + pmatch[4].rm_so);
        } else {
            *port = *use_ssl ? 443 : 80;
        }
        if (pmatch[5].rm_so != -1) {
            snprintf(path, pmatch[5].rm_eo - pmatch[5].rm_so + 1, "%.*s", (int)(pmatch[5].rm_eo - pmatch[5].rm_so), url + pmatch[5].rm_so);
        } else {
            strcpy(path, "/");
        }
    }

    regfree(&regex);
}

int main(int argc, char **argv) {
    if (argc != 4) {
        fprintf(stderr, "Usage: %s <relay_url> <event_json | NULL> <public_key>\n", argv[0]);
        return 1;
    }

    relay_url = argv[1];
    event_json = (strcmp(argv[2], "NULL") == 0) ? NULL : argv[2];
    public_key = argv[3];

    if (!relay_url || (!event_json && !public_key)) {
        fprintf(stderr, "Error: Missing required arguments.\nUsage: %s <relay_url> <event_json | NULL> <public_key>\n", argv[0]);
        return 1;
    }

    char hostname[256];
    char path[256];
    int port;
    int use_ssl;

    parse_url(relay_url, hostname, path, &port, &use_ssl);

    // Check if the hostname is an IP address
    struct in_addr ipv4addr;
    struct in6_addr ipv6addr;
    if (inet_pton(AF_INET, hostname, &ipv4addr) == 1 || inet_pton(AF_INET6, hostname, &ipv6addr) == 1) {
        fprintf(stderr, "Error: Please provide a domain name instead of an IP address.\n");
        return 1;
    }

    // Initialize OpenSSL library
    SSL_library_init();
    SSL_load_error_strings();
    OpenSSL_add_all_algorithms();

    struct lws_context_creation_info info;
    memset(&info, 0, sizeof(info));
    info.port = CONTEXT_PORT_NO_LISTEN;
    info.protocols = protocols;

    // Enable detailed logging
    // lws_set_log_level(LLL_ERR | LLL_WARN | LLL_NOTICE | LLL_INFO | LLL_DEBUG | LLL_PARSER | LLL_HEADER | LLL_EXT | LLL_CLIENT | LLL_LATENCY, NULL);

    if (use_ssl) {
        info.options |= LWS_SERVER_OPTION_DO_SSL_GLOBAL_INIT;
        info.ssl_ca_filepath = "/etc/ssl/certs/ca-certificates.crt";  // Update this path to your CA certificates
        info.ssl_cipher_list = "DEFAULT:!DH";
    }

    context = lws_create_context(&info);
    if (!context) {
        fprintf(stderr, "lws init failed\n");
        return -1;
    }

    signal(SIGINT, sigint_handler);

    struct lws_client_connect_info ccinfo = {0};
    ccinfo.context = context;
    ccinfo.address = hostname;
    ccinfo.port = port;
    ccinfo.path = path;
    ccinfo.host = hostname;  // Use the hostname provided by the user
    ccinfo.origin = hostname;
    ccinfo.local_protocol_name = protocols[0].name;
    ccinfo.ssl_connection = use_ssl ? LCCSCF_USE_SSL | LCCSCF_ALLOW_SELFSIGNED | LCCSCF_SKIP_SERVER_CERT_HOSTNAME_CHECK : 0;

    if (!lws_client_connect_via_info(&ccinfo)) {
        fprintf(stderr, "Client connection failed\n");
        lws_context_destroy(context);
        return -1;
    }

    while (!force_exit && !event_published && !eose_received) {
      lws_service(context, 100);
    }

    lws_context_destroy(context);
    return 0;
}

