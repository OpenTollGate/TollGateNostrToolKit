
# Setup build environment from scratch

Install dependencies and create user called `username`
```
curl -sSL https://raw.githubusercontent.com/OpenTollGate/TollGateNostrToolKit/refs/heads/main/setup_from_scratch.sh | bash
```

Set password and log in as `username`
```
passwd username
ssh username@localhost
```

Make sure your on the branch that needs testing. If you want to try a branch that "just works", you should probably go for `main`.

Run build script:
```
username@ubuntu-32gb-nbg1-1:~/TollGateNostrToolKit$ ./build_coordinator.sh 
Running setup_dependencies.sh
[sudo] password for username:
```

`./build_coordinator.sh` will build TollGate for all routers listed
under `./routers/*_config` using `./install_script.sh` to place
configurations from `./files/` into the filesystem of the
`sysupgrade.bin` file.

You can find your newly created sysupgrade file in
`./binaries/openwrt-ath79-nand-glinet_gl-ar300m-nor-squashfs-sysupgrade_[commit_hash].bin`.

This can take over an hour if its your first time building TollGate,
but `build_coordinator.sh` only takes minutes if you run it again
after having changed something in `files` without changing any of
source code that affects openwrt's binaries and without having changed
the configuration files in `routers`.

You can modify the contents of `./files` and/or `install_script.sh` to
change the initial content of the filesystem in `sysupgrade.bin`.

The following make command was used to collect logs, so you can
inspect `~/openwrt/make_logs.md` in case of build failure.
```
make -j$(nproc) V=sc > make_logs.md 2>&1
```

## Some basic documentation

- [Setup from Scratch](setup_from_scratch.md): Detailed instructions for setting up the build environment in a new VPS.

- [Updating Feeds Configuration in OpenWrt](updating_feeds_conf_in_openwrt.md): Guide on how to update the feeds configuration in OpenWrt.

- [Uploading Binaries to GitHub Releases](upload_binaries_to_github.md): Instructions for uploading binaries to GitHub releases without adding them to the git repository.

- [Setting DNS Server](setting_dns_server.md): Instructions for setting DNS server.

- [Find error in logs](find_error_in_logs.md): Commands for parsing through `build_logs.md` to find relevant lines.

- [Syncronize nodogsplash.conf with UCI](nodogsplash_configuration.md): nodogsplash gets its commands from `/etc/nodogsplash/nodogsplash.conf`, but the UCI commands modify `/etc/config/nodogsplash`. Logic is required to transfer the UCI settings to `nodogsplash.conf` on startup.

- [Squashing a diverged branch](squash_commits_since_main.md): squash all commits on current branch since the point where it diverged from main. This makes the branch easier to rebase onto main.

- [Updating Feeds Configuration in OpenWRT](updating_feeds_conf_in_openwrt.md): the feeds are used to specify which repos should be cloned and built when building openwrt.
