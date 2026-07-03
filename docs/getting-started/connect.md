# Connect to the Server

## Server details

| | |
|---|---|
| **Server IP** | `172.215.213.23` |
| **Data port** | `54240` |
| **Auth port** | `54241` |
| **View port** | `54011` |

---

## Windower

Windower 4 has no "Login Server" field for private servers. Instead, you point a profile at **`xiloader.exe`** (the FJB loader) and pass the server address and ports as launch arguments.

1. Make sure **`xiloader.exe`** is in your FFXI folder, next to `pol.exe` (usually `…\SquareEnix\PlayOnlineViewer\`). See [Get the loader](install.md#get-the-loader).
2. Open the **Windower 4** launcher and create or edit a profile.
3. Set **Executable** to `xiloader.exe` (use the full path if Windower can't find it).
4. Set **Arguments** to:
   ```
   --server 172.215.213.23 --dataport 54240 --authport 54241 --viewport 54011
   ```
5. Save and launch.

Prefer to edit `Windower4/settings/settings.xml` by hand? The profile looks like this:

```xml
<profile name="FJBRelaunch">
  <executable>xiloader.exe</executable>
  <args>--server 172.215.213.23 --dataport 54240 --authport 54241 --viewport 54011</args>
</profile>
```

!!! tip "Skip the login prompt"
    Add your credentials to log in automatically:
    ```
    --server 172.215.213.23 --dataport 54240 --authport 54241 --viewport 54011 --user YOURNAME --pass YOURPASSWORD
    ```

---

## Ashita

1. Open the **Ashita** launcher.
2. Select your profile (or create a new one) and click **Edit**.
3. Under **Login Server**, enter `172.215.213.23`.
4. Set the **Data port** to `54240`, **Auth port** to `54241`, and **View port** to `54011`.
5. Save the profile and launch.

!!! tip
    If Ashita uses a `boot.ini` or boot script, set `--server 172.215.213.23 --dataport 54240 --authport 54241 --viewport 54011`.

---

## Troubleshooting

**"Unable to connect" / connection timeout**
: Verify all four values (IP + 3 ports) match the table above. If the server was just restarted, wait 30 seconds and try again.

**"Version mismatch" error**
: Your client needs to be the current retail version. Run the PlayOnline updater to patch up, then try again.

**Stuck on the login screen / no response**
: Check the [Discord](https://discord.gg/Yd3Kn3dN36) #server-status channel — the server may be down for maintenance.

---

<!-- DOCGEN:BEGIN id="last-updated" -->
<!-- content-hash: 78f396f43492 -->
_Last updated: 2026-06-29 04:19 UTC_
<!-- DOCGEN:END id="last-updated" -->
