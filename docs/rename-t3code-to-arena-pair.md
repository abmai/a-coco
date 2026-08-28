# Plan: Rename T3Code → Arena Pair

**Status:** ✅ **Executed.** **Chosen scope:** *literal* (product name only). **Naming scheme:** *single token*.

> Execution summary:
> - Content sweep applied to **501 files** (~2,841 occurrences of `T3Code`/`t3code`/`T3CODE`/`T3 Code`; **0 remaining**).
> - Path renames applied via `git mv`: `oxlint-plugin-t3code/` → `oxlint-plugin-arenapair/`, `docs/internals/t3-code-connect-auth-flow.html` → `arena-pair-connect-auth-flow.html`, `packaging/aur/t3code-bin/` → `arenapair-bin/`, `packaging/aur/t3code-nightly-bin/` → `arenapair-nightly-bin/`.
> - Lockfile importer key `oxlint-plugin-t3code` → `oxlint-plugin-arenapair` updated (full `pnpm install` was not runnable here — it OOM'd in this sandbox; regenerate with `pnpm install` in a normal environment).
> - Verified: no leftover product-name forms, no dangling `oxlint-plugin-t3code` refs, all modified JSON parses, scope ecosystem (`@t3tools`, `npx t3`, `t3.codes`, `T3Markdown`, `T3Project`) untouched.

This is a **brand rename of the product name only**. It does **not** touch the wider `T3`-prefixed engineering ecosystem (`@t3tools`, `T3Markdown`, `T3Project`, `T3Composer`, `T3Terminal`, the `t3` CLI, domain `t3.codes`, data dir `~/.t3`, etc.) — those are out of scope by choice.

---

## 1. Mapping (the only thing that changes)

| From | To | Used for |
|------|----|----------|
| `T3 Code` | `Arena Pair` | Display string (docs, UI copy, marketing) |
| `T3Code` | `ArenaPair` | CamelCase identifiers/types (`T3CodePublicConfig`, `T3CodeRelay`, `T3CodeDev`, iOS scheme/app name) |
| `t3code` | `arenapair` | Lowercase slug / filenames / package suffix / binary-ish names |
| `T3CODE` | `ARENAPAIR` | SCREAMING_CASE env vars (`T3CODE_PORT` → `ARENAPAIR_PORT`) |

All other identifiers (`T3Markdown*`, `T3Project*`, `@t3tools/*`, `npx t3`, `t3.codes`, `~/.t3`) are **left untouched**.

---

## 2. Scope of the change (measured)

- **Tracked files affected:** **501** (of which 500 are text; `pnpm-lock.yaml` is the 501st and is regenerated, not hand-edited)
- **Total occurrences of the 4 forms:** **~2,841**

Breakdown (per form — occurrences / files):

| Form | → | Occurrences | Files |
|------|---|-------------|-------|
| `T3Code` | `ArenaPair` | 30 | 16 |
| `t3code` | `arenapair` | 1,402 | 289 |
| `T3CODE` | `ARENAPAIR` | 783 | 105 |
| `T3 Code` | `Arena Pair` | 625 | 218 |

A single mechanical, case-sensitive sweep covers ~99% of the rename. Everything else (path renames, registry/publish, external surfaces) is a small, explicitly labeled add-on.

---

## 3. Steps

### Step 1 — Content sweep (the whole rename)
Run the bundled script. It is **dry-run by default** and prints the numbers above before writing.

```bash
# Confirm nothing will change (re-prints breakdown, writes nothing):
./scripts/rename-t3code-to-arena-pair.sh

# Apply:
./scripts/rename-t3code-to-arena-pair.sh --apply
```

- Operates only on `git`-tracked text files (`git grep -Fl`), so it never touches `node_modules`, build output, or untracked files.
- Uses fixed-string matching (no regex surprises), one `perl` in-place pass, and re-verifies the leftover count drops to **0**.
- Case-sensitive, so `T3Code`/`T3CODE`/`t3code` are handled independently and don't collide.
- `pnpm-lock.yaml` is **excluded by default** (generated file). Use `--all` to sweep it, but the recommended path is Step 2.

Review the diff for sanity:
```bash
git diff --stat
```

### Step 2 — Regenerate the lockfile
Changing package names in source (e.g. `@t3tools/oxlint-plugin-t3code` → `@t3tools/oxlint-plugin-arenapair`) makes the lockfile stale. Regenerate it rather than hand-editing:
```bash
pnpm install
```

### Step 3 — Path renames (optional; opt-in)
A few **on-disk paths** carry the name and are *not* covered by the content sweep. They are opt-in because renaming a directory/package requires coordinated reference updates and external re-publishing:

```bash
./scripts/rename-t3code-to-arena-pair.sh --apply --rename-paths
```

| Path | → | Notes |
|------|---|-------|
| `docs/internals/t3-code-connect-auth-flow.html` | `docs/internals/arena-pair-connect-auth-flow.html` | Hyphenated slug maps to `arena-pair` |
| `oxlint-plugin-t3code/` | `oxlint-plugin-arenapair/` | Local package; update `pnpm-workspace.yaml`/refs, reinstall |
| `packaging/aur/t3code-bin/` | `packaging/aur/arenapair-bin/` | AUR package; republish on AUR |
| `packaging/aur/t3code-nightly-bin/` | `packaging/aur/arenapair-nightly-bin/` | AUR package; republish on AUR |

> After any path rename, grep for stale references and re-run `pnpm install`.

### Step 4 — Verification
```bash
# 1. No leftover product-name forms:
git grep -iE "t3.?code" -- $(git ls-files) || echo "clean"

# 2. Project still type-checks / tests. (This repo uses pnpm; run the same
#    command your CI uses, e.g.:)
pnpm -r typecheck   # or the project's check
pnpm test           # or `pnpm -r test`
```
Expect a **small number of test failures that hardcoded the old strings** (e.g. `git.test.ts`, `PullRequestService.test.ts`, `openPullRequestLink.test.ts`, `Manager.test.ts`). Those assertions intentionally assert on fixture URLs/names — update them to the new strings (they're part of the same sweep, but a few `expect(...)` fixtures reference `T3Tools/T3Code` GitHub URLs which are *external* — see Step 5).

### Step 5 — External surfaces (not editable by code; requires publishing/renaming)
These are *outside* the repo and cannot be changed by a code edit. They must be done manually (or by the project maintainers):

- **GitHub repo** `PingDotGG/T3Code` / `T3Tools/T3Code` and any resulting redirects.
- **npm package** names under `@t3tools` scope (e.g. `@t3tools/oxlint-plugin-t3code`) — publish under the new name and update `.npmrc`/references.
- **AUR** packages `t3code-bin`, `t3code-nightly-bin`.
- **Domain** `t3.codes`, `app.t3.codes`, `relay.t3.codes` (DNS/TLS + Clerk/OTLP config encoded in `T3CODE_*` values).
- **Store listings**: iOS/Android bundle id `com.t3tools.t3code`, app title "T3 Code", desktop app identity (`T3CodeDev` scheme, `T3Code.app`).
- **Secrets/`.env`**: rename the `T3CODE_*` keys to `ARENAPAIR_*` in deployed environments and `.env.example`; the values referencing `t3.codes` stays until the domain moves.

---

## 4. Risk & rollback

- **Working tree safety:** the script only edits tracked files; run it on your normal branch and review `git diff`. No data is destroyed (there is no user data in scope).
- **Rollback:** the change is a pure textual substitution — revert with `git checkout -- .` (or `git restore .`) if anything is off. Because the whole edit is one deterministic pass, it's trivially reversible before you commit.
- **Order of substitutions:** verified safe — the four forms are case-distinct and none is a substring of another's replacement, so no cascade/double-replace.

---

## 5. One-command summary

```bash
./scripts/rename-t3code-to-arena-pair.sh --apply   # the rename
pnpm install                                        # regenerate lockfile
git diff --stat                                     # review
<project test/typecheck command>                    # verify
# optional: ./scripts/rename-t3code-to-arena-pair.sh --apply --rename-paths
```
