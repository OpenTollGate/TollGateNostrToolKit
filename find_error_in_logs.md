To find the error in the `make_logs.md` file, you can use the `grep` command to search for error messages. Here are a few commands you can try:

1. Search for "Error" messages:

```bash
grep -n "Error" ~/openwrt/make_logs.md
```

2. Search for "failed" messages:

```bash
grep -n "failed" ~/openwrt/make_logs.md
```

3. Search for both "Error" and "failed" messages:

```bash
grep -n -E "Error|failed" ~/openwrt/make_logs.md
```

4. To see more context around the errors, you can use the `-C` option with grep. For example, to see 5 lines before and after each match:

```bash
grep -n -E "Error|failed" -C 5 ~/openwrt/make_logs.md
```

5. If you want to focus on errors related to gltollgate specifically:

```bash
grep -n -E "Error|failed" -C 5 ~/openwrt/make_logs.md | grep -i gltollgate
```

6. To see the last 100 lines of the log file, which often contain the most recent errors:

```bash
tail -n 100 ~/openwrt/make_logs.md | grep -n -E "Error|failed"
```

These commands will help you identify error messages in the log file. The `-n` option with `grep` will show line numbers, which can be helpful for locating the errors in the file.

If these don't yield useful results, you might need to examine the entire log file manually or use more specific search terms based on what you see in the file.