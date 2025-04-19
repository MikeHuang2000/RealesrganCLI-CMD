@echo off
setlocal
setlocal enabledelayedexpansion

:: 设置基础路径
set "root=%~dp0"
set "models_dir=%root%models"
set "input_dir=%root%input"
set "output_dir=%root%output"
set "storage_dir=%root%storage"
set "exe_path=%root%realesrgan-ncnn-vulkan.exe"

:: 创建必要目录
for %%d in ("%input_dir%" "%output_dir%" "%storage_dir%") do (
    if not exist %%d mkdir %%d
)

:: 检查模型目录
if not exist "%models_dir%" (
    echo Error: Models directory not found!
    pause
    exit /b 1
)

::使用说明
echo 把需要放大的图片放在input文件夹下，之后放大后的图片会输出到output文件夹中，原来的文件移动到storage文件夹中
echo 输入序号选择模型，模型在models目录下
echo.
echo ------------------------------------------------------
echo.

:: 用户操作选择
:operation
echo 请选择操作：
echo [s] 处理并移动文件
echo [p] 仅处理文件
echo [m] 仅移动文件
echo [d] 删除所有输入文件
echo [f] 在资源管理器中打开input文件夹
set /p "cmd=请输入命令(s/m/d/f)："

if /i "%cmd%" neq "s" if /i "%cmd%" neq "m" if /i "%cmd%" neq "d" if /i "%cmd%" neq "f" if /i "%cmd%" neq "p" (
    echo 无效命令！
    goto operation
)

if /i "%cmd%"=="f" (
    explorer.exe "%~dp0input"
    echo 已打开input文件夹
    goto operation
)


:: 枚举可用模型
echo 可用模型列表：
set /a model_count=0
set "model_list="

for /f "delims=" %%f in ('dir /b /a-d "%models_dir%\*.bin" 2^>nul') do (
    set "model_name=%%~nf"
    set "model_name=!model_name:.bin=!"
    
    :: 去重检查
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
    echo 错误：未找到任何模型文件！
    pause
    exit /b 1
)

:: 用户选择模型
:select_model
set /p "model_num=请选择模型编号(1-%model_count%)："
if %model_num% lss 1 goto select_model
if %model_num% gtr %model_count% goto select_model

for /l %%i in (1,1,%model_count%) do (
    if %%i equ %model_num% (
        call set "selected_model=%%model_%%i%%"
    )
)



:: 获取当前时间戳
for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value') do set "datetime=%%a"
set "timestamp=%datetime:~0,8%_%datetime:~8,6%"
set "timestamp=%timestamp: =0%"

:: 处理文件操作
if /i "%cmd%"=="s" (
    for %%f in ("%input_dir%\*.jpg" "%input_dir%\*.jpeg" "%input_dir%\*.png" "%input_dir%\*.webp") do (
        if exist "%%f" (
            echo 正在处理: %%~nxf
            "%exe_path%" -i "%%f" -o "%output_dir%\%%~nf_realesrganed%%~xf" -m "%models_dir%" -n "%selected_model%"
            call :move_file "%%f"
        )
    )
)

if /i "%cmd%"=="p" (
    for %%f in ("%input_dir%\*.jpg" "%input_dir%\*.jpeg" "%input_dir%\*.png" "%input_dir%\*.webp") do (
        if exist "%%f" (
            echo 正在处理: %%~nxf
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
    echo 已删除所有输入文件
)


echo 操作完成！
pause
exit /b

:: 文件移动子程序
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