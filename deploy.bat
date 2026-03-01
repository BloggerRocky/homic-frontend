@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo 前端自动化部署脚本
echo ========================================
echo.

REM 切换到脚本所在目录
cd /d %~dp0

REM 1. 打包前端项目
echo [1/4] 正在打包前端项目...
call npm run build
if errorlevel 1 (
    echo 打包失败！
    pause
    exit /b 1
)
echo 打包完成！
echo.

REM 2. 检查dist目录是否存在
if not exist "dist" (
    echo 错误：dist目录不存在！
    pause
    exit /b 1
)

REM 3. 备份旧的dist目录
echo [2/4] 处理旧的dist目录...
if exist "D:\nginx-1.23.4\projects\dist" (
    for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c%%a%%b)
    for /f "tokens=1-2 delims=/:" %%a in ('time /t') do (set mytime=%%a%%b)
    set timestamp=!mydate!_!mytime!
    echo 正在备份旧版本...
    move "D:\nginx-1.23.4\projects\dist" "D:\nginx-1.23.4\projects\dist_backup_!timestamp!"
    echo 已备份到: D:\nginx-1.23.4\projects\dist_backup_!timestamp!
) else (
    echo 无需备份（目标目录不存在）
)
echo.

REM 4. 复制新的dist目录到Nginx
echo [3/4] 移动dist目录到Nginx...
xcopy /E /I /Y "dist" "D:\nginx-1.23.4\projects\dist"
echo 文件移动完成！
echo.

REM 5. 重启Nginx
echo [4/4] 重启Nginx服务...
echo 正在停止Nginx...
taskkill /F /IM nginx.exe >nul 2>&1
timeout /t 2 /nobreak >nul

echo 正在启动Nginx...
cd /d D:\nginx-1.23.4
start nginx.exe
timeout /t 2 /nobreak >nul

echo.
echo ========================================
echo 部署完成！
echo ========================================
echo 访问地址: http://localhost
echo 或访问: http://homic.com (需配置hosts)
echo.
pause
