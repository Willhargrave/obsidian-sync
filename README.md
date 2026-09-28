# Obsidian sync setup

## 1. Overview

Syncthing synchronizes the Obsidian vault among the Personal MacBook, Work MacBook, Android phone, and BOOX Page. This GitHub repository stores only the setup script, ignore rules, and documentation. Vault contents must never be committed or pushed to GitHub.

Syncthing is synchronization, not backup. A deletion or unwanted edit can propagate to every device.

## 2. Architecture

```text
Personal MacBook  ←→  Work MacBook
       ↕                 ↕
 Android Phone   ←→   BOOX Page
```

All four devices are peers in a conceptual mesh. The Personal MacBook is the primary device and the main place for backup and versioning, but it is not a required hub. Peers can connect directly whenever possible. Syncthing can use relays when a direct connection is unavailable.

Every device uses the Syncthing Folder ID `obsidian-main`.

## 3. Personal MacBook setup

Clone the private setup repository and run the installer:

```bash
git clone <PRIVATE_REPO_URL>
cd obsidian-sync
VAULT_DIR="$HOME/Documents/Obsidian Vault" ./install-macos.sh
```

This Personal MacBook's existing vault is `/Users/willh/Documents/Obsidian Vault`, so the quoted `VAULT_DIR` keeps the space in its name. The installer's default remains `~/ObsidianVault`. A different custom path also works:

```bash
VAULT_DIR=/custom/path ./install-macos.sh
```

In the Syncthing web UI:

1. Choose **Actions > Show ID** to view this Mac's Device ID.
2. Choose **Add Folder**.
3. Set **Folder ID** to `obsidian-main`.
4. Set **Folder Path** to `/Users/willh/Documents/Obsidian Vault`, matching the `VAULT_DIR` used above.
5. On the **File Versioning** tab, choose **Simple File Versioning** and retain about 10 versions.
6. Add the other devices and share `obsidian-main` with them.

Syncthing File Versioning applies to changes received from other devices. It does not replace a real backup. Keep an independent backup of the Personal MacBook vault.

## 4. Work MacBook setup

First verify that company IT and security policies permit a personal vault and Syncthing on the managed computer. Then clone the private setup repository and run:

```bash
git clone <PRIVATE_REPO_URL>
cd obsidian-sync
./install-macos.sh
```

Pair the Work MacBook with an existing peer. One side can add the other side's Device ID or scan its QR code, then the other side accepts the device request. You do not need to manually enter both IDs on both devices.

Accept the offered `obsidian-main` folder and map it to:

```text
~/ObsidianVault
```

Enable Simple File Versioning on the Work MacBook too. If company networking blocks Syncthing, reassess the architecture and company policy. Do not quietly switch to committing the vault to GitHub.

## 5. Android phone

The official Syncthing Android application was discontinued. Use the actively maintained Syncthing-Fork app instead.

1. Install Syncthing-Fork, preferably from F-Droid.
2. Grant the storage or files access it needs.
3. Add the Personal MacBook by Device ID or QR code.
4. Accept the device relationship on the other device.
5. Accept the shared `obsidian-main` folder.
6. Select the local directory that Obsidian will use as its vault.
7. Disable battery optimization for Syncthing-Fork and allow background operation.
8. Perform the first large sync over Wi-Fi.

Android background-process restrictions can pause synchronization. If changes do not arrive, check Syncthing-Fork's status and the phone's battery and background-app controls.

## 6. BOOX Page

The BOOX Page runs Android 11, so use Syncthing-Fork as on the phone. Install it through F-Droid, or sideload the F-Droid APK if necessary. Grant file access, pair the device, accept `obsidian-main`, and select the local Obsidian vault directory.

BOOX firmware may suspend background applications aggressively. Allow Syncthing-Fork to run in the background. The exact setting names vary by firmware. If continuous sync uses too much battery, scheduled syncing is a reasonable compromise.

For Obsidian on e-ink, disable unnecessary animations where practical. Choose a BOOX refresh mode suited to the task: a faster mode for typing and a cleaner mode for reading. Exact mode names vary by firmware.

## 7. Obsidian configuration

On each device, choose **Open folder as vault** in Obsidian and select the folder managed by Syncthing.

Most of `.obsidian` can sync. Settings, themes, CSS snippets, and plugins normally belong in the shared vault. Plugins generally sync from:

```text
.obsidian/plugins/
```

Some plugins behave differently on desktop and mobile, so device-specific plugin configuration may sometimes be necessary. This repository ignores desktop workspace state, sessions, and caches. It leaves `.obsidian/workspace-mobile.json` synced by default so both mobile devices can share it. If the phone and BOOX need different mobile layouts, add that file to the vault's `.stignore` after weighing that tradeoff.

## 8. Conflict handling

Concurrent edits can produce files such as:

```text
filename.sync-conflict-YYYYMMDD-HHMMSS-DEVICE.ext
```

Do not ignore these files. Review each one, merge any content that should survive, then delete the conflict copy only after deciding which content is correct. Avoid editing the same note on multiple disconnected devices at the same time.

## 9. Backup strategy

Syncthing is not backup. Keep a separate backup of the Personal MacBook vault. Time Machine, restic, or another local or external backup can fill that role. Backup installation and configuration are outside this repository's scope.

## 10. Daily operation

- Keep `.stignore` in the root of the synchronized vault.
- Run the initial sync while devices are on the same network when possible.
- Later synchronization can happen remotely through direct connections or Syncthing relays.
- Review every conflict file.
- Treat File Versioning as a useful recovery aid, not a complete backup.
- Check Android and BOOX battery controls if background syncing stops.
