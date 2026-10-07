@echo off
title PhotoFrameFancy - Flutter Mobile
cd /d "%~dp0"
echo ========================================================
echo   PhotoFrameFancy - Khoi chay ban Mobile (Flutter)
echo ========================================================
echo.
echo 1. Chay ngay tren trinh duyet Edge (Web Preview)
echo 2. Chay tren thiet bi Android (Dien thoai hoac May ao)
echo 3. Dong goi file APK de cai len dien thoai (flutter build apk)
echo.
set /p choice="Nhap lua chon (1, 2 hoac 3): "

if "%choice%"=="1" (
    echo Dang khoi chay tren Edge Web...
    flutter run -d edge
) else if "%choice%"=="2" (
    echo Dang tim thiet bi Android de chay...
    flutter run
) else if "%choice%"=="3" (
    echo Dang dong goi file APK...
    flutter build apk --release
) else (
    flutter run -d edge
)
pause
