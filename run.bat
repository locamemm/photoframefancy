@echo off
title PhotoFrameFancy - Kho Khung Anh Nghe Thuat
cd /d "%~dp0"

echo ===================================================
echo     PhotoFrameFancy - Kho Khung Anh Nghe Thuat
echo ===================================================
echo.
echo Dang khoi dong ung dung...
python main.py
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Co loi xay ra khi khoi chay ung dung!
    pause
)
