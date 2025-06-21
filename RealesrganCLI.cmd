@echo off
setlocal enabledelayedexpansion

:: =================================================================
:: ==            Real-ESRGAN NCNN Vulkan 启动器脚本             ==
:: =================================================================

:: --- 基础路径设置 ---
:: %~dp0 代表脚本所在的目录
set "base_dir=%~dp0"
set "exe_path=%base_dir%realesrgan-ncnn-vulkan.exe"
set "models_dir=%base_dir%models"
set "input_dir=%base_dir%input"
set "output_dir=%base_dir%output"
set "storage_dir=%base_dir%storage"
set "temp_output_dir=%base_dir%temp_output"

:: --- 检查主程序是否存在 ---
if not exist "%exe_path%" (
    echo.
    echo  错误: 未在当前目录找到 realesrgan-ncnn-vulkan.exe !
    echo  请确保此脚本与主程序在同一文件夹下。
    echo.
    pause
    exit /b
)

:: --- 创建必要的目录 ---
for %%d in ("%input_dir%" "%output_dir%" "%storage_dir%" "%temp_output_dir%") do (
    if not exist %%d mkdir %%d
)

:: =================================================================
:: ==                         主菜单                             ==
:: =================================================================
:main_menu
cls
echo.
echo  =======================================================
echo  =            Real-ESRGAN NCNN Vulkan 启动器           =
echo  =======================================================
echo.
echo  说明:
echo  - 将待处理的图片放入 input 文件夹。
echo  - 处理后的图片会添加时间戳并保存到 output 文件夹。
echo  - 如选择"处理并移动"，原始文件将被移至 storage 文件夹。
echo.
echo  --------------------   功能菜单   ---------------------
echo.
echo    [1] 列出所有可用模型
echo.
echo    [2] 批量处理文件 (并将原始文件移到storage)
echo    [3] 批量处理文件 (仅处理，不移动原始文件)
echo.
echo    [4] 仅移动文件 (将input内所有文件移到storage)
echo    [5] 删除所有输入文件 (input文件夹内所有文件)
echo.
echo    [6] 在资源管理器中打开 input 文件夹
echo    [7] 在资源管理器中打开 output 文件夹
echo.
echo    [0] 退出
echo.
echo  -------------------------------------------------------

set /p "choice=请输入选项编号并按回车: "

if "%choice%"=="1" goto list_models
if "%choice%"=="2" goto process_and_move
if "%choice%"=="3" goto process_only
if "%choice%"=="4" goto move_only
if "%choice%"=="5" goto delete_input
if "%choice%"=="6" goto open_input_folder
if "%choice%"=="7" goto open_output_folder
if "%choice%"=="0" exit /b
echo.
echo  无效的输入，请重新选择。
timeout /t 2 /nobreak >nul
goto main_menu


:: =================================================================
:: ==                       功能实现部分                          ==
:: =================================================================

:list_models
cls
echo.
echo  --------------------   可用模型列表   ---------------------
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
:: 检查input文件夹是否为空
dir /b /a-d "%input_dir%\*" >nul 2>&1
if errorlevel 1 (
    echo.
    echo  错误: input 文件夹是空的，没有文件可以处理！
    echo.
    pause
    goto main_menu
)

:: 1. 让用户选择模型
call :select_model
if "%selected_model%"=="" goto main_menu

:: 2. 清空临时输出文件夹，以防上次意外中断
echo.
echo  正在清理临时文件夹...
del /q "%temp_output_dir%\*" >nul 2>&1

:: 3. 执行批量处理
echo.
echo  =======================================================
echo  即将使用模型 [!selected_model!] 开始批量处理...
echo  输入路径: %input_dir%
echo  临时输出: %temp_output_dir%
echo  =======================================================
echo.
"%exe_path%" -i "%input_dir%" -o "%temp_output_dir%" -n !selected_model! -m "%models_dir%" -f png

if errorlevel 1 (
    echo.
    echo  错误: Real-ESRGAN 处理失败，请检查错误信息。
    echo.
    pause
    goto main_menu
)

echo.
echo  批量处理完成，正在重命名并移动文件...

:: 4. 获取当前时间戳 (格式: YYYY-MM-DD_HH-MM-SS)
for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value') do set "dt=%%a"
set "timestamp=%dt:~0,4%-%dt:~4,2%-%dt:~6,2%_%dt:~8,2%-%dt:~10,2%-%dt:~12,2%"

:: 5. 遍历临时文件夹，重命名并移动到最终输出文件夹
set /a processed_count=0
for %%f in ("%temp_output_dir%\*") do (
    set "new_name=%%~nf_!timestamp!%%~xf"
    echo  正在移动: %%~nxf --^> !new_name!
    move "%%f" "%output_dir%\!new_name!" >nul
    set /a processed_count+=1
)

echo.
echo  成功处理并重命名了 !processed_count! 个文件。
echo.

:: 6. 根据选择决定是否移动原始文件
if "%action%"=="process_and_move" (
    echo  正在将原始文件移动到 storage 文件夹...
    move /y "%input_dir%\*" "%storage_dir%" >nul
    echo  原始文件移动完成。
    echo.
)

:: 7. 打开输出文件夹
echo  操作完成！正在打开 output 文件夹...
explorer.exe "%output_dir%"

pause
goto main_menu


:move_only
cls
dir /b /a-d "%input_dir%\*" >nul 2>&1
if errorlevel 1 (
    echo.
    echo  错误: input 文件夹是空的，没有文件可以移动！
    echo.
    pause
    goto main_menu
)
echo.
echo  正在将 input 文件夹内的所有文件移动到 storage 文件夹...
move /y "%input_dir%\*" "%storage_dir%" >nul
echo.
echo  所有文件移动完成！
echo.
pause
goto main_menu


:delete_input
cls
dir /b /a-d "%input_dir%\*" >nul 2>&1
if errorlevel 1 (
    echo.
    echo  提示: input 文件夹已经是空的。
    echo.
    pause
    goto main_menu
)
echo.
echo  警告: 此操作将永久删除 input 文件夹内的所有文件！
set /p "confirm=您确定要继续吗? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo.
    echo  操作已取消。
    pause
    goto main_menu
)

echo.
echo  正在删除...
del /q "%input_dir%\*"
echo.
echo  input 文件夹内的所有文件已删除。
echo.
pause
goto main_menu


:open_input_folder
echo.
echo  正在打开 input 文件夹...
explorer.exe "%input_dir%"
goto main_menu

:open_output_folder
echo.
echo  正在打开 output 文件夹...
explorer.exe "%output_dir%"
goto main_menu


:: =================================================================
:: ==                       辅助子程序                            ==
:: =================================================================

:get_model_list

set /a model_count=0
for /f "delims=" %%f in ('dir /b "%models_dir%\*.param"') do (
    set /a model_count+=1
    echo    [!model_count!] %%~nf
    set "model_!model_count!=%%~nf"
)

if %model_count% equ 0 (
    echo  错误！找不到模型！
)

exit /b


:select_model
echo.
echo  --------------------   请选择一个模型   ---------------------
call :get_model_list
echo  -------------------------------------------------------
echo.

if %model_count% equ 0 (
    set "selected_model="
    exit /b
)

:prompt_model
set "selected_model="
set /p "model_num=请输入模型编号 (1-%model_count%): "

if %model_num% lss 1 (
    echo  输入无效，请重新输入。
    goto prompt_model
)
if %model_num% gtr %model_count% (
    echo  输入无效，请重新输入。
    goto prompt_model
)

call set "selected_model=%%model_%model_num%%%"
exit /b