# ROM Override Folder

Drop edited DAT files inside this folder using the exact same path they use in
the retail FFXI client.

Example only:

```text
ROM/
  119/
    51.DAT
```

The actual path for the Legendary Ring depends on where your DAT editor finds the
retail `Reraise Ring` item text.

## How To Find The Correct DAT

1. Open the FFXI client DATs with POLUtils or a similar DAT editor.
2. Search for:

```text
Reraise Ring
```

3. Note the DAT path, for example `ROM/xxx/yy.DAT`.
4. Edit the name + help text for item `26169` to the Legendary Ring text
   (see `manifest.md`).
5. Copy the edited DAT into this folder with the same path:

```text
Relaunch Custom DATs/
  ROM/
    xxx/
      yy.DAT
```

XIPivot will then override that DAT client-side when the pack is enabled.
