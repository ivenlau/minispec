#!/usr/bin/env sh
set -eu

ROOT="${1:-.}"
MODE="${2:-auto}"
if [ "$#" -gt 2 ]; then
  shift 2
  CONTEXT="$*"
else
  CONTEXT=""
fi

ROOT="$(cd "$ROOT" && pwd)"
MINISPEC_ROOT="$ROOT/minispec"
PROJECT_PATH="$MINISPEC_ROOT/project.md"
mkdir -p "$MINISPEC_ROOT"

LANGUAGE=""
FRAMEWORK=""
RUNTIME=""
INSTALL_CMD=""
BUILD_CMD=""
TEST_CMD=""
LINT_CMD=""
SOURCE_TAG="guided"
NOTES=""
GUIDED=""

add_note() {
  txt="$1"
  if [ -n "$txt" ]; then
    NOTES="${NOTES}- ${txt}
"
  fi
}

add_guided() {
  txt="$1"
  if [ -n "$txt" ]; then
    GUIDED="${GUIDED}- ${txt}
"
  fi
}

set_guided_defaults() {
  [ -n "$LANGUAGE" ] || LANGUAGE="TBD (pick language)"
  [ -n "$FRAMEWORK" ] || FRAMEWORK="TBD (pick framework)"
  [ -n "$RUNTIME" ] || RUNTIME="TBD (pick runtime)"
  [ -n "$INSTALL_CMD" ] || INSTALL_CMD="TBD"
  [ -n "$BUILD_CMD" ] || BUILD_CMD="TBD"
  [ -n "$TEST_CMD" ] || TEST_CMD="TBD"
  [ -n "$LINT_CMD" ] || LINT_CMD="TBD"

  add_guided "Language and framework?"
  add_guided "Main runtime version requirement?"
  add_guided "Preferred package/dependency manager?"
  add_guided "Default build, test and lint commands?"
  add_guided "Any banned dependencies or architecture constraints?"
}

contains_file_text() {
  file="$1"
  pattern="$2"
  if [ ! -f "$file" ]; then
    return 1
  fi
  grep -Eiq "$pattern" "$file"
}

pkg_dep_names() {
  # Print dep names from .dependencies and .devDependencies in a package.json
  # (one name per line). Uses jq when available; otherwise a best-effort awk
  # parser that handles npm-init-formatted files (one dep per line).
  pkg_file="$1"
  [ -f "$pkg_file" ] || return 0
  if command -v jq >/dev/null 2>&1; then
    jq -r '((.dependencies // {}) + (.devDependencies // {})) | keys[]' "$pkg_file" 2>/dev/null
    return 0
  fi
  awk '
    BEGIN { in_dep = 0 }
    /"(dependencies|devDependencies)"[[:space:]]*:[[:space:]]*\{/ { in_dep = 1; next }
    in_dep && /^[[:space:]]*\}/ { in_dep = 0; next }
    in_dep && /^[[:space:]]*"[^"]+"[[:space:]]*:/ {
      line = $0
      sub(/^[[:space:]]*"/, "", line)
      sub(/"[[:space:]]*:.*$/, "", line)
      print line
    }
  ' "$pkg_file"
}

pkg_has_dep() {
  dep_name="$1"
  file="${2:-$ROOT/package.json}"
  pkg_dep_names "$file" | grep -Fxq -- "$dep_name"
}

has_project_markers() {
  [ -f "$ROOT/package.json" ] || \
  [ -f "$ROOT/pom.xml" ] || \
  [ -f "$ROOT/build.gradle" ] || \
  [ -f "$ROOT/build.gradle.kts" ] || \
  [ -f "$ROOT/pyproject.toml" ] || \
  [ -f "$ROOT/requirements.txt" ] || \
  [ -f "$ROOT/go.mod" ] || \
  [ -f "$ROOT/Cargo.toml" ] || \
  ls "$ROOT"/*.sln >/dev/null 2>&1 || \
  ls "$ROOT"/*.csproj >/dev/null 2>&1
}

cmd_for_node_script() {
  manager="$1"
  script="$2"
  case "$manager" in
    pnpm) printf 'pnpm run %s' "$script" ;;
    yarn) printf 'yarn %s' "$script" ;;
    bun) printf 'bun run %s' "$script" ;;
    *) printf 'npm run %s' "$script" ;;
  esac
}

detect_node() {
  pkg="$ROOT/package.json"
  [ -f "$pkg" ] || return 1

  manager="npm"
  [ -f "$ROOT/pnpm-lock.yaml" ] && manager="pnpm"
  [ -f "$ROOT/yarn.lock" ] && manager="yarn"
  if [ -f "$ROOT/bun.lockb" ] || [ -f "$ROOT/bun.lock" ]; then
    manager="bun"
  fi

  if [ -f "$ROOT/tsconfig.json" ] || pkg_has_dep "typescript" "$pkg"; then
    LANGUAGE="TypeScript"
  else
    LANGUAGE="JavaScript"
  fi
  RUNTIME="Node.js"

  if pkg_has_dep "next" "$pkg"; then
    FRAMEWORK="Next.js"
  elif pkg_has_dep "@nestjs/core" "$pkg"; then
    FRAMEWORK="NestJS"
  elif pkg_has_dep "nuxt" "$pkg"; then
    FRAMEWORK="Nuxt"
  elif pkg_has_dep "react" "$pkg"; then
    FRAMEWORK="React"
  elif pkg_has_dep "vue" "$pkg"; then
    FRAMEWORK="Vue"
  elif pkg_has_dep "@sveltejs/kit" "$pkg" || pkg_has_dep "svelte" "$pkg"; then
    FRAMEWORK="Svelte/SvelteKit"
  elif pkg_has_dep "express" "$pkg"; then
    FRAMEWORK="Express"
  elif pkg_has_dep "fastify" "$pkg"; then
    FRAMEWORK="Fastify"
  elif pkg_has_dep "koa" "$pkg"; then
    FRAMEWORK="Koa"
  else
    FRAMEWORK="Node.js application"
  fi

  case "$manager" in
    pnpm) INSTALL_CMD="pnpm install" ;;
    yarn) INSTALL_CMD="yarn install" ;;
    bun) INSTALL_CMD="bun install" ;;
    *) INSTALL_CMD="npm install" ;;
  esac

  if contains_file_text "$pkg" '"build"[[:space:]]*:'; then
    BUILD_CMD="$(cmd_for_node_script "$manager" "build")"
  else
    BUILD_CMD="Not defined (add build script in package.json)"
  fi

  if contains_file_text "$pkg" '"test"[[:space:]]*:'; then
    TEST_CMD="$(cmd_for_node_script "$manager" "test")"
  else
    TEST_CMD="Not defined (add test script in package.json)"
  fi

  if contains_file_text "$pkg" '"lint"[[:space:]]*:'; then
    LINT_CMD="$(cmd_for_node_script "$manager" "lint")"
  else
    LINT_CMD="Not defined (add lint script in package.json)"
  fi

  add_note "Detected from package.json and lockfile."
  SOURCE_TAG="detected:node"
  return 0
}

detect_maven() {
  pom="$ROOT/pom.xml"
  [ -f "$pom" ] || return 1
  LANGUAGE="Java"
  if contains_file_text "$pom" 'spring-boot|springframework\.boot'; then
    FRAMEWORK="Spring Boot"
  else
    FRAMEWORK="Java (Maven)"
  fi
  RUNTIME="JVM"
  INSTALL_CMD="mvn -DskipTests compile"
  BUILD_CMD="mvn clean package"
  TEST_CMD="mvn test"
  if contains_file_text "$pom" 'spotless-maven-plugin'; then
    LINT_CMD="mvn spotless:check"
  elif contains_file_text "$pom" 'maven-checkstyle-plugin'; then
    LINT_CMD="mvn checkstyle:check"
  else
    LINT_CMD="Not defined (configure spotless/checkstyle)"
  fi
  add_note "Detected from pom.xml."
  SOURCE_TAG="detected:maven"
  return 0
}

detect_gradle() {
  gradle="$ROOT/build.gradle"
  gradle_kts="$ROOT/build.gradle.kts"
  [ -f "$gradle" ] || [ -f "$gradle_kts" ] || return 1
  LANGUAGE="Java/Kotlin"
  if contains_file_text "$gradle" 'spring-boot|org\.springframework\.boot' || \
     contains_file_text "$gradle_kts" 'spring-boot|org\.springframework\.boot'; then
    FRAMEWORK="Spring Boot"
  else
    FRAMEWORK="Gradle application"
  fi
  RUNTIME="JVM"
  INSTALL_CMD="./gradlew dependencies"
  BUILD_CMD="./gradlew build"
  TEST_CMD="./gradlew test"
  if contains_file_text "$gradle" 'checkstyle|spotless' || \
     contains_file_text "$gradle_kts" 'checkstyle|spotless'; then
    LINT_CMD="./gradlew check"
  else
    LINT_CMD="Not defined (configure checkstyle/spotless)"
  fi
  add_note "Detected from Gradle build files."
  SOURCE_TAG="detected:gradle"
  return 0
}

detect_python() {
  pyproject="$ROOT/pyproject.toml"
  req="$ROOT/requirements.txt"
  setup="$ROOT/setup.py"
  [ -f "$pyproject" ] || [ -f "$req" ] || [ -f "$setup" ] || return 1
  LANGUAGE="Python"
  RUNTIME="Python 3.x"

  if contains_file_text "$pyproject" 'fastapi' || contains_file_text "$req" 'fastapi'; then
    FRAMEWORK="FastAPI"
  elif contains_file_text "$pyproject" 'django' || contains_file_text "$req" 'django'; then
    FRAMEWORK="Django"
  elif contains_file_text "$pyproject" 'flask' || contains_file_text "$req" 'flask'; then
    FRAMEWORK="Flask"
  else
    FRAMEWORK="Python application"
  fi

  if [ -f "$ROOT/uv.lock" ]; then
    INSTALL_CMD="uv sync"
  elif [ -f "$ROOT/poetry.lock" ]; then
    INSTALL_CMD="poetry install"
  elif [ -f "$req" ]; then
    INSTALL_CMD="pip install -r requirements.txt"
  else
    INSTALL_CMD="pip install -e ."
  fi

  if [ -f "$pyproject" ]; then
    BUILD_CMD="python -m build"
  else
    BUILD_CMD="Not defined (optional for app-only repositories)"
  fi

  if [ -d "$ROOT/tests" ] || contains_file_text "$pyproject" 'pytest' || contains_file_text "$req" 'pytest'; then
    TEST_CMD="pytest"
  else
    TEST_CMD="Not defined (add pytest)"
  fi

  if contains_file_text "$pyproject" 'ruff' || contains_file_text "$req" 'ruff'; then
    LINT_CMD="ruff check ."
  elif contains_file_text "$pyproject" 'flake8' || contains_file_text "$req" 'flake8'; then
    LINT_CMD="flake8 ."
  else
    LINT_CMD="Not defined (add ruff or flake8)"
  fi

  add_note "Detected from pyproject.toml/requirements.txt."
  SOURCE_TAG="detected:python"
  return 0
}

detect_go() {
  [ -f "$ROOT/go.mod" ] || return 1
  LANGUAGE="Go"
  FRAMEWORK="Go application"
  RUNTIME="Go runtime"
  INSTALL_CMD="go mod download"
  BUILD_CMD="go build ./..."
  TEST_CMD="go test ./..."
  if [ -f "$ROOT/.golangci.yml" ] || [ -f "$ROOT/.golangci.yaml" ]; then
    LINT_CMD="golangci-lint run"
  else
    LINT_CMD="go vet ./..."
  fi
  add_note "Detected from go.mod."
  SOURCE_TAG="detected:go"
  return 0
}

detect_rust() {
  [ -f "$ROOT/Cargo.toml" ] || return 1
  LANGUAGE="Rust"
  FRAMEWORK="Rust application"
  RUNTIME="Native binary"
  INSTALL_CMD="cargo fetch"
  BUILD_CMD="cargo build"
  TEST_CMD="cargo test"
  LINT_CMD="cargo clippy --all-targets --all-features -- -D warnings"
  add_note "Detected from Cargo.toml."
  SOURCE_TAG="detected:rust"
  return 0
}

detect_dotnet() {
  if ! (ls "$ROOT"/*.sln >/dev/null 2>&1 || ls "$ROOT"/*.csproj >/dev/null 2>&1 || find "$ROOT" -name '*.csproj' -print -quit 2>/dev/null | grep -q .); then
    return 1
  fi
  LANGUAGE="C#"
  if contains_file_text "$ROOT/Program.cs" 'WebApplication\.CreateBuilder'; then
    FRAMEWORK="ASP.NET Core"
  else
    FRAMEWORK=".NET application"
  fi
  RUNTIME=".NET"
  INSTALL_CMD="dotnet restore"
  BUILD_CMD="dotnet build"
  TEST_CMD="dotnet test"
  LINT_CMD="dotnet format --verify-no-changes"
  add_note "Detected from .sln/.csproj."
  SOURCE_TAG="detected:dotnet"
  return 0
}

infer_from_context() {
  [ -n "$CONTEXT" ] || return 1
  ctx="$(printf '%s' "$CONTEXT" | tr '[:upper:]' '[:lower:]')"

  if printf '%s' "$ctx" | grep -Eq 'next(\.js|js)?|react'; then
    if printf '%s' "$ctx" | grep -Eq 'javascript'; then
      LANGUAGE="JavaScript"
    else
      LANGUAGE="TypeScript"
    fi
    if printf '%s' "$ctx" | grep -Eq 'next'; then
      FRAMEWORK="Next.js"
    else
      FRAMEWORK="React"
    fi
    RUNTIME="Node.js"
    INSTALL_CMD="npm install"
    BUILD_CMD="npm run build"
    TEST_CMD="npm run test"
    LINT_CMD="npm run lint"
    add_note "Inferred from context text."
    SOURCE_TAG="context:node"
    return 0
  fi

  if printf '%s' "$ctx" | grep -Eq 'spring|java|maven'; then
    LANGUAGE="Java"
    if printf '%s' "$ctx" | grep -Eq 'spring'; then
      FRAMEWORK="Spring Boot"
    else
      FRAMEWORK="Java application"
    fi
    RUNTIME="JVM"
    INSTALL_CMD="mvn -DskipTests compile"
    BUILD_CMD="mvn clean package"
    TEST_CMD="mvn test"
    LINT_CMD="mvn spotless:check"
    add_note "Inferred from context text."
    SOURCE_TAG="context:java"
    return 0
  fi

  if printf '%s' "$ctx" | grep -Eq 'fastapi|django|flask|python'; then
    LANGUAGE="Python"
    if printf '%s' "$ctx" | grep -Eq 'fastapi'; then
      FRAMEWORK="FastAPI"
    elif printf '%s' "$ctx" | grep -Eq 'django'; then
      FRAMEWORK="Django"
    elif printf '%s' "$ctx" | grep -Eq 'flask'; then
      FRAMEWORK="Flask"
    else
      FRAMEWORK="Python application"
    fi
    RUNTIME="Python 3.x"
    INSTALL_CMD="pip install -r requirements.txt"
    BUILD_CMD="python -m build"
    TEST_CMD="pytest"
    LINT_CMD="ruff check ."
    add_note "Inferred from context text."
    SOURCE_TAG="context:python"
    return 0
  fi

  if printf '%s' "$ctx" | grep -Eq '\bgo(lang)?\b'; then
    LANGUAGE="Go"
    FRAMEWORK="Go application"
    RUNTIME="Go runtime"
    INSTALL_CMD="go mod download"
    BUILD_CMD="go build ./..."
    TEST_CMD="go test ./..."
    LINT_CMD="go vet ./..."
    add_note "Inferred from context text."
    SOURCE_TAG="context:go"
    return 0
  fi

  if printf '%s' "$ctx" | grep -Eq 'rust|cargo'; then
    LANGUAGE="Rust"
    FRAMEWORK="Rust application"
    RUNTIME="Native binary"
    INSTALL_CMD="cargo fetch"
    BUILD_CMD="cargo build"
    TEST_CMD="cargo test"
    LINT_CMD="cargo clippy --all-targets --all-features -- -D warnings"
    add_note "Inferred from context text."
    SOURCE_TAG="context:rust"
    return 0
  fi

  if printf '%s' "$ctx" | grep -Eq 'dotnet|\.net|c#|asp\.net'; then
    LANGUAGE="C#"
    if printf '%s' "$ctx" | grep -Eq 'asp\.net'; then
      FRAMEWORK="ASP.NET Core"
    else
      FRAMEWORK=".NET application"
    fi
    RUNTIME=".NET"
    INSTALL_CMD="dotnet restore"
    BUILD_CMD="dotnet build"
    TEST_CMD="dotnet test"
    LINT_CMD="dotnet format --verify-no-changes"
    add_note "Inferred from context text."
    SOURCE_TAG="context:dotnet"
    return 0
  fi

  return 1
}

if [ "$MODE" = "auto" ]; then
  if has_project_markers; then
    MODE="existing"
  else
    MODE="new"
  fi
fi

detected=0
if [ "$MODE" = "existing" ]; then
  if detect_node || detect_maven || detect_gradle || detect_python || detect_go || detect_rust || detect_dotnet; then
    detected=1
  fi

  if [ "$detected" -eq 0 ]; then
    add_note "No known project markers detected. Fallback to guided fields."
    if infer_from_context; then
      :
    fi
    set_guided_defaults
    SOURCE_TAG="guided:fallback"
  fi
else
  if infer_from_context; then
    :
  else
    set_guided_defaults
    SOURCE_TAG="guided:new-project"
  fi
fi

maintainer_notes=""
if [ -f "$PROJECT_PATH" ]; then
  maintainer_notes="$(awk '
    /^## Maintainer Notes[[:space:]]*$/ { in_section=1; print; next }
    in_section && /^## / { exit }
    in_section { print }
  ' "$PROJECT_PATH")"
fi

if [ -f "$PROJECT_PATH" ]; then
  ts="$(date +%Y%m%d%H%M%S)"
  backup_path="${PROJECT_PATH}.bak.${ts}"
  cp "$PROJECT_PATH" "$backup_path"
  printf 'Backup created: %s\n' "$backup_path"
fi

generated_at="$(date '+%Y-%m-%d %H:%M:%S %z')"

cat > "$PROJECT_PATH" <<EOF
# Project Contract

This file defines project-wide constraints for minispec execution.

## Stack

- Language: ${LANGUAGE}
- Framework: ${FRAMEWORK}
- Runtime: ${RUNTIME}

## Commands

- Install: ${INSTALL_CMD}
- Build: ${BUILD_CMD}
- Test: ${TEST_CMD}
- Lint: ${LINT_CMD}

## Engineering Constraints

- Do not introduce new runtime dependencies without explicit approval.
- Keep changes minimal and focused on accepted scope.
- Add or update tests for behavior changes.

## Non-Goals

- Large refactors without a dedicated change card.
- Unrelated cleanup during feature delivery.

## Definition of Done

- Acceptance checklist in change card is fully checked.
- Tests pass locally with the defined project test command.
- Related canonical spec in \`minispec/specs/\` is updated.

## Generation Metadata

- Source: ${SOURCE_TAG}
- Mode: ${MODE}
- Generated at: ${generated_at}
EOF

if [ -n "$CONTEXT" ]; then
  printf '%s\n' "- Context hint: ${CONTEXT}" >> "$PROJECT_PATH"
fi

if [ -n "$NOTES" ]; then
  cat >> "$PROJECT_PATH" <<EOF

## Detection Notes

EOF
  printf '%s' "$NOTES" >> "$PROJECT_PATH"
fi

if [ -n "$GUIDED" ]; then
  cat >> "$PROJECT_PATH" <<EOF

## Guided Inputs

EOF
  printf '%s' "$GUIDED" >> "$PROJECT_PATH"
fi

if [ -n "$maintainer_notes" ]; then
  printf '\n' >> "$PROJECT_PATH"
  printf '%s\n' "$maintainer_notes" >> "$PROJECT_PATH"
else
  cat >> "$PROJECT_PATH" <<'EOF'

## Maintainer Notes

<!-- manual-managed; preserved across ms-project regenerations -->
EOF
fi

printf 'Generated minispec/project.md\n'
printf 'Mode: %s\n' "$MODE"
printf 'Source: %s\n' "$SOURCE_TAG"
if [ -n "$GUIDED" ]; then
  printf 'Guided inputs are included in project.md for manual refinement.\n'
fi

