REM Code from Microsoft
REM Breakdown and/or modifications by Marlon Singleton

Time /t >> C:\Temp\logfile.log
REM (Breakdown) Just output time and append to logfile.log 
REM ==================================================
REM ==== Clean up the folders ========================
RMDIR /S /q %temp%\MobSvc
MKDIR %Temp%\MobSvc
MKDIR C:\Temp
REM (Breakdown) Remove data from "AppData\Local\Temp" - Make pristine MobSvc directory - MKDIR C:\Temp already exists from line 4 and can be removed
REM ==================================================

REM ==== Copy new files ==============================
COPY M*.* %Temp%\MobSvc
CD %Temp%\MobSvc
REN Micro*.exe MobSvcInstaller.exe
REM (Breakdown) From current directory, copy files starting with "M" to MobSvc and then rename them to MobSvcInstaller.exe
REM ==================================================

REM ==== Extract the installer =======================
MobSvcInstaller.exe /q /x:%Temp%\MobSvc\Extracted
REM (Breakdown) Extract intaller files to Extracted folder
REM ==== Wait 10s for extraction to complete =========
TIMEOUT /t 10
REM =================================================

REM ==== Perform installation =======================
REM =================================================

CD %Temp%\MobSvc\Extracted
whoami >> C:\Temp\logfile.log
SET PRODKEY=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
REG QUERY %PRODKEY%\{275197FC-14FD-4560-A5EB-38217F80CBD1}
IF NOT %ERRORLEVEL% EQU 0 (
	echo "Product is not installed. Goto INSTALL." >> C:\Temp\logfile.log
	GOTO :INSTALL
) ELSE (
	echo "Product is installed." >> C:\Temp\logfile.log

	echo "Checking for Post-install action status." >> C:\Temp\logfile.log
	GOTO :POSTINSTALLCHECK
)

:POSTINSTALLCHECK
	REG QUERY "HKLM\SOFTWARE\Wow6432Node\InMage Systems\Installed Products\5" /v "PostInstallActions" | Find "Succeeded"
	If %ERRORLEVEL% EQU 0 (
		echo "Post-install actions succeeded. Checking for Configuration status." >> C:\Temp\logfile.log
		GOTO :CONFIGURATIONCHECK
	) ELSE (
		echo "Post-install actions didn't succeed. Goto INSTALL." >> C:\Temp\logfile.log
		GOTO :INSTALL
	)

:CONFIGURATIONCHECK
	REG QUERY "HKLM\SOFTWARE\Wow6432Node\InMage Systems\Installed Products\5" /v "AgentConfigurationStatus" | Find "Succeeded"
	If %ERRORLEVEL% EQU 0 (
		echo "Configuration has succeeded. Goto UPGRADE." >> C:\Temp\logfile.log
		GOTO :UPGRADE
	) ELSE (
		echo "Configuration didn't succeed. Goto CONFIGURE." >> C:\Temp\logfile.log
		GOTO :CONFIGURE
	)


:INSTALL
	echo "Perform installation." >> C:\Temp\logfile.log
	UnifiedAgent.exe /Role MS /InstallLocation "C:\Program Files (x86)\Microsoft Azure Site Recovery" /Platform "VmWare" /Silent
	IF %ERRORLEVEL% EQU 0 (
	    echo "Installation has succeeded." >> C:\Temp\logfile.log
		(GOTO :CONFIGURE)
    ) ELSE (
		echo "Installation has failed." >> C:\Temp\logfile.log
		GOTO :ENDSCRIPT
	)

:CONFIGURE
	echo "Perform configuration." >> C:\Temp\logfile.log
	cd "C:\Program Files (x86)\Microsoft Azure Site Recovery\agent"
	UnifiedAgentConfigurator.exe  /CSEndPoint "[CSIP]" /PassphraseFilePath %Temp%\MobSvc\MobSvc.passphrase
	IF %ERRORLEVEL% EQU 0 (
	    echo "Configuration has succeeded." >> C:\Temp\logfile.log
    ) ELSE (
		echo "Configuration has failed." >> C:\Temp\logfile.log
	)
	GOTO :ENDSCRIPT

:UPGRADE
	echo "Perform upgrade." >> C:\Temp\logfile.log
	UnifiedAgent.exe /Platform "VmWare" /Silent
	IF %ERRORLEVEL% EQU 0 (
	    echo "Upgrade has succeeded." >> C:\Temp\logfile.log
    ) ELSE (
		echo "Upgrade has failed." >> C:\Temp\logfile.log
	)
	GOTO :ENDSCRIPT

:ENDSCRIPT
	echo "End of script." >> C:\Temp\logfile.log
