# One step: build the web version and put it live on GitHub Pages.
#   https://freecs97.github.io/orbspire/   (repo: github.com/Freecs97/orbspire)
#
# Run from anywhere:
#   powershell -ExecutionPolicy Bypass -File tools\publish_web.ps1 "What changed"
#
# What it does:
#   1. reads the site password's SHA-256 from the live index.html (password unchanged)
#   2. exports the "Web" preset to build/web
#   3. puts the password hash into the new index.html
#   4. copies the web build + the Godot project into the orbspire-site repo
#   5. commits and pushes (skips if nothing changed)
#   6. waits for GitHub Pages to finish building (up to 5 minutes)
param([string]$Message = "")

$proj  = Split-Path -Parent $PSScriptRoot
$site  = Join-Path (Split-Path -Parent $proj) "orbspire-site"
$godot = "$env:LOCALAPPDATA\Programs\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe"
$git   = "$env:LOCALAPPDATA\Programs\MinGit\cmd\git.exe"
$gh    = "$env:LOCALAPPDATA\Programs\gh\bin\gh.exe"
$repo  = "Freecs97/orbspire"

function Fail([string]$why) { Write-Host "PUBLISH FAILED: $why"; exit 1 }

# 1. The password hash already on the site (so the password never changes by accident).
$m = Select-String -Path "$site\index.html" -Pattern "PASSWORD_SHA256 = '([0-9a-f]{64})'"
if (-not $m) { Fail "no password hash found in $site\index.html" }
$hash = $m.Matches[0].Groups[1].Value

# 2. Fresh web export.
Write-Host "Exporting the Web build..."
if (Test-Path "$proj\build\web") { Remove-Item "$proj\build\web" -Recurse -Force }
New-Item -ItemType Directory -Force "$proj\build\web" | Out-Null
& $godot --headless --path $proj --export-release "Web" "build/web/index.html" | Out-Null
if (-not (Test-Path "$proj\build\web\index.pck") -or -not (Test-Path "$proj\build\web\index.wasm")) { Fail "Godot web export did not produce index.pck / index.wasm" }

# 3. Password hash into the page (UTF-8, no BOM).
$htmlPath = "$proj\build\web\index.html"
$html = [IO.File]::ReadAllText($htmlPath)
if (-not $html.Contains("__PASSWORD_SHA256__")) { Fail "password placeholder missing from the exported index.html" }
$html = $html.Replace("__PASSWORD_SHA256__", $hash)
[IO.File]::WriteAllText($htmlPath, $html, (New-Object Text.UTF8Encoding $false))

# 4. Copy into the site repo: web build at the root, project mirrored into project/.
Copy-Item "$proj\build\web\*" $site -Force
robocopy $proj "$site\project" /MIR /XD "$proj\.godot" "$proj\build" "$proj\tests\screenshots" "$site\project\.godot" "$site\project\build" "$site\project\tests\screenshots" /XF "report*.txt" /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -ge 8) { Fail "robocopy failed (code $LASTEXITCODE)" }

# 5. Commit + push.
& $git -C $site add -A
& $git -C $site diff --cached --quiet
if ($LASTEXITCODE -eq 0) { Write-Host "Nothing changed - the site is already up to date."; exit 0 }
if ($Message -eq "") { $Message = "Update game " + (Get-Date -Format "yyyy-MM-dd HH:mm") }
& $git -C $site commit -q -m $Message
if ($LASTEXITCODE -ne 0) { Fail "git commit failed" }
& $git -C $site push -q origin main
if ($LASTEXITCODE -ne 0) { Fail "git push failed" }
$sha = (& $git -C $site rev-parse HEAD).Trim()
Write-Host "Pushed $($sha.Substring(0,7)): $Message"

# 6. Wait for GitHub Pages to build this commit.
$deadline = (Get-Date).AddMinutes(5)
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 15
    $b = (& $gh api "repos/$repo/pages/builds/latest") -join "" | ConvertFrom-Json
    if ($b.commit -eq $sha -and $b.status -eq "built") { Write-Host "LIVE: https://freecs97.github.io/orbspire/"; exit 0 }
    if ($b.commit -eq $sha -and $b.status -eq "errored") { Fail "GitHub Pages build errored" }
}
Write-Host "Pushed, but Pages had not finished building after 5 minutes. It usually appears shortly."
exit 0
