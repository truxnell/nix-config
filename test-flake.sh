#!/usr/bin/env bash
# Comprehensive flake validation script
# Runs fast validation tests without building derivations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

ERRORS=0

echo "🧪 Running comprehensive flake validation tests..."
echo ""

# 1. Quick syntax check
echo "1️⃣  Checking Nix syntax..."
if ! nix-instantiate --parse flake.nix > /dev/null 2>&1; then
    echo "❌ Syntax check failed"
    ((ERRORS++))
else
    echo "✅ Syntax check passed"
fi
echo ""

# 2. Flake metadata check
echo "2️⃣  Validating flake metadata..."
if ! nix flake metadata --no-write-lock-file > /dev/null 2>&1; then
    echo "❌ Flake metadata validation failed"
    ((ERRORS++))
else
    echo "✅ Flake metadata valid"
fi
echo ""

# 3. Flake show (list outputs)
echo "3️⃣  Verifying flake outputs..."
if ! nix flake show --no-write-lock-file > /dev/null 2>&1; then
    echo "❌ Flake show failed"
    ((ERRORS++))
else
    echo "✅ Flake outputs accessible"
fi
echo ""

# 4. Flake check (no build)
echo "4️⃣  Running flake check (no build)..."
if ! nix flake check --no-build > /dev/null 2>&1; then
    echo "❌ Flake check failed"
    nix flake check --no-build
    ((ERRORS++))
else
    echo "✅ Flake check passed"
fi
echo ""

# 5. Evaluate all host configurations
echo "5️⃣  Evaluating host configurations..."
HOSTS=$(nix eval .#nixosConfigurations --apply 'x: builtins.attrNames x' --json 2>/dev/null | jq -r '.[]')
for host in $HOSTS; do
    if nix eval --impure ".#nixosConfigurations.${host}.config.system.name" > /dev/null 2>&1; then
        echo "✅ ${host} configuration evaluates"
    else
        echo "❌ ${host} configuration evaluation failed"
        ((ERRORS++))
    fi
done
echo ""

# 6. Evaluate lib output
echo "6️⃣  Verifying lib output..."
if nix eval --impure .#lib --apply 'x: builtins.attrNames x' > /dev/null 2>&1; then
    echo "✅ Lib output accessible"
else
    echo "❌ Lib output validation failed"
    ((ERRORS++))
fi
echo ""

# 7. Application import validation
echo "7️⃣  Validating application imports..."
SERVICES_FILE="nixos/modules/nixos/services/default.nix"
CONTAINERS_FILE="nixos/modules/nixos/containers/default.nix"

if [ ! -f "$SERVICES_FILE" ]; then
    echo "❌ Services file not found: $SERVICES_FILE"
    ((ERRORS++))
else
    # Check service imports
    while IFS= read -r import_path; do
        if [[ $import_path =~ applications/([^/]+/[^/]+) ]]; then
            app_path="nixos/modules/applications/${BASH_REMATCH[1]}/default.nix"
            if [ ! -f "$app_path" ]; then
                echo "❌ Missing application: $app_path (referenced in services/default.nix)"
                ((ERRORS++))
            fi
        fi
    done < <(grep -E "applications/[^/]+/[^/]+" "$SERVICES_FILE" 2>/dev/null || true)
fi

if [ ! -f "$CONTAINERS_FILE" ]; then
    echo "❌ Containers file not found: $CONTAINERS_FILE"
    ((ERRORS++))
else
    # Check container imports
    while IFS= read -r import_path; do
        if [[ $import_path =~ applications/([^/]+/[^/]+) ]]; then
            app_path="nixos/modules/applications/${BASH_REMATCH[1]}/default.nix"
            if [ ! -f "$app_path" ]; then
                echo "❌ Missing application: $app_path (referenced in containers/default.nix)"
                ((ERRORS++))
            fi
        fi
    done < <(grep -E "applications/[^/]+/[^/]+" "$CONTAINERS_FILE" 2>/dev/null || true)
fi

if [ $ERRORS -eq 0 ]; then
    echo "✅ All application imports valid"
fi
echo ""

# 8. SOPS secrets validation (check that .sops.yaml files are encrypted)
echo "8️⃣  Validating SOPS secrets..."
SOPS_ERRORS=0
while IFS= read -r sops_file; do
    # Check if file appears to be encrypted (contains "ENC[" or "sops:")
    if ! grep -q "ENC\[" "$sops_file" 2>/dev/null && ! grep -q "sops:" "$sops_file" 2>/dev/null; then
        echo "⚠️  Possible unencrypted SOPS file: $sops_file"
        ((SOPS_ERRORS++))
    fi
done < <(find . -name "*.sops.yaml" -type f ! -name ".sops.yaml" 2>/dev/null || true)

if [ $SOPS_ERRORS -eq 0 ]; then
    echo "✅ SOPS secrets appear encrypted"
else
    echo "⚠️  Found $SOPS_ERRORS potentially unencrypted SOPS file(s)"
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ERRORS -eq 0 ]; then
    echo "✅ All validation tests passed!"
    exit 0
else
    echo "❌ Validation failed with $ERRORS error(s)"
    exit 1
fi
