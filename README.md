# minisforum_ec — HPBSD fork

Linux kernel module that controls both fans of several Minisforum mini PCs through
their ITE embedded controller. It shows up in `sensors` and runs its own temperature
curves, with no userspace daemon.

Fork of [mordilloSan/fan_control](https://github.com/mordilloSan/fan_control) with:

- **HPBSD support** — Minisforum UM880 Pro / UM890 Pro (EliteMini, Ryzen 8845HS /
  8945HS, EC firmware 0.1/0.2), verified on live hardware. Ported from the `hpbsd`
  profile of [FanControl.MinisforumUM](https://github.com/zuyan9/FanControl.MinisforumUM);
  the module's admission check fingerprint-matches the ported CPU table against the
  live EC, so a correct load is itself proof the port is byte-accurate.
- **Linearly interpolated curves** — the goal varies continuously with temperature
  between curve points instead of holding each point's code until the next one.
  Default curves are flat across the idle band, then ramp smoothly.
- **CachyOS / clang build support** — the kernel there is built with clang; both the
  local Makefile and the DKMS rule pass the right toolchain. Plus an install script
  with boot autoload.

## Supported boards

Admission is fail-closed: exact DMI tuple + EC firmware version + controller
signature + byte-exact firmware table fingerprints. Anything unexpected refuses
to load and leaves both fans with the firmware.

| Board | Models | DMI product | EC | sys code max | CPU min code |
|---|---|---|---|---|---|
| F7BSI / F7BSW | UM760/870 Slim, UM760/870/880 Plus | `EliteMini Series` | 0.5 | 51 | 6 |
| F7BSC | UM760/780/790 Pro | `Venus series` | 2.6 | 51 | 10 |
| **HPBSD** | **UM880 Pro, UM890 Pro** | `EliteMini Series` | **0.1 / 0.2** | **40** | 10 |

### HPBSD verification record (UM880 Pro, BIOS 1.02, EC 0.1)

- Admission: all fingerprints pass on first load (`CPU table Performance (0xb2)`).
- Idle: CPU fan 1900 → ~1020 RPM, system fan 1544 → ~930 RPM, EC temps 37–38 °C.
- Stability: 40 s sampling within ±25 RPM, no hunting; load test shows the
  interpolated goal tracking temperature continuously (+46 RPM/°C in the ramp band).

## Install

### Arch / CachyOS

```bash
sudo pacman -S linux-cachyos-headers   # match your kernel
git clone <this repo> && cd <repo>
sudo bash install-dkms.sh              # DKMS register + build + boot autoload
```

### Debian / Ubuntu (upstream flow)

See the upstream README in git history; the source layout and dkms.conf are
unchanged apart from the toolchain flags (drop `CC=clang LD=ld.lld` from
`MAKE[0]` if your kernel is gcc-built).

### Verify

```bash
sensors 'minisforum_ec-*'
sudo cat /sys/kernel/debug/minisforum_ec/state   # fingerprints, tables, RPM, modes
```

## Curves

Points are `temp:rpm` (nominal; code × 100), up to 8 per fan, temperatures
ascending. **Between points the goal is linearly interpolated**; a `firmware`
point is never interpolated into — the code below it holds until the handoff.
Keep a flat pair across your idle band (e.g. `25:1000,42:1000`), or interpolation
will idle the fan higher than the lower point.

```bash
echo '0:0,25:1000,42:1000,55:1600,66:firmware' | \
  sudo tee /sys/module/minisforum_ec/parameters/cpu_curve
echo '0:0,25:1000,42:1000,50:1600,55:firmware' | \
  sudo tee /sys/module/minisforum_ec/parameters/system_curve
```

Persist via `/etc/modprobe.d/minisforum_ec.conf`:
`options minisforum_ec cpu_curve=... system_curve=...`

Behaviour and safety (stepping, hysteresis, hunting fallback, 80/55 °C limits,
watchdog, suspend restore) are unchanged from upstream; see its README in git
history. On HPBSD the system-fan target domain tops out at code 40, enforced at
every validation site.

## Credits & license

- Register map, admission rules and write/restore sequences:
  [FanControl.MinisforumUM](https://github.com/zuyan9/FanControl.MinisforumUM) by zuyan9
  (HPBSD profile: firmware-derived data, first live verification here).
- Module: [mordilloSan/fan_control](https://github.com/mordilloSan/fan_control).
- GPL-2.0, same as upstream.
