#!/usr/bin/env bash
# Self-contained tests for the deferred-gate scaffold (deferred-check.sh +
# omakase-record.sh). Builds throwaway git repos in a temp dir; no network, no
# project deps. Run: bash tests/deferred-gates.test.sh
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECKER="$HERE/../payload/.omakase/gates/deferred-check.sh"
RECORDER="$HERE/../payload/.omakase/bin/omakase-record.sh"

# Isolate from the user's global/system git config (a leaked global
# core.hooksPath would otherwise fire lefthook inside the temp repos).
export GIT_CONFIG_SYSTEM=/dev/null
GIT_CONFIG_GLOBAL="$(mktemp)"; export GIT_CONFIG_GLOBAL

PASS=0 FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok   - $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL - $1"; }
check(){ if [[ "$2" == "$3" ]]; then ok "$1"; else bad "$1 (expected exit $2, got $3)"; fi; }

# Make a throwaway repo with one commit on master; echo its path (caller cd's in).
newrepo() {
  local d; d="$(mktemp -d)"
  git -C "$d" init -q -b master
  git -C "$d" config user.email t@t; git -C "$d" config user.name t
  git -C "$d" config core.hooksPath /dev/null   # never run hooks in the fixture
  echo base > "$d/base.txt"; git -C "$d" add -A; git -C "$d" commit -q --no-verify -m init
  printf '%s' "$d"
}

echo "deferred-check.sh"

# 1. Dormant when OMAKASE_CHECK unset.
d=$(newrepo); cd "$d"
( bash "$CHECKER" ) >/dev/null 2>&1; check "dormant when OMAKASE_CHECK unset" 0 $?

# 2. BLOCKER: no resolvable base ref -> fail-open exit 0 (not a git-error block).
d=$(newrepo); cd "$d"
( OMAKASE_CHECK=vv OMAKASE_GLOB='*.vue' bash "$CHECKER" ) >/dev/null 2>&1
check "no resolvable base fails open (exit 0)" 0 $?

# 3. Out-of-scope (no matching file in range) -> exit 0.
d=$(newrepo); cd "$d"
git checkout -q -b feat; echo x > note.txt; git add -A; git commit -q --no-verify -m note
( OMAKASE_CHECK=vv OMAKASE_GLOB='*.vue' OMAKASE_BASE=master bash "$CHECKER" ) >/dev/null 2>&1
check "out-of-scope passes (exit 0)" 0 $?

# 4. In-scope, no record -> block.
d=$(newrepo); cd "$d"
git checkout -q -b feat; echo '<template/>' > app.vue; git add -A; git commit -q --no-verify -m vue
( OMAKASE_CHECK=vv OMAKASE_GLOB='*.vue' OMAKASE_BASE=master bash "$CHECKER" ) >/dev/null 2>&1
check "in-scope + no record blocks (exit 1)" 1 $?

# 5. In-scope, fresh PASS record -> exit 0.
bash "$RECORDER" --check vv --verdict pass >/dev/null 2>&1
( OMAKASE_CHECK=vv OMAKASE_GLOB='*.vue' OMAKASE_BASE=master bash "$CHECKER" ) >/dev/null 2>&1
check "in-scope + fresh pass passes (exit 0)" 0 $?

# 6. Stale record (advance HEAD after recording) -> block.
echo '<template>2</template>' > app.vue; git add -A; git commit -q --no-verify -m vue2
( OMAKASE_CHECK=vv OMAKASE_GLOB='*.vue' OMAKASE_BASE=master bash "$CHECKER" ) >/dev/null 2>&1
check "stale record blocks (exit 1)" 1 $?

# 7. FAIL record -> block.
bash "$RECORDER" --check vv --verdict fail >/dev/null 2>&1
( OMAKASE_CHECK=vv OMAKASE_GLOB='*.vue' OMAKASE_BASE=master bash "$CHECKER" ) >/dev/null 2>&1
check "fail record blocks (exit 1)" 1 $?

# 8. Waiver (pass + reason) -> exit 0 and prints WAIVED banner.
bash "$RECORDER" --check vv --verdict pass --reason "judge wrong: known agent-browser limit" --original-verdict fail >/dev/null 2>&1
out=$( ( OMAKASE_CHECK=vv OMAKASE_GLOB='*.vue' OMAKASE_BASE=master bash "$CHECKER" ) 2>&1 ); rc=$?
check "waiver passes (exit 0)" 0 $rc
if grep -q "WAIVED" <<< "$out"; then ok "waiver prints WAIVED banner"; else bad "waiver prints WAIVED banner"; fi

# 9. Corrupt record -> block.
echo 'not json' > "$(git rev-parse --git-path omakase)/deferred/vv.json"
( OMAKASE_CHECK=vv OMAKASE_GLOB='*.vue' OMAKASE_BASE=master bash "$CHECKER" ) >/dev/null 2>&1
check "corrupt record blocks (exit 1)" 1 $?

# 10. Three-dot range: a file changed only on the BASE since branch-point must
#     NOT trigger the gate (the two-dot over-scope bug the review caught).
d=$(newrepo); cd "$d"
git checkout -q -b feat; echo x > note.txt; git add -A; git commit -q --no-verify -m note
git checkout -q master; echo '<template/>' > base-only.vue; git add -A; git commit -q --no-verify -m baseui
git checkout -q feat
( OMAKASE_CHECK=vv OMAKASE_GLOB='*.vue' OMAKASE_BASE=master bash "$CHECKER" ) >/dev/null 2>&1
check "base-only UI change does NOT trigger (three-dot, exit 0)" 0 $?

# 11. Escape hatch.
d=$(newrepo); cd "$d"
git checkout -q -b feat; echo '<template/>' > app.vue; git add -A; git commit -q --no-verify -m vue
( OMAKASE_CHECK=vv OMAKASE_GLOB='*.vue' OMAKASE_BASE=master OMAKASE_SKIP_VV=1 bash "$CHECKER" ) >/dev/null 2>&1
check "escape hatch OMAKASE_SKIP_VV=1 passes (exit 0)" 0 $?

echo ""
echo "omakase-record.sh"

# 12. Writes conforming JSON keyed to HEAD.
d=$(newrepo); cd "$d"
bash "$RECORDER" --check vv --verdict pass >/dev/null 2>&1
REC="$(git rev-parse --git-path omakase)/deferred/vv.json"
if [[ -f "$REC" ]] && grep -q '"verdict":"pass"' "$REC" && grep -q "\"key\":\"$(git rev-parse HEAD)\"" "$REC"; then
  ok "writes conforming JSON keyed to HEAD"
else bad "writes conforming JSON keyed to HEAD"; fi

# 13. Waiving a FAIL without a reason is rejected.
( bash "$RECORDER" --check vv --verdict pass --original-verdict fail ) >/dev/null 2>&1
check "waive-without-reason rejected (exit 2)" 2 $?

# 14. Bad verdict rejected.
( bash "$RECORDER" --check vv --verdict maybe ) >/dev/null 2>&1
check "bad verdict rejected (exit 2)" 2 $?

echo ""
echo "==== $PASS passed, $FAIL failed ===="
[[ $FAIL -eq 0 ]]
