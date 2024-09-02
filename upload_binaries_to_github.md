# Uploading Binaries to GitHub Releases

To upload binaries to GitHub without adding them to the git repository and without downloading them to your local machine first, you can use GitHub's Releases feature. This allows you to attach binary files directly to a release. Here's how you can do it using the GitHub CLI (`gh`) tool:

1. Install the GitHub CLI if you haven't already:

   ```bash
   sudo apt update
   sudo apt install gh
   ```

2. Authenticate with your GitHub account:

   ```bash
   gh auth login
   ```

3. Create a new release (replace `v1.0.0` with your desired version number):

   ```bash
   gh release create v1.0.0
   ```

4. Upload the binary files to the release:

   ```bash
   gh release upload v1.0.0 binaries/*
   ```

   This command will upload all files in the `binaries/` directory to the release.

   If you want to upload specific files, you can list them individually:

   ```bash
   gh release upload v1.0.0 binaries/checksums.json binaries/generate_npub_optimized_ath79_glar300m binaries/mips_24kc_packages_ath79_glar300m.tar.gz binaries/generate_npub_optimized_ath79_archer_c7_v2 binaries/mips_24kc_packages_ath79_archer_c7_v2.tar.gz
   ```

These commands will upload the binaries directly from your VPS to GitHub without adding them to the git repository or requiring you to download them to your local machine first.

