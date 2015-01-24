 ; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "FLIMfit"
#define MyAppPublisher "Sean Warren"
#define MyAppCopyright "(c) Imperial College London"


; These options need to be set on the commandline, eg. > iscc \dMyAppVersion=x.x.x \dMyAppSystem=64 \dRepositoryRoot="...\Imperial-FLIMfit" "InstallerScript.iss"
;#define MyAppVersion "x.x.x"
;#define MyAppSystem 64 or 32 
;#define RepositoryRoot "...\Imperial-FLIMfit"

; Define Matlab compiler runtime download and required version
#define McrUrl32 "http://www.mathworks.co.uk/supportfiles/downloads/R2014b/deployment_files/R2014b/installers/win32/MCR_R2014b_win32_installer.exe"
#define McrUrl64 "http://www.mathworks.co.uk/supportfiles/downloads/R2014b/deployment_files/R2014b/installers/win64/MCR_R2014b_win64_installer.exe"
#define McrVersionRequired "8.4"

; Define Ghostscript download urls and required version
#define GhostscriptUrl32 "http://ghostscript.googlecode.com/files/gs871w32.exe"
#define GhostscriptUrl64 "http://ghostscript.googlecode.com/files/gs871w64.exe"
#define GhostscriptVersionRequired "8.71"

#include ReadReg(HKEY_LOCAL_MACHINE,'Software\Sherlock Software\InnoTools\Downloader','ScriptPath','')

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
#if MyAppSystem == "32"
#define MyAppArch "x86"
#define MyAppComputer "PCWIN"
ArchitecturesAllowed=x86 x64
#else
#define MyAppArch "x64"
#define MyAppComputer "PCWIN64"
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
#endif

AppId={{5B6988D3-4B10-4DC8-AE28-E29DF8D99C39}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
UsePreviousAppDir=no
DefaultDirName={pf}\{#MyAppName}\{#MyAppName} {#MyAppVersion}
DefaultGroupName={#MyAppName}
OutputDir={#RepositoryRoot}\FLIMfitStandalone\Installer
OutputBaseFilename=FLIMFit {#MyAppVersion} Setup {#MyAppArch}
SetupIconFile={#RepositoryRoot}\FLIMfitFrontEnd\DeployFiles\microscope.ico
Compression=lzma
SolidCompression=yes


ShowLanguageDialog=no
AppCopyright={#MyAppCopyright}
LicenseFile={#RepositoryRoot}\FLIMfitFrontEnd\LicenseFiles\GPL Licence.txt
AllowUNCPath=False
VersionInfoVersion={#MyAppVersion}
MinVersion=0,5.01sp3

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 0,6.1

[Files]
Source: "{#RepositoryRoot}\InstallerSupport\unzip.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall
Source: "{#RepositoryRoot}\InstallerSupport\vcredist_{#MyAppArch}.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall
Source: "{#RepositoryRoot}\FLIMfitStandalone\FLIMfit_{#MyAppVersion}_{#MyAppComputer}\Start_FLIMfit.bat"; DestDir: "{app}"; Flags: ignoreversion {#MyAppSystem}bit
Source: "{#RepositoryRoot}\FLIMfitStandalone\FLIMfit_{#MyAppVersion}_{#MyAppComputer}\FLIMGlobalAnalysis_{#MyAppSystem}.dll"; DestDir: "{app}"; Flags: ignoreversion {#MyAppSystem}bit
Source: "{#RepositoryRoot}\FLIMfitStandalone\FLIMfit_{#MyAppVersion}_{#MyAppComputer}\FLIMfit.exe"; DestDir: "{app}"; Flags: ignoreversion {#MyAppSystem}bit
Source: "C:\Program Files\MATLAB\R2014b\bin\win64\tbb.dll"; DestDir: "{app}"; Flags: ignoreversion {#MyAppSystem}bit
Source: "{#RepositoryRoot}\InstallerSupport\microscope.ico"; DestDir: "{app}"
Source: "{#RepositoryRoot}\FLIMfitFrontEnd\java.opts"; DestDir: "{app}";
[Icons]
Name: "{group}\{#MyAppName} {#MyAppVersion}"; Filename: "{app}\Start_FLIMfit_{#MyAppSystem}.bat"; IconFilename: "{app}\microscope.ico"
Name: "{commondesktop}\{#MyAppName} {#MyAppVersion}"; Filename: "{app}\Start_FLIMfit_{#MyAppSystem}.bat"; Tasks: desktopicon; IconFilename: "{app}\microscope.ico"
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#MyAppName} {#MyAppVersion}"; Filename: "{app}\Start_FLIMfit_{#MyAppSystem}.bat"; Tasks: quicklaunchicon;  IconFilename: "{app}\microscope.ico"

;[Run]
;Filename: "{app}\Start_FLIMfit_{#MyAppSystem}.bat"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent


[Messages]
WinVersionTooHighError=This will install [name/ver] on your computer.%n%nIt is recommended that you close all other applications before continuing.%n%nIf they are not already installed, it will also download and install the Matlab 2012b Compiler Runtime, Visual C++ Redistributable for Visual Studio 2012 Update 1 and Ghostscript 8.71 which are required to run [name]. An internet connection will be required.

[Code]
procedure InitializeWizard();
begin
 itd_init;
 itd_setoption('UI_AllowContinue', '1'); // allow downloads to fail
 //Start the download after the "Ready to install" screen is shown
 itd_downloadafter(wpReady);
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ResultCode : Integer;
begin
 if CurStep=ssPostInstall then begin //Lets install those files that were downloaded for us
  // Unzip and install Matlab MCR if downloaded
  Exec(expandconstant('{tmp}\unzip.exe'), expandconstant('{tmp}\MatlabMCR.zip'), expandconstant('{tmp}'), SW_SHOW, ewWaitUntilTerminated, ResultCode)
  Exec(expandconstant('{tmp}\bin\win{#MyAppSystem}\setup.exe'), '-mode automated', expandconstant('{tmp}'), SW_SHOW, ewWaitUntilTerminated, ResultCode)
  
  // Install Visual Studio Redist
  Exec(expandconstant('{tmp}\vcredist_{#MyAppArch}.exe'), '/passive /norestart', expandconstant('{tmp}'), SW_SHOW, ewWaitUntilTerminated, ResultCode)
  
  // Install Ghostscript if downloaded
  Exec(expandconstant('{tmp}\unzip.exe'), expandconstant('{tmp}\Ghostscript.exe'), expandconstant('{tmp}'), SW_SHOW, ewWaitUntilTerminated, ResultCode)
  Exec(expandconstant('{tmp}\setupgs.exe'), expandconstant('"{pf}\gs"'), expandconstant('{tmp}'), SW_SHOW, ewWaitUntilTerminated, ResultCode)
 end;
end;


function InitializeSetup(): Boolean;
var
  // Declare variables
  MatlabMcrInstalled : Boolean;
  GhostscriptInstalled : Boolean;
  url : String;
  
begin

  // Check if mcr is installed
  MatlabMcrInstalled := RegKeyExists(HKLM,'SOFTWARE\MathWorks\MATLAB Compiler Runtime\{#McrVersionRequired}');
  GhostscriptInstalled := RegKeyExists(HKLM,'SOFTWARE\GPL Ghostscript\{#GhostscriptVersionRequired}');

  if MatlabMcrInstalled = true then
      Log('Required MCR version already installed')
  else
   begin
      Log('Required MCR version not installed')
      if {#MyAppSystem} = 64 then
        url := '{#McrUrl64}'
      else
        url := '{#McrUrl32}';
      Log('Adding MCR Download: ' + url);
      itd_addfile(url,expandconstant('{tmp}\MatlabMCR.zip'));  
    end;  
    
  if GhostscriptInstalled = true then
      Log('Required Ghostscript version already installed')
  else
    begin
      if {#MyAppSystem} = 64 then
        url := '{#GhostscriptUrl64}'
      else
        url := '{#GhostscriptUrl32}';
      Log('Adding Ghostscript Download: ' + url);
      itd_addfile(url,expandconstant('{tmp}\Ghostscript.exe'));    
    end;

  Result := true;
end;


