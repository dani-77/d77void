# acpi-gpe-guard

Detects and masks a runaway ACPI GPE (a firmware/hardware interrupt-storm
bug found on some laptops — see the comment header in
`acpi-gpe-guard.sh` for the full story of how this was diagnosed) without
hardcoding which GPE number to watch for, so it's safe to ship in a
general-purpose image built for hardware you don't control.

Tested by hand on the machine this was written for: correctly leaves a
healthy system alone (clean exit, no log output) and correctly detects
and masks a GPE actively storming.

## Files

- `acpi-gpe-guard.sh` — the actual detector/masker. Self-contained,
  runnable standalone for one-off diagnosis: `sh acpi-gpe-guard.sh`.
  Logs via `logger -t acpi-gpe-guard` (falls back to stderr if `logger`
  isn't available) only when it actually masks something — silent on a
  healthy system. Depends only on `awk` (a direct `base-system`
  dependency, so guaranteed on any variant) and `logger` (optional,
  degrades gracefully).
- `run` — a runit service wrapping the script in a boot-settle delay
  (20s) plus a 5-minute recheck loop, so it catches a storm that starts
  later too (e.g. after suspend/resume), not just one present at boot.

## Wired into the build

Installed and enabled from `_include_base()` in `../../mkd77.sh` — that
function is the one place every variant's include-directory build
funnels through, so this lands in every image regardless of desktop
environment. It's *not* an xbps package, so it couldn't go through the
normal `-S SERVICES` / `enable_services()` path (that requires the
service to already exist under `$ROOTFS/etc/sv`, which only
`install_packages` can provide, and it runs before `-I INCLUDEDIR` is
copied in). Instead `_include_base()` places both the service directory
*and* its `/etc/runit/runsvdir/default/` symlink itself:

```sh
install -Dm755 ./common/acpi-gpe-guard/acpi-gpe-guard.sh \
	"$INCLUDEDIR"/usr/lib/acpi-gpe-guard/acpi-gpe-guard.sh
install -Dm755 ./common/acpi-gpe-guard/run \
	"$INCLUDEDIR"/etc/sv/acpi-gpe-guard/run
ln -sf /etc/sv/acpi-gpe-guard "$INCLUDEDIR"/etc/runit/runsvdir/default/acpi-gpe-guard
```

## If it ever fires

The mask only lasts until reboot — it's a safety net, not a permanent
fix. Check what got masked and how bad it was:

```sh
journalctl -t acpi-gpe-guard    # or wherever this image routes syslog
```

From there, decide whether to mask that GPE permanently (kernel
parameter `acpi_mask_gpe=0xNN`, machine-specific — do **not** default
this on for everyone) or report/investigate the firmware bug.
