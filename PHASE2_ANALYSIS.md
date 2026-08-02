# Phase 2: Codebase Analysis + Dependency Mapping

Baseline: ONLYOFFICE release/v9.4.0 (see VERSIONS.md). Date: 2026-08-02.

## THE CRITICAL RESULT — pdf/ → word/ dependency

**pdf/ uses the word engine in 19 of 83 files — 165 references** (`AscWord`, `CDocumentContent`,
`CDocument`, `CParagraph`, `ParaRun`, `CTable` …). Heaviest users: `src/document.js` (26),
`src/thumbnails.js` (46), `src/forms/textBoxContent.js` (17), `src/GraphicObjects.js` (17),
`src/forms/text.js` (15).

> **VERDICT: word/ DELETE NAHI HOGA — KEEP.** (Exactly as the project brief predicted.)

There is no separate pdf build config at all: `sdkjs/configs/` has only `word.json`,
`cell.json`, `slide.json`, `visio.json`, `externs.json`. **The PDF editor ships inside the
word bundle** — `word.json` includes 236 `word/` files + 57 `pdf/` files.

## Second critical discovery — word bundle needs 9 cell/ files

`word.json` also pulls in the spreadsheet formula engine (used by PDF form calculations
and word fields):

```
cell/model/CellInfo.js            cell/model/Serialize.js
cell/model/FormulaObjects/parserFormula.js    cell/model/SheetMemory.js
cell/model/HeaderFooter.js        cell/model/Workbook.js
cell/model/WorkbookElems.js       cell/utils/utils.js
cell/view/HandlerList.js
```

So `cell/` can NOT be deleted wholesale — these 9 files must survive.

## Full dependency matrix

| Check | Result | Action |
|---|---|---|
| pdf/ → word/ | 165 refs, 19 files | **word/ KEEP** |
| pdf/ → cell/ | 0 | — |
| pdf/ → slide/ | 2 benign (word-namespace `CPresentationBullet`; defensive stub `var CPresentation = CPresentation \|\| function(){}`) | **slide/ DELETE-safe** |
| word.json → slide/ or visio/ | 0 | **slide/, visio/ DELETE-safe** |
| word.json → cell/ | 9 files | **prune cell/, keep 9 files** |
| pdfeditor UI → other editors | 5 trivial (3 help htm + 2 js mentions) | DELETE-safe |
| desktop-sdk PDF routing | routes URLs containing `pdfeditor` natively (client_renderer_wrapper.cpp:1157) | no change needed |

## sdkjs structure (v9.4.0)

| Folder | Size | Verdict |
|---|---|---|
| pdf/ | 40.0 MB, 83 files | KEEP (main module) |
| word/ | 13.3 MB, 234 files | KEEP (PDF depends on it) |
| common/ | 39.8 MB, 525 files | KEEP (shared engine) |
| cell/ | 10.1 MB, 65 files | PRUNE → keep 9 files |
| slide/ | 21.7 MB, 90 files | DELETE |
| visio/ | 0.7 MB, 13 files | DELETE (new in 9.x) |

## web-apps structure

| App | Size | Verdict |
|---|---|---|
| pdfeditor/ | 34.6 MB (main only) | KEEP |
| common/ + api/ | 9.5 MB | KEEP |
| documenteditor/ | 95 MB | DELETE |
| spreadsheeteditor/ | 445 MB | DELETE |
| presentationeditor/ | 67 MB | DELETE |
| visioeditor/ | 6 MB | DELETE |

## Build system control points (how PDF-only build hoga)

1. `sdkjs/build/build.py` supports `--product word` → builds only the word bundle
   (which contains the PDF editor). Driver: `build_tools/scripts/build_js.py:145`
   (`build_sdk_desktop`) — add `--product word` here, or trim `CONFIG_NAMES`/default
   products in build.py. `build.py` `OTHER_FILES` copies `cell/css`, `slide/themes`,
   `pdf/src/engine` assets — slide/cell entries need pruning when sources are deleted.
2. `web-apps/build/Gruntfile.js` `default` task (line ~923) builds all 5 editors →
   change to `['deploy-common-component', 'deploy-pdfeditor-component']`.
3. `build_tools/defaults`: `sdkjs-addons="sdkjs-forms"` → sdkjs-forms repo cloned (done).
4. `configure.py --module desktop` is the module selector; there is no per-editor flag —
   editor selection happens via the two points above.
5. `build_tools/scripts/deploy_desktop.py` copies whole sdkjs deploy + web-apps deploy
   dirs; after stripping, only pdf artifacts will exist so no change needed there.
   It also downloads marketplace plugins from onlyoffice.github.io during deploy.

## Desktop shell (start screen / templates / dialogs) — Phase 3/4 targets

- Start screen source: `desktop-apps/common/loginpage/src/`
  - `paneltemplates.js:86-89` — 4 template category tabs (`Documents`, `Spreadsheets`,
    `Presentations`, `PDFs`) → keep only PDFs (mapping at :341-344).
  - `document-creation-grid.js` — "Create new" grid (data-driven; config comes from
    panelwelcome/model) → PDF-only entries.
- Bundled template files: `desktop-apps/common/templates/<LANG>/{Documents,Forms,
  Presentation,Spreadsheet}` — **PDF templates live in `Forms/` as .pdf files**;
  Documents/Presentation/Spreadsheet contain .dotx/.potx/.xltx → delete those three,
  keep Forms.
- File open dialog filters: `desktop-apps/win-linux/src/components/cfiledialog.cpp`
  (the only file with `*.docx|*.xlsx|*.pptx` filter strings).
- File association: `desktop-apps/win-linux/src/platform_win/association.cpp`.
- Editor type plumbing: `ceditortools.cpp`, `asctabwidget.cpp`, `cascapplicationmanagerwrapper.cpp`,
  `windows/ceditorwindow*.{h,cpp}`, `casctabdata.cpp` (14 files matched editor-type enums).

## core/ and desktop-sdk/

Untouched. core is the C++ conversion/render engine (x2t, PdfReader/PdfWriter,
graphics, fonts) — PDF depends on large parts of it; stripping is high-risk, low-reward.
desktop-sdk (CEF wrapper) already routes PDFs to pdfeditor.

## Risks / notes

- Disk: 27.9 GB free at start; sources ~2.1 GB. Full desktop build (Qt + CEF + core build
  outputs) typically needs 20-40 GB more — tight. May need cleanup or a bigger drive.
- Build prerequisites on Windows: Python, Node.js+grunt, Java (closure compiler),
  Visual Studio C++ toolchain, Qt — availability check pending at Phase 5 start.
- GitHub: single monorepo (real content, nested .git removed; provenance in VERSIONS.md).
  Baseline pushed in 4 chunks to stay under pack limits.
