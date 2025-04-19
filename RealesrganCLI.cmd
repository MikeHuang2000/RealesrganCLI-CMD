@echo off
setlocal
setlocal enabledelayedexpansion

:: ���û���·��
set "root=%~dp0"
set "models_dir=%root%models"
set "input_dir=%root%input"
set "output_dir=%root%output"
set "storage_dir=%root%storage"
set "exe_path=%root%realesrgan-ncnn-vulkan.exe"

:: ������ҪĿ¼
for %%d in ("%input_dir%" "%output_dir%" "%storage_dir%") do (
    if not exist %%d mkdir %%d
)

:: ���ģ��Ŀ¼
if not exist "%models_dir%" (
    echo Error: Models directory not found!
    pause
    exit /b 1
)

::ʹ��˵��
echo ����Ҫ�Ŵ��ͼƬ����input�ļ����£�֮��Ŵ���ͼƬ�������output�ļ����У�ԭ�����ļ��ƶ���storage�ļ�����
echo �������ѡ��ģ�ͣ�ģ����modelsĿ¼��
echo.
echo ------------------------------------------------------
echo.

:: �û�����ѡ��
:operation
echo ��ѡ�������
echo [s] �����ƶ��ļ�
echo [p] �������ļ�
echo [m] ���ƶ��ļ�
echo [d] ɾ�����������ļ�
echo [f] ����Դ�������д�input�ļ���
set /p "cmd=����������(s/m/d/f)��"

if /i "%cmd%" neq "s" if /i "%cmd%" neq "m" if /i "%cmd%" neq "d" if /i "%cmd%" neq "f" if /i "%cmd%" neq "p" (
    echo ��Ч���
    goto operation
)

if /i "%cmd%"=="f" (
    explorer.exe "%~dp0input"
    echo �Ѵ�input�ļ���
    goto operation
)


:: ö�ٿ���ģ��
echo ����ģ���б�
set /a model_count=0
set "model_list="

for /f "delims=" %%f in ('dir /b /a-d "%models_dir%\*.bin" 2^>nul') do (
    set "model_name=%%~nf"
    set "model_name=!model_name:.bin=!"
    
    :: ȥ�ؼ��
    set "exists=0"
    for %%m in (!model_list!) do if "%%m"=="!model_name!" set exists=1
    
    if !exists! equ 0 (
        set /a model_count+=1
        set "model_!model_count!=!model_name!"
        set "model_list=!model_list! !model_name!"
        echo [!model_count!] !model_name!
    )
)

if %model_count% equ 0 (
    echo ����δ�ҵ��κ�ģ���ļ���
    pause
    exit /b 1
)

:: �û�ѡ��ģ��
:select_model
set /p "model_num=��ѡ��ģ�ͱ��(1-%model_count%)��"
if %model_num% lss 1 goto select_model
if %model_num% gtr %model_count% goto select_model

for /l %%i in (1,1,%model_count%) do (
    if %%i equ %model_num% (
        call set "selected_model=%%model_%%i%%"
    )
)



:: ��ȡ��ǰʱ���
for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value') do set "datetime=%%a"
set "timestamp=%datetime:~0,8%_%datetime:~8,6%"
set "timestamp=%timestamp: =0%"

:: �����ļ�����
if /i "%cmd%"=="s" (
    for %%f in ("%input_dir%\*.jpg" "%input_dir%\*.jpeg" "%input_dir%\*.png" "%input_dir%\*.webp") do (
        if exist "%%f" (
            echo ���ڴ���: %%~nxf
            "%exe_path%" -i "%%f" -o "%output_dir%\%%~nf_realesrganed%%~xf" -m "%models_dir%" -n "%selected_model%"
            call :move_file "%%f"
        )
    )
)

if /i "%cmd%"=="p" (
    for %%f in ("%input_dir%\*.jpg" "%input_dir%\*.jpeg" "%input_dir%\*.png" "%input_dir%\*.webp") do (
        if exist "%%f" (
            echo ���ڴ���: %%~nxf
            "%exe_path%" -i "%%f" -o "%output_dir%\%%~nf_realesrganed%%~xf" -m "%models_dir%" -n "%selected_model%"
        )
    )
)

if /i "%cmd%"=="m" (
    for %%f in ("%input_dir%\*.jpg" "%input_dir%\*.jpeg" "%input_dir%\*.png" "%input_dir%\*.webp") do (
        if exist "%%f" call :move_file "%%f"
    )
)

if /i "%cmd%"=="d" (
    del /q "%input_dir%\*" >nul 2>&1
    echo ��ɾ�����������ļ�
)


echo ������ɣ�
pause
exit /b

:: �ļ��ƶ��ӳ���
:move_file
set "file=%~1"
set "filename=%~nx1"
set "name=%~n1"
set "ext=%~x1"

if exist "%storage_dir%\%filename%" (
    set "newname=%name%_%timestamp%%ext%"
    move /y "%file%" "%storage_dir%\%newname%" >nul
) else (
    move /y "%file%" "%storage_dir%\" >nul
)
exit /b
endlocal