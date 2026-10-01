@echo off
title Servidor de Controlo Nativo Windows
setlocal enabledelayedexpansion

:: Descobrir o IP Local do computador automaticamente
for /f "tokens=4" %%a in ('route print ^| findstr 0.0.0.0 ^| findstr /v "127.0.0.1"') do (
    set "IP=%%a"
)
if "%IP%"=="" set "IP=127.0.0.1"

echo ==================================================
echo   SERVIDOR ATIVO! No telemovel aceda a:
echo   http://%IP%:8080
echo ==================================================
echo.

:: Cria um loop em PowerShell para escutar a porta 8080 nativamente
powershell -Command ^
    "$listener = New-Object System.Net.HttpListener;" ^
    "$listener.Prefixes.Add('http://+:8080/');" ^
    "try { $listener.Start() } catch { Write-Host 'Erro: Execute o .bat como Administrador se nao ligar.' -ForegroundColor Red; exit };" ^
    "Add-Type -AssemblyName System.Windows.Forms, System.Drawing;" ^
    "while ($listener.IsListening) {" ^
    "    $context = $listener.GetContext();" ^
    "    $req = $context.Request;" ^
    "    $res = $context.Response;" ^
    "    if ($req.HttpMethod -eq 'POST') {" ^
    "        $reader = New-Object System.IO.StreamReader($req.InputStream);" ^
    "        $body = $reader.ReadToEnd();" ^
    "        if ($body -match 'action=move&x=(-?\d+)&y=(-?\d+)') {" ^
    "            $dx = [int]$Matches[1]; $dy = [int]$Matches[2];" ^
    "            $pos = [System.Windows.Forms.Cursor]::Position;" ^
    "            [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point(($pos.X + $dx), ($pos.Y + $dy));" ^
    "        } elseif ($body -match 'action=click') {" ^
    "            $signature = '[DllImport(\"user32.dll\")] public static extern void mouse_event(int dwFlags, int dx, int dy, int cButtons, int dwExtraInfo);';" ^
    "            $type = Add-Type -MemberDefinition $signature -Name 'Win32Mouse' -Namespace 'Win32' -PassThru;" ^
    "            $type::mouse_event(0x0002, 0, 0, 0, 0);" ^
    "            Start-Sleep -Milliseconds 50;" ^
    "            $type::mouse_event(0x0004, 0, 0, 0, 0);" ^
    "        }" ^
    "        $buffer = [System.Text.Encoding]::UTF8.GetBytes('ok');" ^
    "        $res.ContentLength64 = $buffer.Length;" ^
    "        $res.OutputStream.Write($buffer, 0, $buffer.Length);" ^
    "    } else {" ^
    "        $htmlPath = Join-Path $pwd 'index.html';" ^
    "        if (Test-Path $htmlPath) {" ^
    "            $buffer = [System.IO.File]::ReadAllBytes($htmlPath);" ^
    "            $res.ContentType = 'text/html';" ^
    "        } else {" ^
    "            $buffer = [System.Text.Encoding]::UTF8.GetBytes('Ficheiro index.html nao encontrado.');" ^
    "        }" ^
    "        $res.ContentLength64 = $buffer.Length;" ^
    "        $res.OutputStream.Write($buffer, 0, $buffer.Length);" ^
    "    }" ^
    "    $res.OutputStream.Close();" ^
    "}"
pause
