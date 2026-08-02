# PW PDF — Source Provenance

Fork baseline: **ONLYOFFICE release/v9.4.0** (cloned 2026-08-02, shallow single-branch).

Original plan referenced `nicedoc/*` forks, but only 4 of 8 repos existed there and they were
frozen at ~v8.x (March 2025). To keep all components version-consistent, everything was cloned
from ONLYOFFICE official at the `release/v9.4.0` branch instead.

| Repo | Source | Branch | Commit |
|------|--------|--------|--------|
| build_tools | ONLYOFFICE/build_tools | release/v9.4.0 | cf4cac0 |
| core | ONLYOFFICE/core | release/v9.4.0 | 55e5f973 |
| desktop-apps | ONLYOFFICE/desktop-apps | release/v9.4.0 | 3ad4e29 |
| desktop-sdk | ONLYOFFICE/desktop-sdk | release/v9.4.0 | c84d59c |
| dictionaries | ONLYOFFICE/dictionaries | master | d3223bb |
| document-templates | ONLYOFFICE/document-templates | master | 71430c9 |
| sdkjs | ONLYOFFICE/sdkjs | release/v9.4.0 | d8e4124 |
| sdkjs-forms | ONLYOFFICE/sdkjs-forms | release/v9.4.0 | 2e3dd66 |
| web-apps | ONLYOFFICE/web-apps | release/v9.4.0 | 1993a6d8 |

`sdkjs-forms` was added beyond the original 8-repo plan because `build_tools/defaults`
declares `sdkjs-addons="sdkjs-forms"` — the desktop word/pdf bundle build requires it
(PDF forms functionality).

License: AGPL v3 (inherited from ONLYOFFICE).
