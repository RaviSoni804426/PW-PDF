# PW PDF — Windows build setup

What the v9.4 build actually needs on Windows, and the non-obvious things that
have to be true before `make.py` will run end to end.

## Toolchain

| Component | Version | Notes |
|---|---|---|
| Visual Studio | **2019** (v142 toolset) | v9.4 `build_tools` has no VS2022 support — boost 1.72's `bootstrap.bat` and V8 8.9's `vs_toolchain.py` both accept only 2017/2019. |
| Qt | **5.15.2 msvc2019_64** | Installed with `python -m aqt install-qt windows desktop 5.15.2 win64_msvc2019_64 -O C:\Qt`. Qt 6.x needs VS2022 and is not usable here. |
| Windows SDK | 10.0.19041.0 | Already present. "Debugging Tools for Windows" is *not* required (see patch below). |
| Python | 3.11 | Use `python -m pip`, not bare `pip` (that resolves to a different interpreter on this machine). |
| Node.js + grunt-cli, Java | any recent | For the JS/web-apps stage. |

On this machine VS2019 lives at a non-default path: `C:\BuildTools2019`.

## Configure

```
cd build_tools
python configure.py --module desktop --platform win_64 --update 0 --qt-dir "C:/Qt/5.15.2" --vs-version 2019
```

`--update 0` is required: this repo is a monorepo with no per-component `.git`,
so `build_tools` must not try to pull subrepos.

## Launching the build

`make.py` must run from **cmd/PowerShell**, never from Git Bash, and with the
VS2019 environment applied:

```
cmd /c "call C:\BuildTools2019\VC\Auxiliary\Build\vcvarsall.bat x64 && ^
  set vs2019_install=C:\BuildTools2019&& ^
  set GYP_MSVS_OVERRIDE_PATH=C:\BuildTools2019&& ^
  set GYP_MSVS_VERSION=2019&& ^
  set DEPOT_TOOLS_WIN_TOOLCHAIN=0&& ^
  set DEPOT_TOOLS_UPDATE=0&& ^
  cd /d D:\pw-pdf\build_tools && python make.py"
```

Why each piece matters:

- **Not Git Bash** — the agent/Git-Bash environment sets
  `NoDefaultCurrentDirectoryInExePath=1`, which stops cmd from running
  `bootstrap.bat` / `make.py` out of the current directory. Boost's bootstrap
  fails with "'bootstrap.bat' is not recognized" purely because of this.
- **`vs2019_install`** — V8's `build/vs_toolchain.py` only probes
  `%ProgramFiles(x86)%\Microsoft Visual Studio\2019\{Community,BuildTools,…}`.
  With VS at `C:\BuildTools2019` it must be told explicitly, or `gn gen` dies
  with "No supported Visual Studio can be found".
- **`DEPOT_TOOLS_UPDATE=0`** — keeps depot_tools from self-updating and
  reverting the local patches listed below.

## V8 lives on C:, not D:

V8 (checkout + DEPS + build output) needs roughly 10 GB and D: does not have
it. The whole `v8_89` directory therefore lives at `C:\pwpdf_v8`, exposed to
the build through an NTFS junction:

```
mklink /J D:\pw-pdf\core\Common\3dParty\v8_89 C:\pwpdf_v8
```

**The junction must be at the `v8_89` level, not at `v8_89\v8`.** depot_tools
assumes the gclient root, `.cipd` cache, and the checkout all sit on one
volume. Junctioning only `v8/` puts the gclient root on D: and the checkout on
C:, and then every layer breaks in turn:

- `gclient_utils.safe_replace` → `OSError [WinError 17]` (cross-device rename)
- `gclient_paths.FindGclientRoot` → `ValueError: path is on mount 'C:', start on mount 'D:'`
- `cipd` (a Go binary, unpatchable) → "cannot move the file to a different disk drive"

With the junction at the top level, every path resolves to C: and all of the
above disappear.

## Local patches

Two are in-repo and tracked:

- `build_tools/scripts/config.py` — detects VS2019 at `C:\BuildTools2019`.
- `build_tools/scripts/core_common/modules/v8_89.py` — the V8 fetch/sync steps
  are made idempotent so an existing checkout is not re-fetched, and each stage
  is guarded independently.

Two are inside the V8 tree (untracked, under `C:\pwpdf_v8`, recreate if V8 is
ever re-fetched):

- `depot_tools/gclient_utils.py` → `safe_replace` falls back to `shutil.move`
  on a cross-device rename.
- `depot_tools/gclient_paths.py` → `FindGclientRoot` falls back to comparing
  logical paths when `relpath` spans mounts.
- `v8/build/vs_toolchain.py` → `_CopyDebugger` warns instead of raising when
  the Debugging Tools DLLs are absent. Those DLLs only matter for debug stack
  symbolization; a release build does not need them.

## Bootstrapping V8 by hand

If `fetch v8` fails partway, the checkout can be completed directly and
`v8_89.py` will skip the fetch on the next run:

```
cd C:\pwpdf_v8\v8
git fetch origin "+refs/branch-heads/8.9:refs/remotes/branch-heads/8.9" --no-tags
git checkout branch-heads/8.9
cd C:\pwpdf_v8
set PATH=C:\pwpdf_v8\depot_tools;%PATH%
gclient sync --force --no-history
```

The pinned version is V8 **8.9.255.25**.

## Build order

`boost → cef → icu → openssl → curl → websocket → v8 → html2 → iwork → md →
hunspell → harfbuzz → glew → hyphen → googletest → brotli → heif` then the core
C++ engine, the JS bundles (`sdkjs` word bundle + `web-apps` pdfeditor), and
finally the Qt desktop shell and deploy step.

Modules are skipped when their outputs already exist, so a re-run after a
failure resumes rather than restarting.
