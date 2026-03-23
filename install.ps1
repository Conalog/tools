# Conalog CLI installer for Windows
#
# Usage:
#   irm https://raw.githubusercontent.com/Conalog/tools/main/install.ps1 | iex
#
# Environment variables:
#   CONALOG_VERSION     - Version to install (default: latest)
#   CONALOG_INSTALL_DIR - Install directory (default: $HOME\.conalog\bin)

$ErrorActionPreference = "Stop"

$Repo = "Conalog/tools"
$BinaryName = "conalog.exe"
$DefaultInstallDir = Join-Path $HOME ".conalog\bin"
$MaxRetries = 3

# ── Output helpers ───────────────────────────────────────────

function Write-Info { param([string]$Message) Write-Host "==> $Message" -ForegroundColor Blue }
function Write-Warn { param([string]$Message) Write-Host "==> Warning: $Message" -ForegroundColor Yellow }
function Write-Err { param([string]$Message) Write-Host "==> Error: $Message" -ForegroundColor Red; exit 1 }
function Write-Ok { param([string]$Message) Write-Host "==> $Message" -ForegroundColor Green }

# ── Platform detection ──────────────────────────────────────

function Get-Platform {
    $arch = if ([Environment]::Is64BitOperatingSystem) { "amd64" } else { "386" }

    if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
        Write-Err "Windows ARM64 is not supported. Supported: windows_amd64"
    }

    return "windows_$arch"
}

# ── Version resolution ──────────────────────────────────────

function Get-LatestVersion {
    $url = "https://api.github.com/repos/$Repo/releases/latest"

    try {
        $response = Invoke-RestMethod -Uri $url -Headers @{ "User-Agent" = "conalog-installer" }
        $version = $response.tag_name
    } catch {
        Write-Err "Failed to fetch latest version. GitHub API may be rate-limited.`n  Try setting `$env:CONALOG_VERSION = 'v0.1.0'`n  Releases: https://github.com/$Repo/releases"
    }

    if (-not $version) {
        Write-Err "Failed to parse latest version from GitHub API response.`n  Check: https://github.com/$Repo/releases"
    }

    return $version
}

# ── Download helper ─────────────────────────────────────────

function Invoke-Download {
    param([string]$Url, [string]$Dest)

    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        try {
            Invoke-WebRequest -Uri $Url -OutFile $Dest -UseBasicParsing
            return
        } catch {
            if ($attempt -lt $MaxRetries) {
                $wait = $attempt * 2
                Write-Warn "Download failed (attempt $attempt/$MaxRetries), retrying in ${wait}s..."
                Start-Sleep -Seconds $wait
            }
        }
    }

    Write-Err "Failed to download $Url after $MaxRetries attempts"
}

# ── Checksum verification ──────────────────────────────────

function Test-Checksum {
    param([string]$TmpDir, [string]$ArchiveName)

    $checksumFile = Join-Path $TmpDir "checksums.txt"
    $archivePath = Join-Path $TmpDir $ArchiveName

    if (-not (Test-Path $checksumFile)) {
        Write-Warn "No checksums.txt found. Skipping verification."
        return $true
    }

    $expectedLine = Get-Content $checksumFile | Where-Object { $_ -match $ArchiveName }
    if (-not $expectedLine) {
        Write-Warn "No checksum entry found for $ArchiveName. Skipping verification."
        return $true
    }

    $expectedHash = ($expectedLine -split '\s+')[0]
    $actualHash = (Get-FileHash -Path $archivePath -Algorithm SHA256).Hash.ToLower()

    return $expectedHash -eq $actualHash
}

# ── Existing installation check ─────────────────────────────

function Test-Existing {
    param([string]$InstallDir)

    $target = Join-Path $InstallDir $BinaryName
    if (Test-Path $target) {
        try {
            $ver = & $target version 2>$null
            if ($ver) { Write-Info "Existing installation detected: $ver" }
            else { Write-Info "Existing installation detected at $target" }
        } catch {
            Write-Info "Existing installation detected at $target"
        }
    }
}

# ── PATH management ─────────────────────────────────────────

function Add-ToUserPath {
    param([string]$Dir)

    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -split ";" | Where-Object { $_ -eq $Dir }) {
        return
    }

    $newPath = "$currentPath;$Dir"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = "$env:Path;$Dir"
    Write-Info "Added $Dir to user PATH (restart terminal to take effect)"
}

# ── Main ────────────────────────────────────────────────────

function Install-Conalog {
    Write-Info "Conalog CLI Installer (Windows)"

    # Resolve install directory
    $installDir = if ($env:CONALOG_INSTALL_DIR) { $env:CONALOG_INSTALL_DIR } else { $DefaultInstallDir }

    # Detect platform
    $platform = Get-Platform
    Write-Info "Platform: $platform"

    # Resolve version
    $version = if ($env:CONALOG_VERSION) { $env:CONALOG_VERSION } else { Get-LatestVersion }
    if ($version -notmatch "^v") { $version = "v$version" }
    Write-Info "Version: $version"

    # Check existing
    Test-Existing -InstallDir $installDir

    # Build download URLs
    $verNoV = $version.TrimStart("v")
    $archiveName = "conalog_${verNoV}_${platform}.zip"
    $downloadUrl = "https://github.com/$Repo/releases/download/$version/$archiveName"
    $checksumUrl = "https://github.com/$Repo/releases/download/$version/checksums.txt"

    # Create temp directory
    $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "conalog-install-$(Get-Random)"
    New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

    try {
        # Download
        Write-Info "Downloading $archiveName..."
        Invoke-Download -Url $checksumUrl -Dest (Join-Path $tmpDir "checksums.txt")
        Invoke-Download -Url $downloadUrl -Dest (Join-Path $tmpDir $archiveName)

        # Verify checksum
        Write-Info "Verifying checksum..."
        if (-not (Test-Checksum -TmpDir $tmpDir -ArchiveName $archiveName)) {
            Write-Err "Checksum verification failed! The download may be corrupted or tampered with."
        }
        Write-Info "Checksum verified"

        # Extract
        Write-Info "Extracting..."
        Expand-Archive -Path (Join-Path $tmpDir $archiveName) -DestinationPath $tmpDir -Force

        # Create install directory
        if (-not (Test-Path $installDir)) {
            New-Item -ItemType Directory -Path $installDir -Force | Out-Null
        }

        # Install
        $source = Join-Path $tmpDir $BinaryName
        $dest = Join-Path $installDir $BinaryName
        Write-Info "Installing to $dest..."
        Copy-Item -Path $source -Destination $dest -Force

        # Add to PATH
        Add-ToUserPath -Dir $installDir

        Write-Ok "Installed conalog $version"
        Write-Host ""
        Write-Host "Next steps:"
        Write-Host "  1. Restart your terminal (or open a new one)"
        Write-Host "  2. conalog library login             # Authenticate with Google"
        Write-Host "  3. conalog library list              # Browse available packages"
        Write-Host "  4. conalog library install <name>    # Install a package"
        Write-Host ""
    } finally {
        Remove-Item -Path $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Install-Conalog
