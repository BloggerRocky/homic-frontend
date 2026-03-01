# 前端自动化部署脚本
# 功能：打包前端项目 -> 移动到Nginx目录 -> 重启Nginx服务

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "开始前端项目部署..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. 打包前端项目
Write-Host "`n[1/4] 正在打包前端项目..." -ForegroundColor Yellow
npm run build

if ($LASTEXITCODE -ne 0) {
    Write-Host "打包失败！" -ForegroundColor Red
    exit 1
}
Write-Host "打包完成！" -ForegroundColor Green

# 2. 检查dist目录是否存在
if (-Not (Test-Path "dist")) {
    Write-Host "错误：dist目录不存在！" -ForegroundColor Red
    exit 1
}

# 3. 删除旧的dist目录并移动新的dist目录到Nginx
$targetPath = "D:/nginx-1.23.4/projects/dist"
Write-Host "`n[2/4] 处理旧的dist目录..." -ForegroundColor Yellow

if (Test-Path $targetPath) {
    Write-Host "正在删除旧的dist目录..." -ForegroundColor Yellow
    Remove-Item -Path $targetPath -Recurse -Force
    Write-Host "旧目录已删除" -ForegroundColor Green
}
else {
    Write-Host "无需删除（目标目录不存在）" -ForegroundColor Yellow
}

# 4. 移动新的dist目录到Nginx
Write-Host "`n[3/4] 移动dist目录到Nginx..." -ForegroundColor Yellow
Move-Item -Path "dist" -Destination $targetPath -Force
Write-Host "文件移动完成！" -ForegroundColor Green

# 5. 重启Nginx服务
Write-Host "`n[4/4] 重启Nginx服务..." -ForegroundColor Yellow

$nginxProcess = Get-Process nginx -ErrorAction SilentlyContinue

if ($nginxProcess) {
    Write-Host "正在停止Nginx..." -ForegroundColor Yellow
    Set-Location "D:/nginx-1.23.4"
    & ".\nginx.exe" -s quit
    Start-Sleep -Seconds 2
    Write-Host "Nginx已停止" -ForegroundColor Green
}

Write-Host "正在启动Nginx..." -ForegroundColor Yellow
Set-Location "D:/nginx-1.23.4"
# 使用 Start-Process 在后台启动 Nginx，不占用当前窗口
Start-Process -FilePath ".\nginx.exe" -WindowStyle Hidden
Start-Sleep -Seconds 2

$nginxProcess = Get-Process nginx -ErrorAction SilentlyContinue
if ($nginxProcess) {
    Write-Host "Nginx启动成功！" -ForegroundColor Green
}
else {
    Write-Host "警告：Nginx可能未成功启动，请手动检查" -ForegroundColor Red
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "部署完成！" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "访问地址: http://localhost" -ForegroundColor Green
Write-Host "或访问: http://homic.com (需配置hosts)" -ForegroundColor Green
