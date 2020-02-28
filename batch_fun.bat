@Echo OFF
SetLocal EnableDelayedExpansion

Set /A _count=1
Set _nLocal=C:\Program Files\N-able Technologies
Set _regQry=HKLM\Hardware\Description\System\CentralProcessor\0

Reg Query %_regQry% | FindStr /c:x86 1>nul

If %errorlevel% NEQ 0 (
    Set "_nLocal=C:\Program Files (x86)\N-able Technologies"
    Call :el0
)

:: Random Hash work that currently doesn't fit in the script
echo An empty file > empty.log
Set hash=powershell.exe -command "(Get-FileHash -Algorithm SHA1 -Path empty.log).Hash.ToLower()"
For /f "tokens=*" %%i In ('%hash%') Do Set confirm=%%i
Echo Some hash fun.
Echo %confirm%
Echo.

Echo Stopping Windows Agent Maintenance Service
SC STOP "Windows Agent Maintenance Service" 1>nul
Call :sleep 5

Echo Stopping Windows Agent Service
SC STOP "Windows Agent Service" 1>nul
Call :sleep 15

:CHECKAGENT
Wmic PROCESS WHERE "Caption = 'agent.exe'" GET /VALUE | FINDSTR /c:agent.exe 1>nul

Echo Error level 1: %errorlevel%
Goto :eof

If %errorlevel% equ 0 (
    If %_count% gtr 10 (
        Echo Looks like services didn't stop, killing them, 20 more sec ...
        taskkill.exe /f /im agent.exe > nul 2>&1
        taskkill.exe /f /im AgentMaint.exe > nul 2>&1
        SC STOP "Windows Agent Maintenance Service" 1>nul
        SC STOP "Windows Agent Service" 1>nul
        Call :sleep 20
        GOTO :NEXT
    )
    Echo Found process, waiting 20 sec
    ::Echo !_count!
    SET /A _count+=1
    Call :sleep 20
    GOTO :CHECKAGENT
)

:NEXT

Call :delpatch

Echo Starting services ...
SC START "Windows Agent Maintenance Service" 1>nul
SC START "Windows Agent Service" 1>nul
Call :sleep 20

Wmic Process Where "Caption = 'agent.exe'" Get /Value | Findstr /c:agent.exe 1>nul

If %errorlevel% EQU 0 (
    Echo Looks like agent.exe is starting.
) Else (
    Echo Looks like agent.exe is not starting.
)

EndLocal
Goto :eof

::--------- Subroutines ---------

:el0
:: Resetting errorlevel back to 0.
%ComSpec% /c "Exit /b 0"
Exit /b

:sleep
Echo Waiting for %1 secs.
PING 123.45.67.89 -n 1 -w %1000 1>nul
Call :el0
Exit /b

:delpatch
DEL /F /Q /S "%_nLocal%\Windows Agent\bin\Patches.nable" 1>nul
DEL /F /Q /S "%_nLocal%\PatchManagement\metadata\*.*" 1>nul
DEL /F /Q /S "%_nLocal%\PatchManagement\metadata\previous\*.*" 1>nul
DEL /F /Q /S "%_nLocal%\PatchManagement\approvals.xml" 1>nul
DEL /F /Q /S "%_nLocal%\PatchManagement\classificationmetadata.xml" 1>nul
DEL /F /Q /S "%_nLocal%\PatchManagement\patchmetadata.xml" 1>nul
DEL /F /Q /S "%_nLocal%\PatchManagement\productmetadata.xml" 1>nul
Exit /b