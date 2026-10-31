#!/usr/bin/env bash
# Tests for bin/av-load-from-op using stub `op` and `av` shims on PATH.
# The real op and av are never called. Runs in CI and locally.
#
# Usage:
#   ./scripts/test-av-load-from-op.sh

set -u

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOL="$DIR/bin/av-load-from-op"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

SECRET="s3cr3t-value-must-never-print"
SHIMS="$TEST_DIR/shims"
mkdir -p "$SHIMS" "$TEST_DIR/repo"

# op stub: logs argv, emits the secret for `read`; fails for any ref containing BOOM.
cat > "$SHIMS/op" << 'SH'
#!/usr/bin/env bash
echo "op $*" >> "$STUB_LOG"
case "$*" in *BOOM*) echo "op: item not found" >&2; exit 1 ;; esac
printf '%s' "$STUB_SECRET"
SH
# av stub: logs argv and cwd, stores stdin per key so the test can see what arrived.
cat > "$SHIMS/av" << 'SH'
#!/usr/bin/env bash
echo "av $* (cwd $PWD)" >> "$STUB_LOG"
key="${@: -1}"
cat > "$STUB_STORE.$key"
[[ -s "$STUB_STORE.$key" ]] || { echo "av: empty input" >&2; exit 1; }
[[ "${STUB_AV_FAIL:-}" == "$key" ]] && { echo "av: denied" >&2; exit 1; }
exit 0
SH
chmod +x "$SHIMS/op" "$SHIMS/av"

export STUB_LOG="$TEST_DIR/log" STUB_SECRET="$SECRET" STUB_STORE="$TEST_DIR/store"
export PATH="$SHIMS:$PATH"

cat > "$TEST_DIR/repo/secrets.map" << 'MAP'
# comment line
ALPHA=op://Vault/alpha/field

BETA=op://Vault/beta/field
GAMMA=TODO
MAP

cat > "$TEST_DIR/repo/.env.template" << 'TPL'
# a template
PLAIN=just-a-value
ALPHA={{ op://Vault/alpha/field }}
BETA={{op://Vault/beta/field}}
GAMMA={{ TODO }}
TPL

fail=0
pass() { echo "PASS: $1"; }
bad() {
  echo "FAIL: $1"
  fail=1
}
check() { # check "name" expected-rc
  if [[ "$RC" -eq "$2" ]]; then pass "$1"; else bad "$1 (exit $RC, wanted $2)"; fi
}
ALLOUT=""
run() { # run args... ; sets OUT (stdout+stderr) and RC, resets log and store
  : > "$STUB_LOG"
  rm -f "$STUB_STORE".*
  OUT=$("$TOOL" "$@" 2>&1)
  RC=$?
  ALLOUT+="$OUT"$'\n'
}
calls() { wc -l < "$STUB_LOG" | tr -d ' '; }

cd "$TEST_DIR/repo" || exit 1

# dry-run: lists keys, calls nothing
run --map secrets.map --dry-run
check "dry-run exits 0" 0
[[ "$(calls)" == 0 ]] && pass "dry-run never calls op or av" || bad "dry-run called op or av"
grep -q "ALPHA: would load from op://Vault/alpha/field" <<< "$OUT" && pass "dry-run lists ALPHA" || bad "dry-run lists ALPHA"
grep -q "GAMMA: skipped" <<< "$OUT" && pass "dry-run skips TODO when loading all" || bad "dry-run skips TODO"

# full load: pipes op into av for each real key, in the cwd
run --map secrets.map
check "load all exits 0" 0
grep -q "ALPHA: loaded" <<< "$OUT" && grep -q "BETA: loaded" <<< "$OUT" && pass "status line per key" || bad "status line per key"
grep -q "op read -n op://Vault/alpha/field" "$STUB_LOG" && pass "uses op read -n" || bad "uses op read -n"
grep -q "av save --stdin --project-directory=. ALPHA (cwd .*repo)" "$STUB_LOG" && pass "av save --stdin in the repo dir" || bad "av save invocation"
[[ "$(cat "$STUB_STORE.ALPHA")" == "$SECRET" ]] && pass "value reached av via stdin untouched" || bad "value did not reach av"
[[ ! -e "$STUB_STORE.GAMMA" ]] && pass "TODO key not loaded" || bad "TODO key was loaded"

# subset
run --map secrets.map BETA
check "subset exits 0" 0
[[ -e "$STUB_STORE.BETA" && ! -e "$STUB_STORE.ALPHA" ]] && pass "subset loads only BETA" || bad "subset loads only BETA"

# TODO refusal when named
run --map secrets.map GAMMA
check "named TODO is refused" 1
[[ "$(calls)" == 0 ]] && pass "TODO refusal calls nothing" || bad "TODO refusal called op or av"

# unknown key: validated before anything loads
run --map secrets.map ALPHA NOPE
check "unknown key exits 2" 2
[[ "$(calls)" == 0 ]] && pass "unknown key loads nothing, even valid ones" || bad "unknown key half-loaded"
grep -q "unknown key NOPE" <<< "$OUT" && pass "unknown key is named" || bad "unknown key message"

# template parsing
run --template .env.template --dry-run
check "template dry-run exits 0" 0
if grep -q "ALPHA: would load from op://Vault/alpha/field" <<< "$OUT" && grep -q "BETA: would load from op://Vault/beta/field" <<< "$OUT"; then
  pass "template refs parsed (with and without spaces)"
else
  bad "template parsing"
fi
if grep -q PLAIN <<< "$OUT"; then bad "template plain value treated as key"; else pass "template plain values ignored"; fi
run --template .env.template ALPHA
check "template load exits 0" 0

# -C
cd "$TEST_DIR" || exit 1
run -C repo --map secrets.map ALPHA
check "-C exits 0" 0
grep -q "(cwd .*repo)" "$STUB_LOG" && pass "-C runs av in the target dir" || bad "-C cwd"
cd "$TEST_DIR/repo" || exit 1

# failure propagation: op fails for one key, the rest still run, exit nonzero
cat > fail.map << 'MAP'
ALPHA=op://Vault/alpha/field
BAD=op://Vault/BOOM/field
BETA=op://Vault/beta/field
MAP
run --map fail.map
check "op failure exits 1" 1
grep -q "BAD: FAILED" <<< "$OUT" && pass "failed key reported" || bad "failed key reported"
grep -q "BETA: loaded" <<< "$OUT" && pass "later keys still load after a failure" || bad "later keys skipped"

# av failure
STUB_AV_FAIL=ALPHA run --map secrets.map ALPHA
check "av failure exits 1" 1

# bad input
run --map secrets.map --template .env.template
check "map and template together is a usage error" 2
run
check "no input file is a usage error" 2
printf 'ALPHA=op://V/i/f\nALPHA=op://V/i/g\n' > dup.map
run --map dup.map
check "duplicate key is an error" 2
printf 'ALPHA=not-a-reference\n' > nonop.map
run --map nonop.map
check "non-op reference is refused" 1

# no value ever printed
if grep -qF "$SECRET" <<< "$ALLOUT"; then bad "secret value appeared in tool output"; else pass "secret value never printed"; fi
if grep -qF "$SECRET" "$STUB_LOG"; then bad "secret value appeared in argv"; else pass "secret value never in argv"; fi

exit "$fail"
