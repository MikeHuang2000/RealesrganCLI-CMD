@echo off
setlocal enabledelayedexpansion

:: =================================================================
:: ==            Real-ESRGAN NCNN Vulkan �������ű�             ==
:: =================================================================

:: --- ����·������ ---
:: %~dp0 ����ű����ڵ�Ŀ¼
set "base_dir=%~dp0"
set "exe_path=%base_dir%realesrgan-ncnn-vulkan.exe"
set "models_dir=%base_dir%models"
set "input_dir=%base_dir%input"
set "output_dir=%base_dir%output"
set "storage_dir=%base_dir%storage"
set "temp_output_dir=%base_dir%temp_output"

:: --- ����������Ƿ���� ---
if not exist "%exe_path%" (
    echo.
    echo  ����: δ�ڵ�ǰĿ¼�ҵ� realesrgan-ncnn-vulkan.exe !
    echo  ��ȷ���˽ű�����������ͬһ�ļ����¡�
    echo.
    pause
    exit /b
)

:: --- ������Ҫ��Ŀ¼ ---
for %%d in ("%input_dir%" "%output_dir%" "%storage_dir%" "%temp_output_dir%") do (
    if not exist %%d mkdir %%d
)

:: =================================================================
:: ==                         ���˵�                             ==
:: =================================================================
:main_menu
cls
echo.
echo  =======================================================
echo  =            Real-ESRGAN NCNN Vulkan ������           =
echo  =======================================================
echo.
echo  ˵��:
echo  - ���������ͼƬ���� input �ļ��С�
echo  - ������ͼƬ�����ʱ��������浽 output �ļ��С�
echo  - ��ѡ��"�����ƶ�"��ԭʼ�ļ��������� storage �ļ��С�
echo.
echo  --------------------   ���ܲ˵�   ---------------------
echo.
echo    [1] �г����п���ģ��
echo.
echo    [2] ���������ļ� (����ԭʼ�ļ��Ƶ�storage)
echo    [3] ���������ļ� (���������ƶ�ԭʼ�ļ�)
echo.
echo    [4] ���ƶ��ļ� (��input�������ļ��Ƶ�storage)
echo    [5] ɾ�����������ļ� (input�ļ����������ļ�)
echo.
echo    [6] ����Դ�������д� input �ļ���
echo    [7] ����Դ�������д� output �ļ���
echo.
echo    [0] �˳�
echo.
echo  -------------------------------------------------------

set /p "choice=������ѡ���Ų����س�: "

if "%choice%"=="1" goto list_models
if "%choice%"=="2" goto process_and_move
if "%choice%"=="3" goto process_only
if "%choice%"=="4" goto move_only
if "%choice%"=="5" goto delete_input
if "%choice%"=="6" goto open_input_folder
if "%choice%"=="7" goto open_output_folder
if "%choice%"=="0" exit /b
echo.
echo  ��Ч�����룬������ѡ��
timeout /t 2 /nobreak >nul
goto main_menu


:: =================================================================
:: ==                       ����ʵ�ֲ���                          ==
:: =================================================================

:list_models
cls
echo.
echo  --------------------   ����ģ���б�   ---------------------
call :get_model_list
echo  -------------------------------------------------------
echo.
pause
goto main_menu


:process_and_move
set "action=process_and_move"
goto start_processing

:process_only
set "action=process_only"
goto start_processing


:start_processing
cls
:: ���input�ļ����Ƿ�Ϊ��
dir /b /a-d "%input_dir%\*" >nul 2>&1
if errorlevel 1 (
    echo.
    echo  ����: input �ļ����ǿյģ�û���ļ����Դ���
    echo.
    pause
    goto main_menu
)

:: 1. ���û�ѡ��ģ��
call :select_model
if "%selected_model%"=="" goto main_menu

:: 2. �����ʱ����ļ��У��Է��ϴ������ж�
echo.
echo  ����������ʱ�ļ���...
del /q "%temp_output_dir%\*" >nul 2>&1

:: 3. ִ����������
echo.
echo  =======================================================
echo  ����ʹ��ģ�� [!selected_model!] ��ʼ��������...
echo  ����·��: %input_dir%
echo  ��ʱ���: %temp_output_dir%
echo  =======================================================
echo.
"%exe_path%" -i "%input_dir%" -o "%temp_output_dir%" -n !selected_model! -m "%models_dir%" -f png

if errorlevel 1 (
    echo.
    echo  ����: Real-ESRGAN ����ʧ�ܣ����������Ϣ��
    echo.
    pause
    goto main_menu
)

echo.
echo  ����������ɣ��������������ƶ��ļ�...

:: 4. ��ȡ��ǰʱ��� (��ʽ: YYYY-MM-DD_HH-MM-SS)
for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value') do set "dt=%%a"
set "timestamp=%dt:~0,4%-%dt:~4,2%-%dt:~6,2%_%dt:~8,2%-%dt:~10,2%-%dt:~12,2%"

:: 5. ������ʱ�ļ��У����������ƶ�����������ļ���
set /a processed_count=0
for %%f in ("%temp_output_dir%\*") do (
    set "new_name=%%~nf_!timestamp!%%~xf"
    echo  �����ƶ�: %%~nxf --^> !new_name!
    move "%%f" "%output_dir%\!new_name!" >nul
    set /a processed_count+=1
)

echo.
echo  �ɹ������������� !processed_count! ���ļ���
echo.

:: 6. ����ѡ������Ƿ��ƶ�ԭʼ�ļ�
if "%action%"=="process_and_move" (
    echo  ���ڽ�ԭʼ�ļ��ƶ��� storage �ļ���...
    move /y "%input_dir%\*" "%storage_dir%" >nul
    echo  ԭʼ�ļ��ƶ���ɡ�
    echo.
)

:: 7. ������ļ���
echo  ������ɣ����ڴ� output �ļ���...
explorer.exe "%output_dir%"

pause
goto main_menu


:move_only
cls
dir /b /a-d "%input_dir%\*" >nul 2>&1
if errorlevel 1 (
    echo.
    echo  ����: input �ļ����ǿյģ�û���ļ������ƶ���
    echo.
    pause
    goto main_menu
)
echo.
echo  ���ڽ� input �ļ����ڵ������ļ��ƶ��� storage �ļ���...
move /y "%input_dir%\*" "%storage_dir%" >nul
echo.
echo  �����ļ��ƶ���ɣ�
echo.
pause
goto main_menu


:delete_input
cls
dir /b /a-d "%input_dir%\*" >nul 2>&1
if errorlevel 1 (
    echo.
    echo  ��ʾ: input �ļ����Ѿ��ǿյġ�
    echo.
    pause
    goto main_menu
)
echo.
echo  ����: �˲���������ɾ�� input �ļ����ڵ������ļ���
set /p "confirm=��ȷ��Ҫ������? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo.
    echo  ������ȡ����
    pause
    goto main_menu
)

echo.
echo  ����ɾ��...
del /q "%input_dir%\*"
echo.
echo  input �ļ����ڵ������ļ���ɾ����
echo.
pause
goto main_menu


:open_input_folder
echo.
echo  ���ڴ� input �ļ���...
explorer.exe "%input_dir%"
goto main_menu

:open_output_folder
echo.
echo  ���ڴ� output �ļ���...
explorer.exe "%output_dir%"
goto main_menu


:: =================================================================
:: ==                       �����ӳ���                            ==
:: =================================================================

:get_model_list

set /a model_count=0
for /f "delims=" %%f in ('dir /b "%models_dir%\*.param"') do (
    set /a model_count+=1
    echo    [!model_count!] %%~nf
    set "model_!model_count!=%%~nf"
)

if %model_count% equ 0 (
    echo  �����Ҳ���ģ�ͣ�
)

exit /b


:select_model
echo.
echo  --------------------   ��ѡ��һ��ģ��   ---------------------
call :get_model_list
echo  -------------------------------------------------------
echo.

if %model_count% equ 0 (
    set "selected_model="
    exit /b
)

:prompt_model
set "selected_model="
set /p "model_num=������ģ�ͱ�� (1-%model_count%): "

if %model_num% lss 1 (
    echo  ������Ч�����������롣
    goto prompt_model
)
if %model_num% gtr %model_count% (
    echo  ������Ч�����������롣
    goto prompt_model
)

call set "selected_model=%%model_%model_num%%%"
exit /b