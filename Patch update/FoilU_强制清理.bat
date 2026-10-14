@echo off
setlocal
title FoilU 插件目录强制清理工具
set "TGT=%~1"
if "%TGT%"=="" set "TGT=%APPDATA%\Adobe\CEP\extensions\com.foilu.panel"
echo.
echo   FoilU/电电你的 强制清理工具
echo   目标: %TGT%
echo.
if not exist "%TGT%" goto regclean
tasklist /fi "imagename eq Photoshop.exe" 2>nul | find /i "Photoshop.exe" >nul
if not errorlevel 1 (
  echo   [!] 检测到 Photoshop 正在运行：正在使用的文件会删不掉。
  echo       建议先完全关闭 Photoshop，再按任意键继续清理。
  pause >nul
)
fsutil reparsepoint query "%TGT%" >nul 2>nul
if not errorlevel 1 (
  echo   检测到这是链接（Junction）：只删除链接本身，不碰它指向的真实目录...
  rmdir "%TGT%" 2>nul
  goto check
)
echo   1/5 尝试取消文件夹加密（EFS）...
cipher /d /s:"%TGT%" >nul 2>nul
echo   2/5 清理只读 / 系统 / 隐藏属性...
attrib -r -s -h "%TGT%\*.*" /s /d >nul 2>nul
echo   3/5 强制删除...
rd /s /q "%TGT%" >nul 2>nul
if exist "%TGT%" timeout /t 1 /nobreak >nul
rd /s /q "%TGT%" >nul 2>nul
if exist "%TGT%" powershell -NoProfile -ExecutionPolicy Bypass -Command "$p='%TGT%'; Set-Location $env:TEMP; Get-ChildItem -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object { try { $_.Attributes='Normal' } catch {} }; Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue"
if not exist "%TGT%" goto check
echo   4/5 尝试取得所有权（takeown）...
takeown /f "%TGT%" /r /d y >nul 2>nul
echo   5/5 重新授予当前用户完全控制（icacls）并再删一次...
icacls "%TGT%" /grant "%USERDOMAIN%\%USERNAME%":F /t /c /q >nul 2>nul
rd /s /q "%TGT%" >nul 2>nul
:check
if exist "%TGT%" (
  echo.
  echo   [X] 仍然无法删除。请依次检查：
  echo       - 是否还有黑色安装窗口没关（关掉它再试）
  echo       - 该文件夹 右键-属性-高级 里是否勾了"加密内容"（取消勾选）
  echo       - Windows安全中心 -^> 病毒和威胁防护 -^> 勒索软件防护 -^> 受控文件夹访问（关闭或移除该位置）
  echo       - 360 / 电脑管家 等安全软件（先退出）
  echo       - OneDrive / 网盘同步（先暂停）
  echo       - 右键本工具 -^> 以管理员身份运行 再试一次
  echo       若重试多次仍失败，请截图本窗口反馈。
) else (
  echo   [OK] 已删除: %TGT%
)
:regclean
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\FoilU_Panel" /f >nul 2>nul
echo   [OK] 已清理安装登记信息（如有）。
echo.
pause
