@echo off
setlocal

set SERVICE_NAME=MyQuartzService
set EXE_NAME=bin\ScheduledTaskService.exe
set EXE_PATH=%~dp0%EXE_NAME%

:menu
cls
echo.
echo ===== .NET �ƻ����������� =====
echo 1. ��װ����
echo 2. ж�ط���
echo 3. �˳�
echo.
set /p choice=��ѡ�� (1-3): 

if "%choice%"=="1" goto install
if "%choice%"=="2" goto uninstall
if "%choice%"=="3" exit /b
goto menu

:install
echo ���ڰ�װ����%SERVICE_NAME%
sc stop %SERVICE_NAME% >nul 2>&1
sc delete %SERVICE_NAME% >nul 2>&1


sc create %SERVICE_NAME% binPath= "%EXE_PATH%" start= auto
if %errorlevel% neq 0 (
    echo ��װʧ�ܣ���ȷ��·����Ȩ���Ƿ���ȷ��
    pause
    goto menu
)

sc description %SERVICE_NAME% "���� Quartz.NET �ļƻ��������"
sc failure %SERVICE_NAME% reset= 60 actions= restart/5000/restart/5000/restart/5000
sc start %SERVICE_NAME%

echo �����Ѱ�װ��������
pause
goto menu

:uninstall
echo ����ж�ط���%SERVICE_NAME%
sc stop %SERVICE_NAME% >nul 2>&1
sc delete %SERVICE_NAME%
echo ������ж�ء�
pause
goto menu
