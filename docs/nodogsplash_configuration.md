I understand your intention, but unfortunately, you **cannot** simply point Nodogsplash to `/etc/config/nodogsplash` by changing the `option config` line. Here's why:

- **Nodogsplash Cannot Parse UCI Files Directly**: The `/etc/config/nodogsplash` file is in UCI (Unified Configuration Interface) format, which is specific to OpenWrt and not directly readable by Nodogsplash.
  
- **Expected Configuration Format**: Nodogsplash expects its configuration file (`nodogsplash.conf`) to be in its own specific format, which is different from the UCI format used in `/etc/config/nodogsplash`.

**Explanation of the `option config` Directive:**

The `option config '/etc/nodogsplash/nodogsplash.conf'` line in `/etc/config/nodogsplash` is not used to tell Nodogsplash where to find its configuration file. Instead, it's used by the **init script** or **hotplug scripts** to know where to generate or place the `nodogsplash.conf` file after processing the UCI configuration.

**Solution:**

To ensure that the configurations from `/etc/config/nodogsplash` are used and that any conflicting settings in `/etc/nodogsplash/nodogsplash.conf` are ignored, you need to have a process that **translates the UCI configurations into the `nodogsplash.conf` file** before starting Nodogsplash.

Here's how you can achieve this:

1. **Uncomment and Correct the `option config` Line:**

   Edit `/etc/config/nodogsplash` and ensure the `option config` line is uncommented and correctly points to the expected location:

   ```bash
   option config '/etc/nodogsplash/nodogsplash.conf'
   ```

2. **Create a Script to Generate `nodogsplash.conf` from UCI Settings:**

   Create a script that reads the UCI configuration and writes the corresponding settings to `/etc/nodogsplash/nodogsplash.conf`. Here's a sample script:

   **Script:** `/etc/nodogsplash/uci2ndsconf.sh`

   ```bash
   #!/bin/sh

   . /lib/functions.sh

   uci_load_nodogsplash() {
       config_load nodogsplash
       config_foreach uci2conf_settings nodogsplash
   }

   uci2conf_settings() {
       local cfg="$1"

       config_get enabled "$cfg" enabled
       [ "$enabled" = "0" ] && exit 0  # Exit if Nodogsplash is disabled

       config_get gatewayinterface "$cfg" gatewayinterface
       config_get gatewayname "$cfg" gatewayname
       config_get maxclients "$cfg" maxclients
       config_get debuglevel "$cfg" debuglevel
       config_get preauthidletimeout "$cfg" preauthidletimeout
       config_get authidletimeout "$cfg" authidletimeout
       config_get sessiontimeout "$cfg" sessiontimeout
       config_get checkinterval "$cfg" checkinterval
       config_get binauth "$cfg" binauth
       config_get_list authenticated_users "$cfg" authenticated_users

       # Start writing to nodogsplash.conf
       cat > /etc/nodogsplash/nodogsplash.conf <<EOF
   GatewayInterface $gatewayinterface
   GatewayName $gatewayname
   MaxClients $maxclients
   DebugLevel $debuglevel
   PreAuthIdleTimeout $preauthidletimeout
   AuthIdleTimeout $authidletimeout
   SessionTimeout $sessiontimeout
   CheckInterval $checkinterval
   $( [ -n "$binauth" ] && echo "BinAuth $binauth" )

   FirewallRuleSet authenticated-users {
   EOF

       for rule in $authenticated_users; do
           echo "    FirewallRule $rule" >> /etc/nodogsplash/nodogsplash.conf
       done

       cat >> /etc/nodogsplash/nodogsplash.conf <<EOF
   }

   # Add other FirewallRuleSets as needed
   EOF
   }

   uci_load_nodogsplash
   ```

   **Make the script executable:**

   ```bash
   chmod +x /etc/nodogsplash/uci2ndsconf.sh
   ```

3. **Modify the Nodogsplash Init Script:**

   Edit `/etc/init.d/nodogsplash` to call this script before starting Nodogsplash.

   **Modified `/etc/init.d/nodogsplash`:**

   ```bash
   #!/bin/sh /etc/rc.common

   START=95
   STOP=05
   USE_PROCD=1

   start_service() {
       # Generate nodogsplash.conf from UCI settings
       /etc/nodogsplash/uci2ndsconf.sh

       procd_open_instance
       procd_set_param command /usr/bin/nodogsplash
       procd_set_param respawn
       procd_close_instance
   }

   stop_service() {
       killall nodogsplash
   }

   boot() {
       start_service
   }

   shutdown() {
       stop_service
   }
   ```

4. **Ensure the `nodogsplash.conf` File Is Up-to-Date:**

   Now, whenever Nodogsplash starts, it will generate the `nodogsplash.conf` file based on your UCI configuration. This ensures that any changes you make in `/etc/config/nodogsplash` are reflected in the configuration file used by Nodogsplash.

5. **Restart Nodogsplash:**

   After making these changes, restart the service:

   ```bash
   /etc/init.d/nodogsplash restart
   ```

**Explanation:**

- **Why Can't You Point Nodogsplash to the UCI File Directly?**

  Nodogsplash is not designed to parse the UCI configuration format. It expects its configuration file to be in a specific syntax, as seen in `/etc/nodogsplash/nodogsplash.conf`. Changing the path to point to `/etc/config/nodogsplash` would cause Nodogsplash to attempt to read an improperly formatted file, resulting in errors.

- **Role of `option config` in `/etc/config/nodogsplash`:**

  The `option config` directive is used internally (by scripts or the init system) to specify where the generated `nodogsplash.conf` file should be placed. It is not used by Nodogsplash to find and parse the UCI configuration.

- **Ensuring Consistency:**

  By generating the `nodogsplash.conf` from the UCI file each time Nodogsplash starts, you ensure that all configurations are consistent and that settings from `/etc/nodogsplash/nodogsplash.conf` are always synchronized with `/etc/config/nodogsplash`.

**Alternative Solution: Use UCI2CONF Package (If Available):**

Some OpenWrt packages come with built-in scripts to handle this conversion. Check if the `nodogsplash` package you installed includes a UCI to conf conversion script, or consider updating to a version that does. If available, you might just need to enable or configure it properly.

**Summary:**

- **Do not** point Nodogsplash directly to the UCI configuration file.
- **Ensure** that the `nodogsplash.conf` file is generated from your UCI configuration.
- **Modify** the init script to generate the configuration file before starting Nodogsplash.
- **Restart** Nodogsplash to apply the changes.

**Note:**

Always make backups of your configuration files before making changes. This way, you can restore previous configurations if needed.

**Additional Tips:**

- **Testing Configurations:**

  After restarting Nodogsplash, check the status and logs to ensure it started correctly:

  ```bash
  nodogsplash status
  logread | grep nodogsplash
  ```

- **Validate the Generated `nodogsplash.conf`:**

  Ensure that the generated `/etc/nodogsplash/nodogsplash.conf` file contains the correct settings as per your UCI configuration.

- **Keep Your System Updated:**

  Ensure that you are running the latest stable version of OpenWrt and that all packages are up-to-date. This minimizes compatibility issues.

---

By following these steps, you'll ensure that Nodogsplash uses the configurations from `/etc/config/nodogsplash`, and any conflicting configurations in `/etc/nodogsplash/nodogsplash.conf` are effectively overridden.