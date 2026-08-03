; PW PDF - Inno Setup installer script
; Build with:  ISCC.exe /DBuildDir="<path to the built app>" pwpdf_setup.iss

#define AppName "PW PDF"
#define AppVersion "1.0.0"
#define AppPublisher "Physics Wallah"
#define AppURL "https://github.com/RaviSoni804426/PW-PDF"
; Deployed app dir produced by build_tools deploy_desktop.py. Override with
; ISCC /D so the installer can also be built from an installed copy when the
; build tree is not around.
#ifndef BuildDir
  #define BuildDir "D:\pw-pdf\build_tools\out\win_64\onlyoffice\DesktopEditors"
#endif
; User-facing launcher inside BuildDir. It is the projicons shim (renamed from
; DesktopEditors.exe): it carries the file-type icons, accepts --new:form, and
; starts editors.exe. Shortcuts must point here, not at editors.exe.
#define MainExe "PWPDF.exe"

[Setup]
AppId={{7A2B9E1C-4D5F-4E6A-9B3C-PWPDF1000001}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
DefaultDirName={autopf}\PW PDF
DefaultGroupName=PW PDF
; Override with ISCC's /O switch.
OutputDir={#SourcePath}installer-output
OutputBaseFilename=PW-PDF-Setup-{#AppVersion}-x64
Compression=lzma2/max
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; Relative to this script, so it keeps working wherever the repo is checked out.
SetupIconFile={#SourcePath}branding\icons\PWPDF.ico
UninstallDisplayIcon={app}\{#MainExe}
UninstallDisplayName={#AppName}
WizardStyle=modern
PrivilegesRequired=admin
DisableProgramGroupPage=yes
ChangesAssociations=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
; Keep rollback copies of patched binaries out of the payload. Do NOT add a
; bare "*.bak" - ONLYOFFICE ships real product files with that extension
; (dictionaries/hyph_sl_SI.dic.bak), and excluding those silently drops
; product data. Only the suffixes our patch scripts create are listed.
Source: "{#BuildDir}\*"; DestDir: "{app}"; Excludes: "*.bak-*,*.bak2,*.bak3"; \
    Flags: ignoreversion recursesubdirs createallsubdirs

; The file-type icons used to be copied in separately from D:\pw-pdf\branding,
; a path that no longer exists. deploy_desktop.py already places them in the
; app's icons\ folder, so they arrive with the payload above - and that folder
; also holds filetype_oxps.ico, which the old explicit list had missed.
Source: "D:\pw-pdf\branding\icons\filetype_oxps.ico"; DestDir: "{app}\icons"

[Icons]
Name: "{autodesktop}\PW PDF"; Filename: "{app}\{#MainExe}"; WorkingDir: "{app}"; IconFilename: "{app}\app.ico"
Name: "{group}\PW PDF"; Filename: "{app}\{#MainExe}"; WorkingDir: "{app}"; IconFilename: "{app}\app.ico"
Name: "{group}\New PDF"; Filename: "{app}\{#MainExe}"; Parameters: "--new:form"; WorkingDir: "{app}"; IconFilename: "{app}\icons\filetype_pdf.ico"
Name: "{group}\Uninstall PW PDF"; Filename: "{uninstallexe}"

[Registry]
; .pdf association (registered as an option; user picks default via Windows Settings)
Root: HKCR; Subkey: ".pdf\OpenWithProgids"; ValueType: string; ValueName: "PWPDF.pdf"; ValueData: ""; Flags: uninsdeletevalue
Root: HKCR; Subkey: "PWPDF.pdf"; ValueType: string; ValueData: "PDF Document"; Flags: uninsdeletekey
Root: HKCR; Subkey: "PWPDF.pdf\DefaultIcon"; ValueType: string; ValueData: "{app}\icons\filetype_pdf.ico"
Root: HKCR; Subkey: "PWPDF.pdf\shell\open\command"; ValueType: string; ValueData: """{app}\{#MainExe}"" ""%1"""

Root: HKCR; Subkey: ".djvu\OpenWithProgids"; ValueType: string; ValueName: "PWPDF.djvu"; ValueData: ""; Flags: uninsdeletevalue
Root: HKCR; Subkey: "PWPDF.djvu"; ValueType: string; ValueData: "DJVU Document"; Flags: uninsdeletekey
Root: HKCR; Subkey: "PWPDF.djvu\DefaultIcon"; ValueType: string; ValueData: "{app}\icons\filetype_djvu.ico"
Root: HKCR; Subkey: "PWPDF.djvu\shell\open\command"; ValueType: string; ValueData: """{app}\{#MainExe}"" ""%1"""

Root: HKCR; Subkey: ".xps\OpenWithProgids"; ValueType: string; ValueName: "PWPDF.xps"; ValueData: ""; Flags: uninsdeletevalue
Root: HKCR; Subkey: "PWPDF.xps"; ValueType: string; ValueData: "XPS Document"; Flags: uninsdeletekey
Root: HKCR; Subkey: "PWPDF.xps\DefaultIcon"; ValueType: string; ValueData: "{app}\icons\filetype_xps.ico"
Root: HKCR; Subkey: "PWPDF.xps\shell\open\command"; ValueType: string; ValueData: """{app}\{#MainExe}"" ""%1"""

Root: HKCR; Subkey: ".oxps\OpenWithProgids"; ValueType: string; ValueName: "PWPDF.oxps"; ValueData: ""; Flags: uninsdeletevalue
Root: HKCR; Subkey: "PWPDF.oxps"; ValueType: string; ValueData: "OpenXPS Document"; Flags: uninsdeletekey
Root: HKCR; Subkey: "PWPDF.oxps\DefaultIcon"; ValueType: string; ValueData: "{app}\icons\filetype_oxps.ico"
Root: HKCR; Subkey: "PWPDF.oxps\shell\open\command"; ValueType: string; ValueData: """{app}\{#MainExe}"" ""%1"""

[Run]
Filename: "{app}\{#MainExe}"; Description: "Launch PW PDF"; Flags: postinstall nowait skipifsilent
