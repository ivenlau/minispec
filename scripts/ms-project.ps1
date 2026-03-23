param(
  [string]$Root = ".",
  [ValidateSet("auto", "existing", "new")]
  [string]$Mode = "auto",
  [string]$Context = ""
)

$ErrorActionPreference = "Stop"

function Test-AnyPath {
  param([string[]]$Paths)
  foreach ($p in $Paths) {
    if (Test-Path $p) { return $true }
  }
  return $false
}

function Get-FileText {
  param([string]$Path)
  if (Test-Path $Path) {
    return (Get-Content -Path $Path -Raw -Encoding UTF8)
  }
  return ""
}

function New-StackInfo {
  return @{
    Language = ""
    Framework = ""
    Runtime = ""
    Install = ""
    Build = ""
    Test = ""
    Lint = ""
    Notes = New-Object System.Collections.Generic.List[string]
    Guided = New-Object System.Collections.Generic.List[string]
    Source = "guided"
  }
}

function Add-Note {
  param($Info, [string]$Text)
  if ($Text -and -not $Info.Notes.Contains($Text)) {
    $Info.Notes.Add($Text)
  }
}

function Add-GuidedPrompt {
  param($Info, [string]$Text)
  if ($Text -and -not $Info.Guided.Contains($Text)) {
    $Info.Guided.Add($Text)
  }
}

function Get-NodeManager {
  param([string]$ProjectRoot)
  if (Test-Path (Join-Path $ProjectRoot "pnpm-lock.yaml")) { return "pnpm" }
  if (Test-Path (Join-Path $ProjectRoot "yarn.lock")) { return "yarn" }
  if (Test-AnyPath @((Join-Path $ProjectRoot "bun.lockb"), (Join-Path $ProjectRoot "bun.lock"))) { return "bun" }
  return "npm"
}

function Build-NodeScriptCmd {
  param([string]$Manager, [string]$Script)
  switch ($Manager) {
    "pnpm" { return "pnpm run $Script" }
    "yarn" { return "yarn $Script" }
    "bun"  { return "bun run $Script" }
    default { return "npm run $Script" }
  }
}

function Detect-Node {
  param([string]$ProjectRoot, $Info)

  $pkgPath = Join-Path $ProjectRoot "package.json"
  if (-not (Test-Path $pkgPath)) { return $false }

  $pkg = Get-Content -Path $pkgPath -Raw -Encoding UTF8 | ConvertFrom-Json
  $manager = Get-NodeManager -ProjectRoot $ProjectRoot
  $scripts = $pkg.scripts
  $deps = @()
  if ($pkg.dependencies) { $deps += $pkg.dependencies.PSObject.Properties.Name }
  if ($pkg.devDependencies) { $deps += $pkg.devDependencies.PSObject.Properties.Name }

  $scriptNames = @()
  if ($scripts) { $scriptNames = $scripts.PSObject.Properties.Name }

  $hasTs = (Test-Path (Join-Path $ProjectRoot "tsconfig.json")) -or ($deps -contains "typescript")
  $Info.Language = if ($hasTs) { "TypeScript" } else { "JavaScript" }
  $Info.Runtime = "Node.js"

  if ($deps -contains "next") {
    $Info.Framework = "Next.js"
  } elseif ($deps -contains "@nestjs/core") {
    $Info.Framework = "NestJS"
  } elseif ($deps -contains "nuxt") {
    $Info.Framework = "Nuxt"
  } elseif ($deps -contains "react") {
    $Info.Framework = "React"
  } elseif ($deps -contains "vue") {
    $Info.Framework = "Vue"
  } elseif (($deps -contains "@sveltejs/kit") -or ($deps -contains "svelte")) {
    $Info.Framework = "Svelte/SvelteKit"
  } elseif ($deps -contains "express") {
    $Info.Framework = "Express"
  } elseif ($deps -contains "fastify") {
    $Info.Framework = "Fastify"
  } elseif ($deps -contains "koa") {
    $Info.Framework = "Koa"
  } else {
    $Info.Framework = "Node.js application"
  }

  switch ($manager) {
    "pnpm" { $Info.Install = "pnpm install" }
    "yarn" { $Info.Install = "yarn install" }
    "bun" { $Info.Install = "bun install" }
    default { $Info.Install = "npm install" }
  }

  if ($scriptNames -contains "build") {
    $Info.Build = Build-NodeScriptCmd -Manager $manager -Script "build"
  } else {
    $Info.Build = "Not defined (add build script in package.json)"
  }

  if ($scriptNames -contains "test") {
    $Info.Test = Build-NodeScriptCmd -Manager $manager -Script "test"
  } else {
    $Info.Test = "Not defined (add test script in package.json)"
  }

  if ($scriptNames -contains "lint") {
    $Info.Lint = Build-NodeScriptCmd -Manager $manager -Script "lint"
  } else {
    $Info.Lint = "Not defined (add lint script in package.json)"
  }

  Add-Note -Info $Info -Text "Detected from package.json and lockfile."
  $Info.Source = "detected:node"
  return $true
}

function Detect-Maven {
  param([string]$ProjectRoot, $Info)

  $pomPath = Join-Path $ProjectRoot "pom.xml"
  if (-not (Test-Path $pomPath)) { return $false }

  $pomText = Get-FileText -Path $pomPath
  $Info.Language = "Java"
  $Info.Framework = if ($pomText -match "spring-boot|springframework\.boot") { "Spring Boot" } else { "Java (Maven)" }
  $Info.Runtime = "JVM"
  $Info.Install = "mvn -DskipTests compile"
  $Info.Build = "mvn clean package"
  $Info.Test = "mvn test"

  if ($pomText -match "spotless-maven-plugin") {
    $Info.Lint = "mvn spotless:check"
  } elseif ($pomText -match "maven-checkstyle-plugin") {
    $Info.Lint = "mvn checkstyle:check"
  } else {
    $Info.Lint = "Not defined (configure spotless/checkstyle)"
  }

  Add-Note -Info $Info -Text "Detected from pom.xml."
  $Info.Source = "detected:maven"
  return $true
}

function Detect-Gradle {
  param([string]$ProjectRoot, $Info)

  $gradlePath = Join-Path $ProjectRoot "build.gradle"
  $gradleKtsPath = Join-Path $ProjectRoot "build.gradle.kts"
  if (-not (Test-AnyPath @($gradlePath, $gradleKtsPath))) { return $false }

  $gradleText = (Get-FileText -Path $gradlePath) + "`n" + (Get-FileText -Path $gradleKtsPath)
  $Info.Language = "Java/Kotlin"
  $Info.Framework = if ($gradleText -match "spring-boot|org\.springframework\.boot") { "Spring Boot" } else { "Gradle application" }
  $Info.Runtime = "JVM"
  $Info.Install = "./gradlew dependencies"
  $Info.Build = "./gradlew build"
  $Info.Test = "./gradlew test"
  $Info.Lint = if ($gradleText -match "checkstyle|spotless") { "./gradlew check" } else { "Not defined (configure checkstyle/spotless)" }

  Add-Note -Info $Info -Text "Detected from Gradle build files."
  $Info.Source = "detected:gradle"
  return $true
}

function Detect-Python {
  param([string]$ProjectRoot, $Info)

  $pyproject = Join-Path $ProjectRoot "pyproject.toml"
  $requirements = Join-Path $ProjectRoot "requirements.txt"
  if (-not (Test-AnyPath @($pyproject, $requirements, (Join-Path $ProjectRoot "setup.py")))) { return $false }

  $pyText = (Get-FileText -Path $pyproject) + "`n" + (Get-FileText -Path $requirements)
  $Info.Language = "Python"
  $Info.Runtime = "Python 3.x"

  if ($pyText -match "fastapi") {
    $Info.Framework = "FastAPI"
  } elseif ($pyText -match "django") {
    $Info.Framework = "Django"
  } elseif ($pyText -match "flask") {
    $Info.Framework = "Flask"
  } else {
    $Info.Framework = "Python application"
  }

  if (Test-Path (Join-Path $ProjectRoot "uv.lock")) {
    $Info.Install = "uv sync"
  } elseif (Test-Path (Join-Path $ProjectRoot "poetry.lock")) {
    $Info.Install = "poetry install"
  } elseif (Test-Path $requirements) {
    $Info.Install = "pip install -r requirements.txt"
  } else {
    $Info.Install = "pip install -e ."
  }

  if (Test-Path $pyproject) {
    $Info.Build = "python -m build"
  } else {
    $Info.Build = "Not defined (optional for app-only repositories)"
  }

  if ((Test-Path (Join-Path $ProjectRoot "tests")) -or ($pyText -match "pytest")) {
    $Info.Test = "pytest"
  } else {
    $Info.Test = "Not defined (add pytest)"
  }

  if ($pyText -match "ruff") {
    $Info.Lint = "ruff check ."
  } elseif ($pyText -match "flake8") {
    $Info.Lint = "flake8 ."
  } else {
    $Info.Lint = "Not defined (add ruff or flake8)"
  }

  Add-Note -Info $Info -Text "Detected from pyproject.toml/requirements.txt."
  $Info.Source = "detected:python"
  return $true
}

function Detect-Go {
  param([string]$ProjectRoot, $Info)

  if (-not (Test-Path (Join-Path $ProjectRoot "go.mod"))) { return $false }

  $Info.Language = "Go"
  $Info.Framework = "Go application"
  $Info.Runtime = "Go runtime"
  $Info.Install = "go mod download"
  $Info.Build = "go build ./..."
  $Info.Test = "go test ./..."
  $Info.Lint = if (Test-AnyPath @((Join-Path $ProjectRoot ".golangci.yml"), (Join-Path $ProjectRoot ".golangci.yaml"))) { "golangci-lint run" } else { "go vet ./..." }
  Add-Note -Info $Info -Text "Detected from go.mod."
  $Info.Source = "detected:go"
  return $true
}

function Detect-Rust {
  param([string]$ProjectRoot, $Info)

  if (-not (Test-Path (Join-Path $ProjectRoot "Cargo.toml"))) { return $false }

  $Info.Language = "Rust"
  $Info.Framework = "Rust application"
  $Info.Runtime = "Native binary"
  $Info.Install = "cargo fetch"
  $Info.Build = "cargo build"
  $Info.Test = "cargo test"
  $Info.Lint = "cargo clippy --all-targets --all-features -- -D warnings"
  Add-Note -Info $Info -Text "Detected from Cargo.toml."
  $Info.Source = "detected:rust"
  return $true
}

function Detect-DotNet {
  param([string]$ProjectRoot, $Info)

  $sln = Get-ChildItem -Path $ProjectRoot -Filter *.sln -File -ErrorAction SilentlyContinue
  $csproj = Get-ChildItem -Path $ProjectRoot -Filter *.csproj -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $sln -and -not $csproj) { return $false }

  $program = Get-FileText -Path (Join-Path $ProjectRoot "Program.cs")
  $Info.Language = "C#"
  $Info.Framework = if ($program -match "WebApplication\.CreateBuilder") { "ASP.NET Core" } else { ".NET application" }
  $Info.Runtime = ".NET"
  $Info.Install = "dotnet restore"
  $Info.Build = "dotnet build"
  $Info.Test = "dotnet test"
  $Info.Lint = "dotnet format --verify-no-changes"
  Add-Note -Info $Info -Text "Detected from .sln/.csproj."
  $Info.Source = "detected:dotnet"
  return $true
}

function Infer-FromContext {
  param([string]$ContextText, $Info)

  if (-not $ContextText) { return $false }
  $ctx = $ContextText.ToLowerInvariant()

  if ($ctx -match "next(\.js|js)?|react") {
    $Info.Language = if ($ctx -match "javascript") { "JavaScript" } else { "TypeScript" }
    $Info.Framework = if ($ctx -match "next") { "Next.js" } else { "React" }
    $Info.Runtime = "Node.js"
    $Info.Install = "npm install"
    $Info.Build = "npm run build"
    $Info.Test = "npm run test"
    $Info.Lint = "npm run lint"
    Add-Note -Info $Info -Text "Inferred from context text."
    $Info.Source = "context:node"
    return $true
  }

  if ($ctx -match "spring|java|maven") {
    $Info.Language = "Java"
    $Info.Framework = if ($ctx -match "spring") { "Spring Boot" } else { "Java application" }
    $Info.Runtime = "JVM"
    $Info.Install = "mvn -DskipTests compile"
    $Info.Build = "mvn clean package"
    $Info.Test = "mvn test"
    $Info.Lint = "mvn spotless:check"
    Add-Note -Info $Info -Text "Inferred from context text."
    $Info.Source = "context:java"
    return $true
  }

  if ($ctx -match "fastapi|django|flask|python") {
    $Info.Language = "Python"
    if ($ctx -match "fastapi") {
      $Info.Framework = "FastAPI"
    } elseif ($ctx -match "django") {
      $Info.Framework = "Django"
    } elseif ($ctx -match "flask") {
      $Info.Framework = "Flask"
    } else {
      $Info.Framework = "Python application"
    }
    $Info.Runtime = "Python 3.x"
    $Info.Install = "pip install -r requirements.txt"
    $Info.Build = "python -m build"
    $Info.Test = "pytest"
    $Info.Lint = "ruff check ."
    Add-Note -Info $Info -Text "Inferred from context text."
    $Info.Source = "context:python"
    return $true
  }

  if ($ctx -match "\bgo(lang)?\b") {
    $Info.Language = "Go"
    $Info.Framework = "Go application"
    $Info.Runtime = "Go runtime"
    $Info.Install = "go mod download"
    $Info.Build = "go build ./..."
    $Info.Test = "go test ./..."
    $Info.Lint = "go vet ./..."
    Add-Note -Info $Info -Text "Inferred from context text."
    $Info.Source = "context:go"
    return $true
  }

  if ($ctx -match "rust|cargo") {
    $Info.Language = "Rust"
    $Info.Framework = "Rust application"
    $Info.Runtime = "Native binary"
    $Info.Install = "cargo fetch"
    $Info.Build = "cargo build"
    $Info.Test = "cargo test"
    $Info.Lint = "cargo clippy --all-targets --all-features -- -D warnings"
    Add-Note -Info $Info -Text "Inferred from context text."
    $Info.Source = "context:rust"
    return $true
  }

  if ($ctx -match "dotnet|\.net|c#|asp\.net") {
    $Info.Language = "C#"
    $Info.Framework = if ($ctx -match "asp\.net") { "ASP.NET Core" } else { ".NET application" }
    $Info.Runtime = ".NET"
    $Info.Install = "dotnet restore"
    $Info.Build = "dotnet build"
    $Info.Test = "dotnet test"
    $Info.Lint = "dotnet format --verify-no-changes"
    Add-Note -Info $Info -Text "Inferred from context text."
    $Info.Source = "context:dotnet"
    return $true
  }

  return $false
}

function Fill-GuidedDefaults {
  param($Info)
  if (-not $Info.Language) { $Info.Language = "TBD (pick language)" }
  if (-not $Info.Framework) { $Info.Framework = "TBD (pick framework)" }
  if (-not $Info.Runtime) { $Info.Runtime = "TBD (pick runtime)" }
  if (-not $Info.Install) { $Info.Install = "TBD" }
  if (-not $Info.Build) { $Info.Build = "TBD" }
  if (-not $Info.Test) { $Info.Test = "TBD" }
  if (-not $Info.Lint) { $Info.Lint = "TBD" }

  Add-GuidedPrompt -Info $Info -Text "Language and framework?"
  Add-GuidedPrompt -Info $Info -Text "Main runtime version requirement?"
  Add-GuidedPrompt -Info $Info -Text "Preferred package/dependency manager?"
  Add-GuidedPrompt -Info $Info -Text "Default build, test and lint commands?"
  Add-GuidedPrompt -Info $Info -Text "Any banned dependencies or architecture constraints?"
}

function Render-ProjectContract {
  param($Info, [string]$ContextText, [string]$ModeValue)
  $generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"

  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add("# Project Contract")
  $lines.Add("")
  $lines.Add("This file defines project-wide constraints for minispec execution.")
  $lines.Add("")
  $lines.Add("## Stack")
  $lines.Add("")
  $lines.Add("- Language: $($Info.Language)")
  $lines.Add("- Framework: $($Info.Framework)")
  $lines.Add("- Runtime: $($Info.Runtime)")
  $lines.Add("")
  $lines.Add("## Commands")
  $lines.Add("")
  $lines.Add("- Install: $($Info.Install)")
  $lines.Add("- Build: $($Info.Build)")
  $lines.Add("- Test: $($Info.Test)")
  $lines.Add("- Lint: $($Info.Lint)")
  $lines.Add("")
  $lines.Add("## Engineering Constraints")
  $lines.Add("")
  $lines.Add("- Do not introduce new runtime dependencies without explicit approval.")
  $lines.Add("- Keep changes minimal and focused on accepted scope.")
  $lines.Add("- Add or update tests for behavior changes.")
  $lines.Add("")
  $lines.Add("## Non-Goals")
  $lines.Add("")
  $lines.Add("- Large refactors without a dedicated change card.")
  $lines.Add("- Unrelated cleanup during feature delivery.")
  $lines.Add("")
  $lines.Add("## Definition of Done")
  $lines.Add("")
  $lines.Add("- Acceptance checklist in change card is fully checked.")
  $lines.Add("- Tests pass locally with the defined project test command.")
  $lines.Add('- Related canonical spec in `minispec/specs/` is updated.')
  $lines.Add("")
  $lines.Add("## Generation Metadata")
  $lines.Add("")
  $lines.Add("- Source: $($Info.Source)")
  $lines.Add("- Mode: $ModeValue")
  $lines.Add("- Generated at: $generatedAt")

  if ($ContextText) {
    $lines.Add("- Context hint: $ContextText")
  }

  if ($Info.Notes.Count -gt 0) {
    $lines.Add("")
    $lines.Add("## Detection Notes")
    $lines.Add("")
    foreach ($n in $Info.Notes) {
      $lines.Add("- $n")
    }
  }

  if ($Info.Guided.Count -gt 0) {
    $lines.Add("")
    $lines.Add("## Guided Inputs")
    $lines.Add("")
    foreach ($q in $Info.Guided) {
      $lines.Add("- $q")
    }
  }

  return ($lines -join "`r`n") + "`r`n"
}

$rootPath = Resolve-Path $Root
$minispecRoot = Join-Path $rootPath "minispec"
if (-not (Test-Path $minispecRoot)) {
  New-Item -ItemType Directory -Path $minispecRoot | Out-Null
}

$projectPath = Join-Path $minispecRoot "project.md"
$hasMarkers = Test-AnyPath @(
  (Join-Path $rootPath "package.json"),
  (Join-Path $rootPath "pom.xml"),
  (Join-Path $rootPath "build.gradle"),
  (Join-Path $rootPath "build.gradle.kts"),
  (Join-Path $rootPath "pyproject.toml"),
  (Join-Path $rootPath "requirements.txt"),
  (Join-Path $rootPath "go.mod"),
  (Join-Path $rootPath "Cargo.toml")
)

$effectiveMode = $Mode
if ($Mode -eq "auto") {
  $effectiveMode = if ($hasMarkers) { "existing" } else { "new" }
}

$info = New-StackInfo
$detected = $false

if ($effectiveMode -eq "existing") {
  $detected = (Detect-Node -ProjectRoot $rootPath -Info $info) -or
              (Detect-Maven -ProjectRoot $rootPath -Info $info) -or
              (Detect-Gradle -ProjectRoot $rootPath -Info $info) -or
              (Detect-Python -ProjectRoot $rootPath -Info $info) -or
              (Detect-Go -ProjectRoot $rootPath -Info $info) -or
              (Detect-Rust -ProjectRoot $rootPath -Info $info) -or
              (Detect-DotNet -ProjectRoot $rootPath -Info $info)

  if (-not $detected) {
    Add-Note -Info $info -Text "No known project markers detected. Fallback to guided fields."
    [void](Infer-FromContext -ContextText $Context -Info $info)
    Fill-GuidedDefaults -Info $info
    $info.Source = "guided:fallback"
  }
} else {
  $detected = Infer-FromContext -ContextText $Context -Info $info
  if (-not $detected) {
    Fill-GuidedDefaults -Info $info
    $info.Source = "guided:new-project"
  }
}

if (Test-Path $projectPath) {
  $timestamp = Get-Date -Format "yyyyMMddHHmmss"
  $backupPath = "$projectPath.bak.$timestamp"
  Copy-Item -Path $projectPath -Destination $backupPath -Force
  Write-Output "Backup created: $backupPath"
}

$body = Render-ProjectContract -Info $info -ContextText $Context -ModeValue $effectiveMode
Set-Content -Path $projectPath -Value $body -Encoding UTF8

Write-Output "Generated minispec/project.md"
Write-Output "Mode: $effectiveMode"
Write-Output "Source: $($info.Source)"
if ($info.Guided.Count -gt 0) {
  Write-Output "Guided inputs are included in project.md for manual refinement."
}
