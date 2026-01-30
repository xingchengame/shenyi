@echo off
chcp 65001 >nul
title 真寻Bot依赖管理

set "BAT_DIR=%~dp0"
cd /d "%BAT_DIR%"

set "PYTHON_EXE=%BAT_DIR%Python310\python.exe"
set "UV_EXE=%BAT_DIR%Python310\Scripts\uv.exe"
set "VENV_PYTHON=%BAT_DIR%venv\Scripts\python.exe"

if not exist "%PYTHON_EXE%" goto ERR_PYTHON
if not exist "%UV_EXE%" goto ERR_UV
if not exist "%VENV_PYTHON%" goto ERR_VENV

goto MAIN_MENU

:ERR_PYTHON
echo ❌ 错误：未找到内置 Python 环境
echo 请检查 Python310 文件夹是否存在
pause
exit /b 1

:ERR_UV
echo ❌ 错误：未找到 UV 工具
echo 请先运行一次 [win启动.bat] 来初始化环境
pause
exit /b 1

:ERR_VENV
echo ❌ 错误：未找到虚拟环境 (venv)
echo 请先运行一次 [win启动.bat] 来初始化环境
pause
exit /b 1

:MAIN_MENU
cls
echo ===============================================
echo           真寻Bot 依赖管理
echo ===============================================
echo 1 安装依赖
echo 2 卸载依赖
echo 3 查看当前所有已安装依赖
echo 4 搜索已安装依赖

echo 0 退出
echo ===============================================
set /p CHOICE=请输入选项(0-4)： 

:: 去掉用户可能输入的点号
set CHOICE=%CHOICE:.=%

if "%CHOICE%"=="1" goto INSTALL_DEP
if "%CHOICE%"=="2" goto UNINSTALL_DEP
if "%CHOICE%"=="3" goto LIST_DEP
if "%CHOICE%"=="4" goto SEARCH_DEP
if "%CHOICE%"=="0" exit /b

echo 无效选项，请重新输入
pause
goto MAIN_MENU

:: ===================== 安装依赖 =====================
:INSTALL_DEP
:INSTALL_LOOP
cls
echo ---------- 安装依赖 ----------
echo 可以指定版本或安装多个依赖（空格分隔）

echo 输入 q 或 Q 返回主菜单

echo 示例： httpx==0.27 requests
echo.
set /p DEPENDENCIES=请输入依赖名： 

:: 输入 q 或 Q 返回主菜单
if /i "%DEPENDENCIES%"=="q" goto MAIN_MENU

if "%DEPENDENCIES%"=="" (
    echo 未输入依赖，返回主菜单
    pause
    goto MAIN_MENU
)

echo 正在安装依赖 (venv)：%DEPENDENCIES%
"%UV_EXE%" pip install %DEPENDENCIES% --python "%VENV_PYTHON%"
if errorlevel 1 (
    echo X 安装失败！
) else (
    echo √ 安装成功！
)

set /p CONTINUE=是否继续安装其他依赖？(Y继续, 其他键返回菜单)： 
if /i "%CONTINUE%"=="Y" goto INSTALL_LOOP

goto MAIN_MENU

:: ===================== 卸载依赖 =====================
:UNINSTALL_DEP
:UNINSTALL_LOOP
cls
echo ---------- 卸载依赖 ----------
echo 可以卸载多个依赖（空格分隔）
echo 输入 q 或 Q 返回主菜单
echo.
set /p DEPENDENCIES=请输入要卸载的依赖名： 

if /i "%DEPENDENCIES%"=="q" goto MAIN_MENU

if "%DEPENDENCIES%"=="" (
    echo 未输入依赖，返回主菜单
    pause
    goto MAIN_MENU
)

echo 正在卸载依赖 (venv)：%DEPENDENCIES%
"%UV_EXE%" pip uninstall %DEPENDENCIES% --python "%VENV_PYTHON%"
if errorlevel 1 (
    echo X 卸载失败！
) else (
    echo √ 卸载成功！
)

set /p CONTINUE=是否继续卸载其他依赖？(Y继续, 其他键返回菜单)： 
if /i "%CONTINUE%"=="Y" goto UNINSTALL_LOOP

goto MAIN_MENU

:: ===================== 查看依赖 =====================
:LIST_DEP
cls
echo ---------- 当前已安装依赖 (venv) ----------
"%UV_EXE%" pip list --python "%VENV_PYTHON%"
pause
goto MAIN_MENU

:: ===================== 搜索依赖 =====================
:SEARCH_DEP
cls
echo ---------- 搜索已安装依赖 ----------
echo 输入 q 或 Q 返回主菜单
echo.
set /p DEP_NAME=请输入要搜索的依赖名： 

if /i "%DEP_NAME%"=="q" goto MAIN_MENU

if "%DEP_NAME%"=="" (
    echo 未输入依赖名，返回主菜单
    pause
    goto MAIN_MENU
)

"%UV_EXE%" pip show %DEP_NAME% --python "%VENV_PYTHON%"
if errorlevel 1 (
    echo X 未找到依赖：%DEP_NAME%
)
pause
goto MAIN_MENU
