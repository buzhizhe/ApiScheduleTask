@echo off
setlocal

set SERVICE_NAME=MyQuartzService
set EXE_NAME=bin\ScheduledTaskService.exe
set EXE_PATH=%~dp0%EXE_NAME%

:menu
cls
echo.
echo ===== .NET 计划任务服务管理 =====
echo 1. 安装服务
echo 2. 卸载服务
echo 3. 退出
echo.
set /p choice=请选择 (1-3): 

if "%choice%"=="1" goto install
if "%choice%"=="2" goto uninstall
if "%choice%"=="3" exit /b
goto menu

:install
echo 正在安装服务：%SERVICE_NAME%
sc stop %SERVICE_NAME% >nul 2>&1
sc delete %SERVICE_NAME% >nul 2>&1


sc create %SERVICE_NAME% binPath= "%EXE_PATH%" start= auto
if %errorlevel% neq 0 (
    echo 安装失败，请确认路径和权限是否正确。
    pause
    goto menu
)

sc description %SERVICE_NAME% "基于 Quartz.NET 的计划任务服务"
sc failure %SERVICE_NAME% reset= 60 actions= restart/5000/restart/5000/restart/5000
sc start %SERVICE_NAME%

echo 服务已安装并启动。
pause
goto menu

:uninstall
echo 正在卸载服务：%SERVICE_NAME%
sc stop %SERVICE_NAME% >nul 2>&1
sc delete %SERVICE_NAME%
echo 服务已卸载。
pause
goto menu
