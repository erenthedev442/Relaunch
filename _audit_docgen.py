import os, re, io
DOCS = r"C:\relaunch-docs\docs"
GENS = r"C:\relaunch-docs\tools\docgen\generators"
GENROOT = r"C:\relaunch-docs\tools\docgen"

# 1) all markdown pages (relative, forward-slash)
pages = []
for root, _, files in os.walk(DOCS):
    for f in files:
        if f.endswith(".md"):
            rel = os.path.relpath(os.path.join(root, f), DOCS).replace("\\", "/")
            pages.append(rel)
pages = sorted(pages)

# 2) which pages have DOCGEN markers (a generator fills them)
has_marker = {}
for rel in pages:
    t = io.open(os.path.join(DOCS, rel.replace("/", os.sep)), encoding="utf-8", errors="replace").read()
    has_marker[rel] = "DOCGEN:BEGIN" in t

# 3) which page paths appear in ANY generator source (a generator writes/owns them)
gensrc = ""
for root, _, files in os.walk(GENROOT):
    for f in files:
        if f.endswith(".py"):
            gensrc += io.open(os.path.join(root, f), encoding="utf-8", errors="replace").read() + "\n"
# every "<...>.md" literal referenced anywhere in generator code
referenced = set(m.group(1) for m in re.finditer(r'["\']([\w./-]+\.md)["\']', gensrc))
# normalize (strip leading docs/ if present)
referenced = {r[5:] if r.startswith("docs/") else r for r in referenced}

def backed(rel):
    if has_marker[rel]:
        return "marker"
    # exact ref or basename ref
    if rel in referenced:
        return "full-page"
    base = rel.split("/")[-1]
    if any(r.split("/")[-1] == base for r in referenced):
        return "full-page(base)"
    return None

untracked = []
counts = {"marker": 0, "full-page": 0, "full-page(base)": 0}
for rel in pages:
    b = backed(rel)
    if b:
        counts[b] += 1
    else:
        untracked.append(rel)

print(f"TOTAL pages: {len(pages)}")
print(f"  marker-backed: {counts['marker']}")
print(f"  full-page generator: {counts['full-page'] + counts['full-page(base)']}")
print(f"  UNTRACKED (no marker, no generator writes it): {len(untracked)}")
for u in untracked:
    print("   -", u)
