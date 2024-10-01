# Setup build environment from scratch
```
curl -sSL https://raw.githubusercontent.com/chGoodchild/TollGateNostrToolKit/nostr_client_relay/setup_from_scratch.sh | bash
```

Set password for user called `username`:
```
root@ubuntu-32gb-nbg1-1:~# passwd username
New password: 
Retype new password: 
passwd: password updated successfully
```

Login as non root user:
```
root@ubuntu-32gb-nbg1-1:~# ssh username@localhost
```

Get repo:
```
curl -sSL https://raw.githubusercontent.com/chGoodchild/TollGateNostrToolKit/nostr_client_relay/setup_repo.sh | bash
```

Run build script:
```
username@ubuntu-32gb-nbg1-1:~/TollGateNostrToolKit$ ./build_coordinator.sh 
Running setup_dependencies.sh
[sudo] password for username:
```

# Collecting logs
```
make -j$(nproc) V=s > make_logs.md 2>&1
```

[Updating Feeds Configuration in OpenWRT](updating_feeds_conf_in_openwrt.md)


# Build everything
```
sudo ./build_coordinator.sh
./sign_event_local 
```

Usage: `./sign_event_local <message_hash> <private_key_hex>`

