# Modbus split add-ons – manual test cases

Tests the split of the Modbus binding into a lean core (`modbus-core`) plus one add-on per device
(`modbus-e3dc`, `modbus-studer`, …) and the unchanged aggregate add-on `modbus` ("Modbus Binding (All Devices)").
Target: openHAB 5.3.0-SNAPSHOT (distro build 146).

## Prerequisites

- Windows, Java 21 or newer (`java -version`), internet access (the snapshot distro is downloaded once to `%TEMP%`).
- Everything is started by double-clicking the `.bat` files in this folder. All instances are created next to them
  (`oh52`, `oh53-lean`, `oh53-core`, `oh53-legacy`). Only one openHAB instance may run at a time (port 8080).
- Stop a running instance with Ctrl+C in its window before starting the next test.
- UI: <http://localhost:8080>, log: `<instance>\userdata\logs\openhab.log`.
- Karaf console (for bundle checks): `ssh -p 8101 openhab@localhost` (password `habopen`), then `bundle:list | grep -i modbus`.

## What is in this folder

| Path | Purpose |
|---|---|
| `modbus-split-test\` | `Setup-OpenHabTest.ps1`, `modbus-features.xml` and a local Maven repo with the 13 Modbus bundles |
| `core-patch\` | Patched `org.openhab.core.thing` jar (adds `bundleSymbolicName` to thing types) and the patch file |
| `ui-patch\` | Patched Main UI jar (filters the "Add Thing" page per add-on) |

---

## Test B – Lean installation (single device add-on)

Goal: only the core and the E3DC extension are installed, nothing else.

1. Run `1-create-lean.bat` (creates `oh53-lean`, downloads the distro on first run).
2. Run `2-start-lean.bat` and wait until the UI is reachable.
3. Open *Settings → Add-on Store → Bindings*. Install **Modbus E3DC Binding**.
4. Wait for the installation to finish.

Expected:
- Karaf: `bundle:list | grep -i modbus` shows exactly two bundles: `org.openhab.binding.modbus` and `org.openhab.binding.modbus.e3dc`
  (plus the transport bundle).
- **Modbus Core Binding** is also listed as installed in the add-on store.
- *Settings → Things → + → Modbus E3DC Binding* lists the generic bridges (TCP/Serial) and the E3DC things.
- Optional: create a *Modbus TCP Slave* bridge to your E3DC and an *E3DC* thing; it goes ONLINE.

## Test C – Patched core + UI (Add Thing filtering)

Goal: on the "Add Thing" page of one device add-on only its own thing types (plus generic Modbus things) are shown.

1. Continue with `oh53-lean` from Test B. In the add-on store additionally install **Modbus Studer Binding**.
2. *Settings → Things → + → Modbus E3DC Binding* – **without the patch** the Studer thing types are listed as well. (Known limitation, this is the problem.)
3. Stop openHAB (Ctrl+C).
4. Run `3-apply-core-ui-patch.bat` (copies the patched jars, moves `userdata\cache` and `userdata\tmp` aside).
5. Run `2-start-lean.bat` again (the first start takes longer).
6. Hard-reload the browser (Ctrl+F5).
7. *Settings → Things → + → Modbus E3DC Binding*.

Expected:
- Generic Modbus things (bridges, Poller, Data) and E3DC things are shown. **No Studer things.**
- *+ → Modbus Studer Binding* shows generic things and Studer things, no E3DC things.
- *+ → Modbus Core Binding* (shown in "Choose Binding" because the device add-ons depend on the core feature) shows only generic things.
- `http://localhost:8080/rest/thing-types?bindingId=modbus` returns entries with a `bundleSymbolicName` field.
- No errors at startup in `openhab.log` (the core jar comes from a newer master than distro build 146 – note any exception).

## Test D – Core binding only

Goal: the pure Modbus Core Binding can be installed without any device extension.

1. Stop other instances. Run `4-create-core-only.bat` (creates `oh53-core`).
2. Run `5-start-core-only.bat`.
3. Add-on store → install **Modbus Core Binding** only.
4. *Settings → Things → + → Modbus Core Binding*.

Expected:
- `bundle:list | grep -i modbus` shows only `org.openhab.binding.modbus` (and transport).
- The following thing types are offered: Modbus Serial Slave, Modbus TCP Slave, Modbus Poller, Modbus Data.
- No device-specific types (E3DC, Studer, …).
- Uninstall via the UI removes the bundles again.

## Test A – Upgrade of an existing installation (no breaking change)

Goal: an installation that has the old add-on `modbus` keeps working after the upgrade to 5.3.

1. Run `0-create-oh52-baseline.bat` (creates a stock `oh52`; edit `VER` in the file if the download URL does not exist).
2. Start `oh52\start.bat`, open the UI, set up the admin account.
3. Install the add-on **Modbus Binding** (id `modbus`), create a *Modbus TCP Slave* bridge, a *Modbus Poller* and an *E3DC* thing
   (or any other device thing you can reach). Check that it is ONLINE. Stop openHAB (Ctrl+C).
4. Run `6-create-legacy-upgrade.bat` (copies `conf` and `userdata` of `oh52` into a new 5.3 instance `oh53-legacy`; `oh52` stays untouched).
5. Run `7-start-legacy-upgrade.bat`.

Expected:
- The add-on **Modbus Binding (All Devices)** (id `modbus`) is shown as installed. Core and all device bundles are installed (`bundle:list | grep -i modbus`: 13 bundles).
- All things are ONLINE, channels deliver values, no errors in the log.
- *Add Thing → Modbus Binding (All Devices)* works and shows the thing types of all devices.

## Test E – Aggregate and core installed together

Goal: installing "Modbus Core Binding" while "Modbus Binding (All Devices)" is installed (or the other way round) causes no conflict.

1. Use `oh53-lean` (or a fresh instance). In the add-on store install **Modbus Binding (All Devices)**, then additionally **Modbus Core Binding**.
2. `bundle:list | grep -i modbus`.
3. Uninstall **Modbus Core Binding** again (store) and repeat step 2 and look at the store.

Expected:
- Step 2: exactly 13 Modbus bundles (core, 11 devices, legacy), each once, no errors in `openhab.log`.
- Step 3: the core bundle stays installed as long as the aggregate is installed (to be confirmed – not yet verified).
- Cloud result (boot with both features): 13 bundles, 37 thing types, no errors.

---

## Reporting

For each test please note: PASS/FAIL, openHAB build, anything unexpected, and attach `openhab.log` on failure.

## Cleanup

Stop openHAB, then delete `oh52`, `oh53-lean`, `oh53-core`, `oh53-legacy`. The downloaded distro stays in `%TEMP%\openhab-5.3-snapshot.zip`.
