@echo off
echo ========================================================
echo Installing 16 GUTI APK to Connected Mobile Device...
echo ========================================================
echo Checking connected devices...
adb devices
echo Stopping any existing 16 Guti instance...
adb shell am force-stop com.antigravity.shologuti
echo.
echo Installing build\16_Guti_Release.apk...
adb install -r build\16_Guti_Release.apk
if %ERRORLEVEL% EQU 0 (
    echo.
    echo [SUCCESS] App installed successfully!
    echo Launching 16 Guti (Single Launcher Instance)...
    adb shell am start -n com.antigravity.shologuti/com.godot.game.GodotAppLauncher -a android.intent.action.MAIN -c android.intent.category.LAUNCHER
) else (
    echo.
    echo [FAILED] Please make sure your phone has USB Debugging enabled and the screen is unlocked!
)
pause
