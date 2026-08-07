rem Disable command echo-ing.
@echo off

rem Set DOS drive letter as the current boot drive.
SET DOSDRV=%_CWD%
rem Make all drive letters available.
for %%i in ( A B C D E F G H I J K L M N O P Q R S T U V W X Y Z ) do if "%_CWD%" == "%%i:\" set DOSDRV=%%i:

rem DOSDIR - DOS directory; PATH - executable paths.
SET DOSDIR=%DOSDRV%\FREEDOS
SET PATH=%dosdir%\BIN;%dosdir%\LINKS

rem Set operating system identifiers.
SET OS_NAME=FreeDOS
SET OS_VERSION=1.4

rem Set startup files.
SET AUTOFILE=%DOSDRV%\FDAUTO.BAT
SET CFGFILE=%DOSDRV%\FDCONFIG.SYS

rem Conditional start-up routine based on menu selection.
GOTO %CONFIG%

:1
rem TSR for optical disc support, set drive letter to Z:.
SHSUCDX.COM /D:MSCD000 /L:Z
rem FIXME: Does not handle multiple optical drives.
LINLD cl=@linld.cmd

:2
CLS
ECHO ╔═════════════════════════════════════════════════════════╗
ECHO ║ Afterglow: Boot Diskette (DOS, x86)                     ║
ECHO ╟─────────────────────────────────────────────────────────╢
ECHO ║ Welcome to Afterglow (DOS Boot Diskette)!               ║
ECHO ║                                                         ║
ECHO ║ To configure or rescue your device, please insert the   ║
ECHO ║ diskette labelled "Utilities Diskette".                 ║
ECHO ╟─────────────────────────────────────────────────────────╢
ECHO ║ Commands available from the Utilities Diskette:         ║
ECHO ║                                                         ║
ECHO ║   - DEBUG: Real-mode debugger                           ║
ECHO ║   - DEBUGX: Protected-mode debugger                     ║
ECHO ║   - DOSFSCK: Filesystem checker for FAT12/16/32         ║
ECHO ║   - EDIT: File editor                                   ║
ECHO ║   - FLASHROM: ROM flashing utility                      ║
ECHO ║   - FORMAT: FAT12/16/32 formatter                       ║
ECHO ║   - LISTPCI: List PCI devices on your device            ║
ECHO ║   - LISTVESA: List available VESA video modes           ║
ECHO ║   - MHDD: Hard disk low-level formatter and checker     ║
ECHO ║   - XFDISK: Disk partition editor                       ║
ECHO ╚═════════════════════════════════════════════════════════╝
ECHO
