@echo off
REM Gera as pastas nativas, baixa dependencias e roda os testes.
cd /d "%~dp0"
call flutter create . --project-name cofrinho --org br.edu.cofrinho --platforms=android,ios,windows || exit /b 1
call flutter pub get || exit /b 1
call flutter test || exit /b 1
echo.
echo Pronto! Agora rode: flutter run
