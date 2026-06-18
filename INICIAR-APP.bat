@echo off
REM ============================================================
REM  Caribbean Fest - Arranque de la app (backend + web)
REM  Doble clic en este archivo para levantar todo.
REM  Deja las dos ventanas abiertas mientras uses la app.
REM ============================================================
echo Iniciando Caribbean Fest...

start "Caribbean Fest - BACKEND" cmd /k "cd /d "%~dp0backend" && npm run start:dev"
start "Caribbean Fest - APP" cmd /k "cd /d "%~dp0mobile" && node serve_build.js"

echo.
echo Backend  -> http://localhost:3000/api
echo App web  -> http://localhost:8080
echo.
echo Espera ~30s a que el backend compile, luego abre:
echo    http://localhost:8080
echo.
timeout /t 30 /nobreak >nul
start "" "http://localhost:8080"
echo Listo. (Puedes cerrar ESTA ventana; deja abiertas BACKEND y APP.)
pause
