# Skill Seeker MCP Server - Quick Setup Script (Windows PowerShell)
# This script automates the MCP server setup for Claude Code

$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Skill Seeker MCP Server - Quick Setup (Windows)" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check Python version
Write-Host "Step 1: Checking Python version..." -ForegroundColor Yellow

try {
    $pythonVersion = (python --version 2>&1) -replace "Python ", ""
    Write-Host "✓ Python $pythonVersion found" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: Python not found" -ForegroundColor Red
    Write-Host "Please install Python 3.7 or higher from https://www.python.org/"
    exit 1
}
Write-Host ""

# Step 2: Get repository path
$repoPath = Get-Location
Write-Host "Step 2: Repository location" -ForegroundColor Yellow
Write-Host "Path: $repoPath"
Write-Host ""

# Step 3: Install dependencies
Write-Host "Step 3: Installing Python dependencies..." -ForegroundColor Yellow
Write-Host "This will install: mcp, requests, beautifulsoup4"
$response = Read-Host "Continue? (y/n)"

if ($response -eq "y" -or $response -eq "Y") {
    Write-Host "Installing MCP server dependencies..." -ForegroundColor Cyan

    try {
        python -m pip install -r mcp/requirements.txt
        Write-Host "✓ MCP dependencies installed" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to install MCP dependencies" -ForegroundColor Red
        exit 1
    }

    Write-Host "Installing CLI tool dependencies..." -ForegroundColor Cyan
    try {
        python -m pip install requests beautifulsoup4
        Write-Host "✓ CLI dependencies installed" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to install CLI dependencies" -ForegroundColor Red
        exit 1
    }

    Write-Host "✓ Dependencies installed successfully" -ForegroundColor Green
} else {
    Write-Host "Skipping dependency installation" -ForegroundColor Yellow
}
Write-Host ""

# Step 4: Test MCP server
Write-Host "Step 4: Testing MCP server..." -ForegroundColor Yellow
$job = Start-Job -ScriptBlock { python "$using:repoPath\mcp\server.py" 2>$null }
Start-Sleep -Seconds 3
Stop-Job $job
Remove-Job $job

if ($?) {
    Write-Host "✓ MCP server starts correctly" -ForegroundColor Green
} else {
    Write-Host "⚠ MCP server test inconclusive, but may still work" -ForegroundColor Yellow
}
Write-Host ""

# Step 5: Optional - Run tests
Write-Host "Step 5: Run test suite? (optional)" -ForegroundColor Yellow
$response = Read-Host "Run MCP tests to verify everything works? (y/n)"

if ($response -eq "y" -or $response -eq "Y") {
    try {
        python -m pip install pytest -q
        Write-Host "Running MCP server tests..." -ForegroundColor Cyan
        python -m pytest tests/test_mcp_server.py -v --tb=short
    } catch {
        Write-Host "⚠ Could not run tests" -ForegroundColor Yellow
    }
} else {
    Write-Host "Skipping tests" -ForegroundColor Yellow
}
Write-Host ""

# Step 6: Configure Claude Code
Write-Host "Step 6: Configure Claude Code" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "You need to add this configuration to Claude Code:" -ForegroundColor White
Write-Host ""

# Detect Windows config location
$configPath = "$env:APPDATA\Claude\claude_desktop_config.json"
if (-not (Test-Path "$env:APPDATA\Claude")) {
    $configPath = "$env:USERPROFILE\.config\claude-code\mcp.json"
}

Write-Host "Configuration file: " -NoNewline -ForegroundColor Yellow
Write-Host "$configPath" -ForegroundColor Cyan
Write-Host ""

$repoPathEscaped = $repoPath.Path -replace '\\', '\\\\'
$configJson = @"
{
  "mcpServers": {
    "skill-seeker": {
      "command": "python",
      "args": [
        "$repoPathEscaped\\mcp\\server.py"
      ],
      "cwd": "$repoPathEscaped"
    }
  }
}
"@

Write-Host "Add this JSON configuration:" -ForegroundColor Yellow
Write-Host ""
Write-Host $configJson -ForegroundColor Green
Write-Host ""

# Ask if user wants auto-configure
$response = Read-Host "Auto-configure Claude Code now? (y/n)"

if ($response -eq "y" -or $response -eq "Y") {
    # Check if config already exists
    if (Test-Path $configPath) {
        Write-Host "⚠ Warning: $configPath already exists" -ForegroundColor Yellow
        Write-Host "Current contents:"
        Get-Content $configPath
        Write-Host ""
        $overwrite = Read-Host "Overwrite? (y/n)"

        if ($overwrite -ne "y" -and $overwrite -ne "Y") {
            Write-Host "Skipping auto-configuration" -ForegroundColor Yellow
            Write-Host "Please manually add the skill-seeker server to your config"
            exit 0
        }
    }

    # Create config directory
    $configDir = Split-Path $configPath -Parent
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }

    # Write configuration
    $configJson | Out-File -FilePath $configPath -Encoding UTF8
    Write-Host "✓ Configuration written to $configPath" -ForegroundColor Green
} else {
    Write-Host "Skipping auto-configuration" -ForegroundColor Yellow
    Write-Host "Please manually configure Claude Code using the JSON above"
}
Write-Host ""

# Step 7: Final instructions
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. " -NoNewline
Write-Host "Restart Claude Code" -ForegroundColor Yellow -NoNewline
Write-Host " (quit and reopen, don't just close window)"
Write-Host "  2. In Claude Code, test with: " -NoNewline
Write-Host "List all available configs" -ForegroundColor Green
Write-Host "  3. You should see 6 Skill Seeker tools available"
Write-Host ""
Write-Host "Available MCP Tools:" -ForegroundColor Cyan
Write-Host "  • generate_config   - Create new config files"
Write-Host "  • estimate_pages    - Estimate scraping time"
Write-Host "  • scrape_docs       - Scrape documentation"
Write-Host "  • package_skill     - Create .zip files"
Write-Host "  • list_configs      - Show available configs"
Write-Host "  • validate_config   - Validate config files"
Write-Host ""
Write-Host "Example commands to try in Claude Code:" -ForegroundColor Cyan
Write-Host "  • " -NoNewline
Write-Host "List all available configs" -ForegroundColor Green
Write-Host "  • " -NoNewline
Write-Host "Validate configs/react.json" -ForegroundColor Green
Write-Host "  • " -NoNewline
Write-Host "Generate config for Tailwind at https://tailwindcss.com/docs" -ForegroundColor Green
Write-Host ""
Write-Host "Documentation:" -ForegroundColor Cyan
Write-Host "  • MCP Setup Guide: " -NoNewline
Write-Host "docs/MCP_SETUP.md" -ForegroundColor Yellow
Write-Host "  • Full docs: " -NoNewline
Write-Host "README.md" -ForegroundColor Yellow
Write-Host ""
Write-Host "Troubleshooting:" -ForegroundColor Cyan
Write-Host "  • Check logs: $env:APPDATA\Claude\logs\ (Windows)"
Write-Host "  • Test server: python mcp\server.py"
Write-Host "  • Run tests: python -m pytest tests\test_mcp_server.py -v"
Write-Host ""
Write-Host "Happy skill creating! 🚀" -ForegroundColor Green
