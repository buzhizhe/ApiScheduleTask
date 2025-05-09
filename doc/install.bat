@echo off
setlocal


:: 统一路径定义
set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%"
set "SOFT_ROOT=%CD%"
popd

set "DOTNET_PATH=%SOFT_ROOT%\bin\ScheduledTaskService.exe"
set "NSSM_PATH=%SOFT_ROOT%\nssm.exe"
set "SERVICE_NAME=ApiScheduledTaskService"
set "SERVICE_DISPLAY=ApiScheduledTask"
set "LOG_DIR=%SCRIPT_DIR%\bin\log"
echo SOFT_ROOT

:: 去掉路径尾部反斜杠
if "%SOFT_ROOT:~-1%"=="\" set "SOFT_ROOT=%SOFT_ROOT:~0,-1%"

:: 检查管理员权限
net session >nul 2>&1 || (
    echo 请以管理员身份运行！
    pause
    exit /b
)

:: 如果是自动模式，跳过交互式菜单
if "%1"=="auto" goto install

:menu
cls
echo.
echo ===== .NET Web 服务管理 =====
echo 1. 安装服务
echo 2. 卸载服务
echo 3. 退出
echo.
set /p choice=请选择 (1-3): 

if "%choice%"=="1" goto install
if "%choice%"=="2" goto uninstall
if "%choice%"=="3" exit /b
echo 无效输入
pause
goto menu

:install
echo 正在安装服务...

:: 检查关键文件
if not exist "%DOTNET_PATH%" (
    echo [×] 错误：未找到 exe，请检查路径 %DOTNET_PATH%
    pause
    goto menu
)

if not exist "%NSSM_PATH%" (
    echo [×] 错误：未找到 nssm.exe，请检查路径 %NSSM_PATH%
    pause
    goto menu
)

:: 确保日志目录存在
if not exist "%LOG_DIR%" (
    mkdir "%LOG_DIR%"
)

:: 停止并移除旧服务
echo 正在清理旧服务...
net stop "%SERVICE_NAME%" >nul 2>&1
"%NSSM_PATH%" remove "%SERVICE_NAME%" confirm >nul 2>&1

:: 安装新服务
echo 正在注册服务...
"%NSSM_PATH%" install "%SERVICE_NAME%" "%DOTNET_PATH%"
"%NSSM_PATH%" set "%SERVICE_NAME%" AppDirectory "%SOFT_ROOT%\bin"
"%NSSM_PATH%" set "%SERVICE_NAME%" DisplayName "%SERVICE_DISPLAY%"
"%NSSM_PATH%" set "%SERVICE_NAME%" Description "基于 Quartz.NET 的接口计划任务"
"%NSSM_PATH%" set "%SERVICE_NAME%" AppStdout "%LOG_DIR%\nssm.log"
"%NSSM_PATH%" set "%SERVICE_NAME%" AppStderr "%LOG_DIR%\nssm-error.log"
"%NSSM_PATH%" set "%SERVICE_NAME%" Start SERVICE_AUTO_START

:: 启动服务
echo 正在启动服务...
net start "%SERVICE_NAME%"

if %errorlevel% equ 0 (
    echo [√] 服务安装成功！
    echo 日志文件目录：%LOG_DIR%
) else (
    echo [×] 启动失败，请检查日志，%LOG_DIR%！
)

:: 如果是自动模式，跳过菜单
if "%1"=="auto" exit /b
pause
goto menu

:uninstall
echo 正在卸载服务...
net stop "%SERVICE_NAME%" >nul 2>&1
"%NSSM_PATH%" remove "%SERVICE_NAME%" confirm
echo [√] 已卸载服务
pause
goto menu
