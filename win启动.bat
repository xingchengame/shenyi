@echo off
cls
chcp 65001 >nul
setlocal enabledelayedexpansion

title 真寻Bot

set "BAT_DIR=%~dp0"
cd /d "%BAT_DIR%"

:: ===== 配置信息 =====
set "PYTHON_EXE=%BAT_DIR%Python310\python.exe"
set "MIRROR=https://mirrors.aliyun.com/pypi/simple"

echo ========================================
echo       真寻Bot 启动器 (启动前检查)
echo ========================================

:: 1. 检查并准备 Git 环境 (保持不动)
echo [1/6] 检查 Git 工具...

if exist "%GIT_EXE%" goto GIT_READY

if not exist "Git\bin\git.exe" (
    if exist "git.7z.exe" (
        echo 未检测到 Git，正在解压 git.7z.exe 到 Git 文件夹...
        "git.7z.exe" -oGit -y -s
        if not exist "Git\bin\git.exe" (
            echo ❌ Git 解压失败
            pause
            exit /b 1
        )
        echo 正在清理 Git 多余文件...
        for /d %%D in (Git\*) do (
            if /i not "%%~nxD"=="bin" if /i not "%%~nxD"=="cmd" if /i not "%%~nxD"=="mingw64" if /i not "%%~nxD"=="usr" (
                rmdir /s /q "%%D"
            )
        )
        for %%F in (Git\*) do (
            if not exist "%%F\" del /f /q "%%F"
        )
    ) else (
        echo ❌ 未找到 git.7z.exe
        pause
        exit /b 1
    )
) else (
    echo 已检测到 Git，跳过解压
)
set "GIT_EXE=%BAT_DIR%Git\cmd\git.exe"
set "PATH=%BAT_DIR%Git\cmd;%PATH%"


:GIT_READY
set "GIT_CMD="%GIT_EXE%""
:: --- 新增：彻底禁用凭据选择器弹窗 ---
%GIT_CMD% config --global credential.helper ""
%GIT_CMD% config --global core.askpass ""
:: 配置 Git 环境，防止路径冲突或权限问题
%GIT_CMD% config --global --add safe.directory "*"
%GIT_CMD% config --global http.postBuffer 524288000

:: ===== 初始化阿里云 Codeup 仓库 (保持不动) =====
if not exist ".git" (
    echo 未检测到 Git 仓库，准备从阿里云 Codeup 初始化...
    "%PYTHON_EXE%" "%BAT_DIR%init_codeup.py" zhenxun_bot
    if errorlevel 1 (
        echo ❌ Codeup 仓库初始化失败，请检查 URL/Token/网络
        pause
        exit /b 1
    )
) else (
    echo 已存在 Git 仓库，跳过初始化
)

:: ===== 更新 Git 仓库 =====
if exist "%GIT_EXE%" (
    git --version
    git pull origin main || echo ⚠️ Git 更新失败，继续执行...
)



:PYTHON_CHECK
:: 3. 检查 Python

echo [3/6] 检查内置 Python 环境...

if not exist "%PYTHON_EXE%" goto ERR_NO_PY

:: 4. 安装 UV (直接装在内置 Python 里)
:: 定义 UV 可执行文件路径

set "UV_EXE=%BAT_DIR%Python310\Scripts\uv.exe"

echo [4/6] 检查 UV 工具...

if not exist "%UV_EXE%" (
    echo 正在安装 UV...
    "%PYTHON_EXE%" -m pip install uv -i %MIRROR%
) else (
    echo UV 已安装，跳过。
)

:: 5. 使用 UV 创建虚拟环境
if not exist "venv" (

    echo [5/6] 正在通过 UV 创建虚拟环境...

    "%UV_EXE%" venv venv --python "%PYTHON_EXE%"
)

:: 6. 激活并安装依赖
echo [6/6] 正在安装依赖...
set "REQ_FILE=requirements.txt"
set "REQ_MARKER=venv\requirements_installed.marker"
set "NEED_INSTALL=1"

if exist "%REQ_MARKER%" (
    fc /b "%REQ_FILE%" "%REQ_MARKER%" >nul
    if not errorlevel 1 set "NEED_INSTALL=0"
)

if "!NEED_INSTALL!"=="1" (
    echo 检测到依赖变动或首次运行，正在安装依赖...
    "%UV_EXE%" pip install -r requirements.txt --python "%BAT_DIR%venv\Scripts\python.exe" -i %MIRROR%
    if not errorlevel 1 copy /y "%REQ_FILE%" "%REQ_MARKER%" >nul
) else (
    echo 依赖未变更，跳过安装。
)
:: 安装 Playwright (在 venv 环境内)
echo [READY] 准备启动...
call venv\Scripts\activate.bat
::python -m playwright install chromium

:: 7. 启动
echo.
echo ========================================
echo           🚀 环境就绪，启动 bot.py
echo ========================================
echo.

python bot.py

if errorlevel 1 goto ERR_EXIT
goto end

:: --- 错误处理标签 ---

:ERR_GIT_ZIP
echo.
echo ❌ 错误：Git 解压失败。
pause
exit /b 1

:ERR_NO_PY
echo.
echo ❌ 错误：找不到 Python 环境！
pause
exit /b 1

:ERR_VENV
echo.
echo ❌ 错误：虚拟环境创建失败。
pause
exit /b 1

:ERR_EXIT
echo.
echo ❌ Bot 运行异常停止。
pause
exit /b 1

:end
echo 程序运行结束。
pause