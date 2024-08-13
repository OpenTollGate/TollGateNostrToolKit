# Setup build environment from scratch
```
curl -sSL https://raw.githubusercontent.com/chGoodchild/TollGateNostrToolKit/nostr_client_relay/setup_from_scratch.sh | bash
```

# Build everything
```
sudo ./build_coordinator.sh
./sign_event_local 
```

Usage: `./sign_event_local <message_hash> <private_key_hex>`

