[Setup]
AppId={{5D87515F-3F5F-4A05-AE86-B9F2A669F218}
AppName=DuoShare
AppVersion=1.0.0
AppPublisher=DuoShare
AppPublisherURL=https://github.com/WeiErLiTeo/DuoShare
AppSupportURL=https://github.com/WeiErLiTeo/DuoShare
AppUpdatesURL=https://github.com/WeiErLiTeo/DuoShare
DefaultDirName={localappdata}\Programs\DuoShare
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=..\build\windows\x64\installer
OutputBaseFilename=DuoShare-Setup
SetupIconFile=..\windows\runner\resources\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\build\windows\x64\runner\Release\duoshare.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{autoprograms}\DuoShare"; Filename: "{app}\duoshare.exe"
Name: "{autodesktop}\DuoShare"; Filename: "{app}\duoshare.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\duoshare.exe"; Description: "{cm:LaunchProgram,DuoShare}"; Flags: nowait postinstall skipifsilent
