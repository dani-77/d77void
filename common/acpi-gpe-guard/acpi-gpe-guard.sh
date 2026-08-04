#!/bin/sh
# acpi-gpe-guard.sh — detects and masks a runaway ACPI GPE (General
# Purpose Event) currently in a storm.
#
# Background: some laptop firmware has a buggy GPE handler that never
# clears its status bit, so the kernel re-fires the same event
# thousands of times per second, forever — a genuine hardware/firmware
# bug, not anything Linux is doing wrong. It's invisible to top/ps
# (the work happens in kernel/interrupt context), but shows up as a
# steady, otherwise-unexplained floor of "sy" CPU time and a high
# context-switch rate system-wide. Found by comparing /proc/interrupts'
# IRQ 9 (the ACPI SCI line) growth against each
# /sys/firmware/acpi/interrupts/gpeXX counter — on the machine this was
# first diagnosed on, one GPE (gpe0D) accounted for essentially all of
# it: ~1000-10000+ interrupts/sec, sustained since boot.
#
# This script does NOT hardcode which GPE to mask — the specific
# number is a firmware/machine detail, so a value that's correct on
# one laptop can be meaningless (or, worse, a legitimate event) on
# another. Instead it takes two counter samples SAMPLE_SECS apart and
# masks whichever GPE(s) exceed THRESHOLD_PER_SEC, whatever their
# number — safe to ship in a general-purpose image built for unknown
# hardware.
#
# "mask" (not "disable") is used deliberately: it's the mechanism the
# kernel documents specifically for GPE storms, since it overrides the
# reference count a plain "disable" write respects — and which the
# stuck GPE's own re-registration can just re-enable, as happened when
# this was first diagnosed by hand (disable: no effect; mask: worked).
#
# The mask only lasts until reboot — this is a safety net against a
# runaway condition, not a permanent fix. If it fires, check this
# script's log output (wherever your logging setup routes `logger -t
# acpi-gpe-guard`) for which GPE got masked, then decide whether to
# mask it permanently via an `acpi_mask_gpe=` kernel parameter or
# investigate/report the firmware bug instead.
#
# Safe to run by hand for one-off diagnosis (just `sh
# acpi-gpe-guard.sh`) or from a periodic service — see the
# accompanying `run` script for the latter.

set -eu

GPE_DIR="/sys/firmware/acpi/interrupts"
SAMPLE_SECS=2
THRESHOLD_PER_SEC=100
TAG="acpi-gpe-guard"

log() {
    logger -t "$TAG" "$1" 2>/dev/null || printf '%s: %s\n' "$TAG" "$1" >&2
}

[ -d "$GPE_DIR" ] || exit 0

# Emits "name count" for every real, currently-unmasked GPE counter.
# Skips "invalid" entries (not a real event on this hardware) and
# anything already masked (nothing to do, and re-checking it would
# always look like 0/sec).
snapshot() {
    for f in "$GPE_DIR"/gpe??; do
        [ -e "$f" ] || continue
        line=$(cat "$f" 2>/dev/null) || continue
        case "$line" in
            *invalid*) continue ;;
        esac
        case "$line" in
            *unmasked*) : ;;
            *masked*) continue ;;
        esac
        count=$(printf '%s\n' "$line" | awk '{print $1}')
        case "$count" in ''|*[!0-9]*) continue ;; esac
        printf '%s %s\n' "${f##*/}" "$count"
    done
}

before=$(snapshot)
sleep "$SAMPLE_SECS"
after=$(snapshot)

printf '%s\n' "$after" | while read -r name count_after; do
    [ -n "${name:-}" ] || continue
    count_before=$(printf '%s\n' "$before" | awk -v n="$name" '$1==n{print $2}')
    [ -n "$count_before" ] || continue
    delta=$((count_after - count_before))
    [ "$delta" -gt 0 ] || continue
    rate=$((delta / SAMPLE_SECS))
    if [ "$rate" -ge "$THRESHOLD_PER_SEC" ]; then
        if printf 'mask\n' > "$GPE_DIR/$name" 2>/dev/null; then
            log "masked $name: ${rate}/sec over ${SAMPLE_SECS}s — firmware GPE storm, see script header"
        else
            log "WARNING: $name is storming at ${rate}/sec but masking it failed (needs root)"
        fi
    fi
done
