# Connect to the Server

## Server details

| | |
|---|---|
| **Login server** | `172.215.213.23` |

---

## Ashita

1. Open the **Ashita** launcher.
2. Select your profile (or create a new one) and click **Edit**.
3. Under **Login Server**, replace the default address with `172.215.213.23`.
4. Save the profile and launch.

!!! tip
    If you don't see a Login Server field, look for a `boot.ini` or boot script in your Ashita profile folder. Change the `--server` argument to `172.215.213.23`.

---

## Windower

Windower 4 has no "Login Server" field for private servers. Instead, you point a profile at **`xiloader.exe`** (the Legendary loader) and pass the server address as a launch argument — xiloader makes the connection and Windower hooks into it.

1. Make sure **`xiloader.exe`** is in your FFXI folder, next to `pol.exe` (usually `…\SquareEnix\PlayOnlineViewer\`). See [Get the loader](install.md#get-the-loader).
2. Open the **Windower 4** launcher and create or edit a profile.
3. Set **Executable** to `xiloader.exe` (use the full path if Windower can't find it).
4. Set **Arguments** to `--server 172.215.213.23`.
5. Save and launch.

Prefer to edit `Windower4/settings/settings.xml` by hand? The profile looks like this:

```xml
<profile name="Legendary">
  <executable>xiloader.exe</executable>
  <args>--server 172.215.213.23</args>
</profile>
```

!!! tip "Skip the login prompt"
    Add your credentials to the arguments to log in automatically:
    `--server 172.215.213.23 --user YOURNAME --pass YOURPASSWORD`

---

## Troubleshooting

**"Unable to connect" / connection timeout**
: Verify you're using IP `172.215.213.23`. If the server was just restarted, wait 30 seconds and try again.

**"Version mismatch" error**
: Your client needs to be the current retail version. Run the PlayOnline updater to patch up, then try again.

**Stuck on the login screen / no response**
: Check the [Discord](https://discord.gg/MsZqvuDn) #server-status channel — the server may be down for maintenance.

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: e7eb37e6a602 -->
_Last updated: 2026-06-13 17:01 UTC_
<!-- DOCGEN:END id="last-updated" -->
