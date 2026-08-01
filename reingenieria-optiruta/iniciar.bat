@echo off
echo ============================================================
echo   OPTIRUTA Web - Iniciando servidor local...
echo ============================================================
echo.
echo IMPORTANTE: La app DEBE abrirse desde un servidor HTTP,
echo NO abriendo los archivos directamente con file://
echo.
where npx >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo Usando npx serve...
    echo Abre: http://localhost:3000
    echo.
    npx -y serve . -p 3000 --no-clipboard
) else (
    where python >nul 2>&1
    if %ERRORLEVEL% == 0 (
        echo Usando Python HTTP server...
        echo Abre: http://localhost:3000
        echo.
        python -m http.server 3000
    ) else (
        echo ERROR: Necesitas Node.js o Python instalado.
        echo Descarga Node.js desde https://nodejs.org
        pause
    )
)
