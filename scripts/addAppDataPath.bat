@echo off

setlocal enabledelayedexpansion

set "_Local=%USERPROFILE%\AppData\Local"
set "_LocalLow=%USERPROFILE%\AppData\LocalLow"
set "_Roaming=%USERPROFILE%\AppData\Roaming"

for %%v in (_Local _Locallow _Roaming) do (
    set "var=%%v"
    set "varName=!var:~1!"
    set "value=!%%v!"
    set "found=0"

    for /f "tokens=1,2 delims==" %%b in ('set') do (
        if "%%b" == "!varName!" (
		echo "Variable !varName! is already set to %%c."
		set "found=1"
        )
    )

    if "!found!"=="0" (
	echo "Variable !varName! is not set, setting it to !value!"
        setx !varName! !value!
    )
)
