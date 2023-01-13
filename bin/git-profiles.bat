@echo off
setlocal EnableDelayedExpansion

(set \n=^
%==%
)

set GIT_PROFILES_PATH=%USERPROFILE%\.gitprofiles

if "%1" == "" goto :verify_any_profiles_or_list
if "%1" == "list" goto :list
if "%1" == "new" goto :new
if "%1" == "use" goto :use

goto :eof

:list
    >nul dir "%GIT_PROFILES_PATH%\*" && set ANY_GIT_PROFILES_EXIST=true
    if "%ANY_GIT_PROFILES_EXIST" == "true" (
        for %%f in (%GIT_PROFILES_PATH%\*) do echo %%~nf
    ) else (
        echo ^No git profiles found in %GIT_PROFILES_PATH%
        goto :fail
    )

:use
    if "%2" == "" (
        echo ^Missing required parameter: [profile name]
        echo.
        echo ^Available profiles:
        call :list
        goto :fail
    )
    set GIT_PROFILE_FILE=%GIT_PROFILES_PATH%\%2
    if not exist "%GIT_PROFILE_FILE%" (
        echo ^Profile not found: '%2'
        echo.
        echo ^Available profiles:
        call :list
        goto :fail
    )
    git config --remove-section user
    for /F "tokens=*" %%l in (%GIT_PROFILE_FILE%) do (
        echo git config %%l
        git config %%l
    )
    goto :eof

:new
    set MSGBOX_TITLE=New git profile
    if "!MSGBOX_TEXT!" == "" if "!GIT_PROFILE_NAME!" == "" set MSGBOX_TEXT=Name for this profile
    if "!MSGBOX_TEXT!" == "" if "!GIT_PROFILE_USER_NAME!" == "" set MSGBOX_TEXT=User name
    if "!MSGBOX_TEXT!" == "" if "!GIT_PROFILE_USER_EMAIL!" == "" set MSGBOX_TEXT=User email
    if "!MSGBOX_TEXT!" == "" if "!GIT_PROFILE_USER_KEY!" == "" set MSGBOX_TEXT=User signing key
    call :msgbox_input
    set MSGBOX_TEXT=
    if "!MSGBOX_RESULT!" == "" goto :cancel
    if not "!MSGBOX_RESULT!" == "" if "!GIT_PROFILE_NAME!" == "" ( set GIT_PROFILE_NAME=!MSGBOX_RESULT!&& set MSGBOX_RESULT=)
    if not "!MSGBOX_RESULT!" == "" if "!GIT_PROFILE_USER_NAME!" == "" ( set GIT_PROFILE_USER_NAME=!MSGBOX_RESULT!&& set MSGBOX_RESULT=)
    if not "!MSGBOX_RESULT!" == "" if "!GIT_PROFILE_USER_EMAIL!" == "" ( set GIT_PROFILE_USER_EMAIL=!MSGBOX_RESULT!&& set MSGBOX_RESULT=)
    if not "!MSGBOX_RESULT!" == "" if "!GIT_PROFILE_USER_KEY!" == "" ( set GIT_PROFILE_USER_KEY=!MSGBOX_RESULT!&& set MSGBOX_RESULT=)
    echo ^NAME !GIT_PROFILE_NAME! USER NAME !GIT_PROFILE_USER_NAME!
    if "!GIT_PROFILE_USER_KEY!" == "" goto :new
    set GIT_PROFILE_FILE=%GIT_PROFILES_PATH%/!GIT_PROFILE_NAME!
    if exist "!GIT_PROFILE_FILE!" del "!GIT_PROFILE_FILE!"
    echo user.name "!GIT_PROFILE_USER_NAME!" >> "!GIT_PROFILE_FILE!"
    echo user.email !GIT_PROFILE_USER_EMAIL! >> "!GIT_PROFILE_FILE!"
    echo user.signingkey !GIT_PROFILE_USER_KEY! >> "!GIT_PROFILE_FILE!"
    echo commit.gpgsign true >> "!GIT_PROFILE_FILE!"
    echo ^Created !GIT_PROFILE_FILE!
    goto :eof

:verify_profiles_folder
    if not exist "%GIT_PROFILES_PATH%" (
        set MSGBOX_TITLE=Create new profiles path?
        set MSGBOX_TEXT=Folder not found %GIT_PROFILES_PATH%!\n!!\n!Would you like to create it now?
        call :msgbox_yes_no
        if "!MSGBOX_RESULT!" == "Yes" (
            mkdir "%GIT_PROFILES_PATH%"
        ) else (
            goto :cancel
        )
    )
    goto :eof

:verify_any_profiles_or_list
    >nul dir "%GIT_PROFILES_PATH%\*" && set ANY_GIT_PROFILES_EXIST=true
    if "%ANY_GIT_PROFILES_EXIST" == "true" (
        goto :list
    ) else (
        set MSGBOX_TITLE=Create new git profile?
        set MSGBOX_TEXT=No git profiles have been created!\n!!\n!Would you like to create one now?
        call :msgbox_yes_no
        if "!MSGBOX_RESULT!" == "Yes" (
            set MSGBOX_TEXT=
            call :new
        ) else (
            goto :cancel
        )
    )
    goto :eof

:msgbox_ok
    powershell -c "Add-Type -Assembly System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show(\"${env:MSGBOX_TEXT}\", \"${env:MSGBOX_TITLE}\")"
    goto :eof

:msgbox_yes_no
    set MSGBOX_TYPE=YesNo
    set MSGBOX_RESULT=
    for /f "usebackq delims=" %%i in (`
        powershell -c "Add-Type -Assembly System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show(\"${env:MSGBOX_TEXT}\", \"${env:MSGBOX_TITLE}\", \"${env:MSGBOX_TYPE}\")"
    `) do set MSGBOX_RESULT=%%i
    goto :eof

:msgbox_input
    set MSGBOX_RESULT=
    for /f "usebackq delims=" %%i in (`
        powershell -c "Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.Interaction]::InputBox(\"${env:MSGBOX_TEXT}\", \"${env:MSGBOX_TITLE}\", \"${env:MSGBOX_VALUE}\")"
    `) do set MSGBOX_RESULT=%%i
    goto :eof

:exit
    exit /b 0

:cancel
    echo ^[Exit]

:error
    if not "%ERROR%" == "" (
        set MSGBOX_TITLE=Error
        set MSGBOX_TEXT=%ERROR%
        call :msgbox_ok
    )

:fail
    exit /b 1
