@echo off
setlocal


:: ͳһ·������
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

:: ȥ��·��β����б��
if "%SOFT_ROOT:~-1%"=="\" set "SOFT_ROOT=%SOFT_ROOT:~0,-1%"

:: ������ԱȨ��
net session >nul 2>&1 || (
    echo ���Թ���Ա������У�
    pause
    exit /b
)

:: ������Զ�ģʽ����������ʽ�˵�
if "%1"=="auto" goto install

:menu
cls
echo.
echo ===== .NET Web ������� =====
echo 1. ��װ����
echo 2. ж�ط���
echo 3. �˳�
echo.
set /p choice=��ѡ�� (1-3): 

if "%choice%"=="1" goto install
if "%choice%"=="2" goto uninstall
if "%choice%"=="3" exit /b
echo ��Ч����
pause
goto menu

:install
echo ���ڰ�װ����...

:: ���ؼ��ļ�
if not exist "%DOTNET_PATH%" (
    echo [��] ����δ�ҵ� exe������·�� %DOTNET_PATH%
    pause
    goto menu
)

if not exist "%NSSM_PATH%" (
    echo [��] ����δ�ҵ� nssm.exe������·�� %NSSM_PATH%
    pause
    goto menu
)

:: ȷ����־Ŀ¼����
if not exist "%LOG_DIR%" (
    mkdir "%LOG_DIR%"
)

:: ֹͣ���Ƴ��ɷ���
echo ��������ɷ���...
net stop "%SERVICE_NAME%" >nul 2>&1
"%NSSM_PATH%" remove "%SERVICE_NAME%" confirm >nul 2>&1

:: ��װ�·���
echo ����ע�����...
"%NSSM_PATH%" install "%SERVICE_NAME%" "%DOTNET_PATH%"
"%NSSM_PATH%" set "%SERVICE_NAME%" AppDirectory "%SOFT_ROOT%\bin"
"%NSSM_PATH%" set "%SERVICE_NAME%" DisplayName "%SERVICE_DISPLAY%"
"%NSSM_PATH%" set "%SERVICE_NAME%" Description "���� Quartz.NET �Ľӿڼƻ�����"
"%NSSM_PATH%" set "%SERVICE_NAME%" AppStdout "%LOG_DIR%\nssm.log"
"%NSSM_PATH%" set "%SERVICE_NAME%" AppStderr "%LOG_DIR%\nssm-error.log"
"%NSSM_PATH%" set "%SERVICE_NAME%" Start SERVICE_AUTO_START

:: ��������
echo ������������...
net start "%SERVICE_NAME%"

if %errorlevel% equ 0 (
    echo [��] ����װ�ɹ���
    echo ��־�ļ�Ŀ¼��%LOG_DIR%
) else (
    echo [��] ����ʧ�ܣ�������־��%LOG_DIR%��
)

:: ������Զ�ģʽ�������˵�
if "%1"=="auto" exit /b
pause
goto menu

:uninstall
echo ����ж�ط���...
net stop "%SERVICE_NAME%" >nul 2>&1
"%NSSM_PATH%" remove "%SERVICE_NAME%" confirm
echo [��] ��ж�ط���
pause
goto menu
