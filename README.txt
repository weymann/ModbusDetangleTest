Modbus split add-ons - test package (openHAB 5.3.0-SNAPSHOT)
Requirements: Windows, Java 21+, internet (downloads snapshot distro once). Details: modbus-split-test\README.md

Test B  lean install:  1-create-lean.bat, 2-start-lean.bat -> Add-ons: install "Modbus E3DC Binding" only.
                       Expect: bundles modbus-core + modbus.e3dc only; "Modbus Core Binding" shown as installed.
Test C  UI/core patch: stop openHAB, 3-apply-core-ui-patch.bat, start again.
                       Expect: Add Thing > modbus-e3dc lists generic Modbus + E3DC things, no Studer things (install Studer too to check).
Test D  core only:     4-create-core-only.bat, 5-start-core-only.bat -> install "Modbus Core Binding" only.
                       Expect: Serial, TCP, Poller, Data things.
Test A  upgrade:       0-create-oh52-baseline.bat (configure Modbus + thing), then 6-create-legacy-upgrade.bat, 7-start-legacy-upgrade.bat.
                       Expect: add-on "Modbus Binding (All Devices)" (id modbus) installed, things come ONLINE.
Cleanup: delete the oh52, oh53-* folders.
