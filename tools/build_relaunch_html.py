#!/usr/bin/env python3
"""Generate interactive HTML review from RELAUNCH_PLAN.md.
Output: D:/server/RELAUNCH_PLAN.html
"""
import subprocess, re, os, sys

PANDOC  = os.path.join(os.environ.get('LOCALAPPDATA',''), 'Pandoc', 'pandoc.exe')
MD_IN   = 'D:/server/RELAUNCH_PLAN.md'
HTML_OUT = 'D:/server/RELAUNCH_PLAN.html'
ADMINS  = ['Bro', 'Ririn', 'Kirin', 'Sivart']

# Firestore REST endpoint — no API key needed in test mode (open for 30 days from 2026-06-24)
FIRESTORE = 'https://firestore.googleapis.com/v1/projects/legendary-relaunch/databases/(default)/documents/votes'

# ── Admin cell HTML ────────────────────────────────────────────────────────────

def admin_cell(admin_name, cell_id):
    return (
        f'<td class="admin-cell" data-admin="{admin_name}" data-cell-id="{cell_id}">'
        f'<select class="vote" data-cell-id="{cell_id}" onchange="onVote(this)">'
        f'<option value="">—</option>'
        f'<option value="agree">✓ Agree</option>'
        f'<option value="disagree">✗ Disagree</option>'
        f'</select>'
        f'<textarea class="notes" data-cell-id="{cell_id}" '
        f'placeholder="Reason for disagreeing…" oninput="onNote(this)"></textarea>'
        f'</td>'
    )

# ── Table transformer ──────────────────────────────────────────────────────────

def process_table(tbl, tidx):
    thead_m = re.search(r'<thead>(.*?)</thead>', tbl, re.DOTALL)
    if not thead_m:
        return tbl

    th_cells = re.findall(r'<th[^>]*>(.*?)</th>', thead_m.group(1), re.DOTALL)
    th_texts  = [re.sub(r'<[^>]+>', '', t).strip() for t in th_cells]
    admin_map = {i: name for i, name in enumerate(th_texts) if name in ADMINS}
    if not admin_map:
        return tbl

    th_idx = [0]
    def style_th(m):
        i = th_idx[0]; th_idx[0] += 1
        inner = m.group(1)
        if i in admin_map:
            return f'<th class="admin-th">{inner}</th>'
        return m.group(0)
    new_thead_inner = re.sub(r'<th[^>]*>(.*?)</th>', style_th,
                             thead_m.group(1), flags=re.DOTALL)
    tbl = tbl.replace(thead_m.group(0), f'<thead>{new_thead_inner}</thead>', 1)

    tbody_m = re.search(r'(<tbody>)(.*?)(</tbody>)', tbl, re.DOTALL)
    if not tbody_m:
        return tbl

    row_idx = [0]
    def process_row(rm):
        ridx = row_idx[0]; row_idx[0] += 1
        row_html = rm.group(0)
        tds = list(re.finditer(r'<td[^>]*>.*?</td>', row_html, re.DOTALL))
        for ci, td_m in reversed(list(enumerate(tds))):
            if ci in admin_map:
                cid  = f't{tidx}r{ridx}c{ci}'
                row_html = (row_html[:td_m.start()]
                            + admin_cell(admin_map[ci], cid)
                            + row_html[td_m.end():])
        return row_html

    new_tbody = re.sub(r'<tr[^>]*>.*?</tr>', process_row,
                       tbody_m.group(2), flags=re.DOTALL)
    tbl = tbl.replace(tbody_m.group(0),
                      tbody_m.group(1) + new_tbody + tbody_m.group(3), 1)
    return tbl

# ── Heading IDs for sidebar ────────────────────────────────────────────────────

def add_heading_ids(html):
    seen = {}
    def replace(m):
        lvl, inner = m.group(1), m.group(2)
        text  = re.sub(r'<[^>]+>', '', inner).strip()
        slug  = re.sub(r'[^a-z0-9]+', '-', text.lower()).strip('-')[:60]
        n     = seen.get(slug, 0); seen[slug] = n + 1
        final = slug if n == 0 else f'{slug}-{n}'
        return f'<h{lvl} id="{final}">{inner}</h{lvl}>'
    return re.sub(r'<h([1-6])>(.*?)</h\1>', replace, html, flags=re.DOTALL)

def build_nav(html):
    items = []
    for m in re.finditer(r'<h([23]) id="([^"]+)">(.*?)</h\1>', html, re.DOTALL):
        lvl, slug, txt = m.group(1), m.group(2), m.group(3)
        clean = re.sub(r'<[^>]+>', '', txt).strip()[:55]
        items.append(f'<a href="#{slug}" class="nav-l{lvl}">{clean}</a>')
    return '\n'.join(items)

# ── CSS ────────────────────────────────────────────────────────────────────────

CSS = """
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --bg:#0b0b18;--bg2:#12122a;--bg3:#1a1a3a;
  --border:#2a2a50;--text:#d4c5a9;--muted:#6868a0;
  --gold:#c9a84c;--gold2:#a07830;--orange:#e07840;
  --green:#4caf50;--green-bg:#0a1f0a;
  --red:#e05050;  --red-bg:#200a0a;
  --side:230px;
}
html{scroll-behavior:smooth}
body{font-family:'Segoe UI',system-ui,sans-serif;font-size:14px;
  line-height:1.65;background:var(--bg);color:var(--text);
  display:flex;flex-direction:column;min-height:100vh}

/* Admin identity bar */
#admin-bar{
  position:sticky;top:0;z-index:200;
  background:#07070f;border-bottom:2px solid var(--gold2);
  padding:10px 20px;display:flex;align-items:center;
  gap:10px;flex-shrink:0;
}
#admin-bar span.label{font-size:13px;color:var(--muted);font-weight:600;
  letter-spacing:.5px;white-space:nowrap}
.admin-id-btn{
  background:var(--bg3);color:var(--text);
  border:1px solid var(--border);border-radius:5px;
  padding:5px 16px;cursor:pointer;font-size:13px;font-weight:700;
  transition:all .15s;letter-spacing:.3px}
.admin-id-btn:hover{border-color:var(--gold2);color:var(--gold)}
.admin-id-btn.active{background:var(--gold2);color:#fff;border-color:var(--gold)}
#admin-status{font-size:12px;font-style:italic;color:var(--orange);margin-left:8px}
#poll-status{margin-left:auto;font-size:11px;color:var(--muted);white-space:nowrap}
#poll-dot{display:inline-block;width:7px;height:7px;border-radius:50%;
  background:var(--muted);margin-right:5px;vertical-align:middle}
#poll-dot.live{background:var(--green);animation:pulse 2s infinite}
@keyframes pulse{0%,100%{opacity:1}50%{opacity:.4}}

/* Layout */
#layout{display:flex;flex:1}

/* Sidebar */
#sidebar{width:var(--side);min-height:100%;background:#07070f;
  border-right:1px solid var(--border);
  overflow-y:auto;padding:0 0 40px;display:flex;flex-direction:column;gap:1px;
  position:sticky;top:44px;height:calc(100vh - 44px)}
.logo{font-size:13px;font-weight:700;color:var(--gold);
  padding:18px 16px 14px;letter-spacing:.5px;
  border-bottom:1px solid var(--border);flex-shrink:0}
.logo span{display:block;font-size:10px;font-weight:400;color:var(--muted);
  letter-spacing:1px;text-transform:uppercase;margin-top:2px}
.nav-section{font-size:10px;font-weight:700;letter-spacing:1.5px;color:var(--muted);
  padding:14px 16px 4px;text-transform:uppercase;flex-shrink:0}
#sidebar a{display:block;padding:3px 16px;color:var(--muted);text-decoration:none;
  font-size:12px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;
  transition:color .12s,background .12s}
#sidebar a.nav-l2{color:var(--text);font-weight:500;padding-top:5px}
#sidebar a.nav-l3{padding-left:28px;font-size:11px}
#sidebar a:hover{color:var(--gold);background:rgba(201,168,76,.07)}
#sidebar hr{border:none;border-top:1px solid var(--border);margin:10px 12px}
.sb-btn{display:block;margin:5px 14px;padding:8px 12px;border:none;border-radius:5px;
  cursor:pointer;font-size:12px;font-weight:600;width:calc(100% - 28px);text-align:left}
.sb-btn.export{background:var(--gold2);color:#fff}
.sb-btn.export:hover{background:var(--gold)}
.sb-btn.clr{background:#200d0d;color:var(--muted);margin-top:4px}
.sb-btn.clr:hover{color:var(--red)}
#vote-counts{font-size:11px;color:var(--muted);padding:10px 16px 0;line-height:2}
#vote-counts b{color:var(--text)}

/* Content */
#content{flex:1;padding:44px 52px 100px;max-width:1160px;width:100%}
.plan-banner{padding-bottom:28px;margin-bottom:36px;border-bottom:1px solid var(--border)}
.plan-banner h1{font-size:30px;color:var(--gold);margin-bottom:4px}
.plan-banner p{color:var(--muted);font-size:15px;margin-bottom:14px}
.legend{display:flex;gap:18px;font-size:12px}
.leg-a{color:var(--green)}.leg-d{color:var(--red)}.leg-p{color:var(--muted)}

/* Typography */
h1{font-size:22px;color:var(--gold);margin:40px 0 10px}
h2{font-size:19px;color:var(--gold);margin:38px 0 10px;
  padding-bottom:7px;border-bottom:1px solid var(--border)}
h3{font-size:15px;color:var(--gold2);margin:24px 0 8px}
h4{font-size:13px;color:var(--orange);margin:16px 0 6px;text-transform:uppercase;letter-spacing:.5px}
p{margin:7px 0}
ul,ol{margin:7px 0 7px 22px}
li{margin:3px 0}
strong{color:#eedd88}
em{color:#9090c0}
a{color:var(--gold)}
hr{border:none;border-top:1px solid var(--border);margin:24px 0}
code{background:var(--bg3);color:#82aaff;padding:1px 5px;border-radius:3px;
  font-family:Consolas,monospace;font-size:12px}
pre{background:var(--bg3);border:1px solid var(--border);border-radius:6px;
  padding:14px;overflow-x:auto;margin:10px 0}
pre code{background:none;padding:0}
blockquote{border-left:3px solid var(--gold2);background:#09091e;
  padding:10px 16px;margin:10px 0;border-radius:0 5px 5px 0;font-size:13px;color:#b8a878}
blockquote strong{color:var(--gold)}
blockquote em{color:var(--muted)}

/* Tables */
table{width:100%;border-collapse:collapse;margin:14px 0;font-size:13px}
th{background:var(--bg3);color:var(--gold);font-weight:600;
  padding:8px 11px;text-align:left;border:1px solid var(--border);white-space:nowrap}
th.admin-th{color:var(--orange);background:#13132a;text-align:center;
  min-width:140px;font-size:12px}
td{padding:7px 11px;border:1px solid var(--border);vertical-align:top}
tr:nth-child(odd)  td{background:var(--bg)}
tr:nth-child(even) td{background:var(--bg2)}
tr:hover td{background:#141424}

/* Admin cells */
td.admin-cell{background:#090916 !important;padding:6px 7px;
  min-width:140px;max-width:160px;text-align:center}
select.vote{width:100%;background:var(--bg3);color:var(--muted);
  border:1px solid var(--border);border-radius:4px;padding:5px 6px;
  font-size:12px;cursor:pointer;outline:none;transition:all .15s}
select.vote:focus{border-color:var(--gold2)}
select.vote.agreed{background:var(--green-bg);border-color:var(--green);
  color:var(--green);font-weight:700}
select.vote.disagreed{background:var(--red-bg);border-color:var(--red);
  color:var(--red);font-weight:700}
select.vote:disabled{opacity:.5;cursor:not-allowed}
textarea.notes{display:none;width:100%;margin-top:5px;background:#130808;
  color:var(--text);border:1px solid #3a1a1a;border-radius:4px;
  padding:5px 7px;font-size:11px;font-family:'Segoe UI',sans-serif;
  resize:vertical;min-height:54px;outline:none;transition:border .15s}
textarea.notes:focus{border-color:var(--red)}
textarea.notes.open{display:block}
textarea.notes[readonly]{opacity:.6;cursor:default}

/* Who-voted badge on cells not owned by current admin */
td.admin-cell.other-admin{opacity:.75}

/* Export modal */
#modal{display:none;position:fixed;inset:0;background:rgba(0,0,0,.82);
  align-items:center;justify-content:center;z-index:999}
#modal.show{display:flex}
.modal-box{background:var(--bg2);border:1px solid var(--border);border-radius:8px;
  padding:24px;width:680px;max-width:92vw;max-height:82vh;
  display:flex;flex-direction:column;gap:12px}
.modal-box h3{color:var(--gold);font-size:16px}
.modal-box textarea{flex:1;background:var(--bg);color:var(--text);
  border:1px solid var(--border);border-radius:4px;padding:12px;
  font-family:Consolas,monospace;font-size:12px;resize:none;min-height:280px;outline:none}
.modal-actions{display:flex;gap:8px}
.modal-actions button{padding:8px 18px;border:none;border-radius:4px;
  cursor:pointer;font-size:13px;font-weight:600}
.btn-copy{background:var(--gold2);color:#fff}
.btn-copy:hover{background:var(--gold)}
.btn-close{background:var(--bg3);color:var(--text)}
.btn-close:hover{background:var(--border)}
"""

# ── JavaScript ─────────────────────────────────────────────────────────────────

JS = r"""
/* ── Config ──────────────────────────────────────────────────────────────── */
const FIRESTORE = 'https://firestore.googleapis.com/v1/projects/legendary-relaunch/databases/(default)/documents/votes';
const POLL_MS   = 15000;   // refresh from Firestore every 15s
const ADMINS    = ['Bro','Ririn','Kirin','Sivart'];

let myAdmin   = '';          // who this browser window is
let allVotes  = {};          // { cellId: { admin, vote, notes } }
let pollTimer = null;
let lastPoll  = null;
let pollTick  = null;

/* ── Identity bar ────────────────────────────────────────────────────────── */
function setAdmin(name) {
  myAdmin = name;
  sessionStorage.setItem('lgnd-admin', name);
  document.querySelectorAll('.admin-id-btn').forEach(b =>
    b.classList.toggle('active', b.dataset.admin === name)
  );
  document.getElementById('admin-status').textContent = 'Voting as: ' + name;
  renderAllVotes();
  startPoll();
}

/* ── Firestore REST helpers ──────────────────────────────────────────────── */
function toFS(obj) {
  const fields = {};
  for (const [k, v] of Object.entries(obj)) fields[k] = {stringValue: String(v)};
  return {fields};
}
function fromFS(doc) {
  const out = {};
  for (const [k, v] of Object.entries(doc.fields || {}))
    out[k] = v.stringValue !== undefined ? v.stringValue : '';
  return out;
}

async function fetchAllVotes() {
  try {
    const r = await fetch(FIRESTORE + '?pageSize=2000');
    if (!r.ok) { console.warn('Firestore fetch', r.status); return; }
    const data = await r.json();
    allVotes = {};
    (data.documents || []).forEach(doc => {
      const id = decodeURIComponent(doc.name.split('/').pop());
      allVotes[id] = fromFS(doc);
    });
    renderAllVotes();
    refreshCounts();
    lastPoll = Date.now();
    const dot = document.getElementById('poll-dot');
    if (dot) { dot.classList.add('live'); setTimeout(() => dot.classList.remove('live'), 800); }
  } catch(e) { console.error('Firestore error:', e); }
}

async function saveVote(cellId, vote, notes) {
  if (!myAdmin) return;
  const docId = encodeURIComponent(cellId);
  const body  = toFS({ admin: myAdmin, cellId, vote: vote||'', notes: notes||'' });
  try {
    await fetch(FIRESTORE + '/' + docId, {
      method: 'PATCH',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify(body)
    });
    allVotes[cellId] = { admin: myAdmin, cellId, vote: vote||'', notes: notes||'' };
    refreshCounts();
  } catch(e) { console.error('Firestore save error:', e); }
}

async function deleteVote(cellId) {
  try {
    await fetch(FIRESTORE + '/' + encodeURIComponent(cellId), { method: 'DELETE' });
    delete allVotes[cellId];
    refreshCounts();
  } catch(e) {}
}

/* ── Rendering ───────────────────────────────────────────────────────────── */
function renderAllVotes() {
  document.querySelectorAll('td.admin-cell').forEach(td => {
    const cellId = td.dataset.cellId;
    const admin  = td.dataset.admin;
    const v      = allVotes[cellId];
    const sel    = td.querySelector('select.vote');
    const ta     = td.querySelector('textarea.notes');
    if (!sel || !ta) return;

    const vote  = v ? v.vote  : '';
    const notes = v ? v.notes : '';

    sel.value     = vote;
    sel.className = 'vote' + (vote==='agree' ? ' agreed' : vote==='disagree' ? ' disagreed' : '');

    if (vote === 'disagree') {
      ta.value = notes;
      ta.classList.add('open');
    } else {
      ta.value = '';
      ta.classList.remove('open');
    }

    const isMyColumn = myAdmin && admin === myAdmin;
    sel.disabled = !isMyColumn;
    ta.readOnly  = !isMyColumn;
    td.classList.toggle('other-admin', !!myAdmin && !isMyColumn);
  });
}

/* ── Event handlers ──────────────────────────────────────────────────────── */
function onVote(sel) {
  if (!myAdmin) { alert('Please click your name at the top of the page first.'); sel.value=''; return; }
  const td    = sel.closest('td');
  const admin = td.dataset.admin;
  if (admin !== myAdmin) return;
  const id   = sel.dataset.cellId;
  const ta   = sel.nextElementSibling;
  const vote = sel.value;
  sel.className = 'vote' + (vote==='agree' ? ' agreed' : vote==='disagree' ? ' disagreed' : '');
  ta.classList.toggle('open', vote === 'disagree');
  if (vote !== 'disagree') ta.value = '';
  saveVote(id, vote, vote === 'disagree' ? ta.value : '');
}

function onNote(ta) {
  if (!myAdmin) return;
  const td    = ta.closest('td');
  const admin = td.dataset.admin;
  if (admin !== myAdmin) return;
  const sel = ta.previousElementSibling;
  saveVote(ta.dataset.cellId, sel.value, ta.value);
}

/* ── Poll control ────────────────────────────────────────────────────────── */
function startPoll() {
  if (pollTimer) clearInterval(pollTimer);
  if (pollTick)  clearInterval(pollTick);
  fetchAllVotes();
  pollTimer = setInterval(fetchAllVotes, POLL_MS);
  pollTick  = setInterval(updatePollLabel, 1000);
}

function updatePollLabel() {
  const el = document.getElementById('poll-status');
  if (!el || !lastPoll) return;
  const sec = Math.round((Date.now() - lastPoll) / 1000);
  el.textContent = 'Live · refreshed ' + sec + 's ago';
}

/* ── Counts ──────────────────────────────────────────────────────────────── */
function refreshCounts() {
  const total  = document.querySelectorAll('select.vote').length;
  const vals   = Object.values(allVotes);
  const agrees = vals.filter(v => v.vote==='agree').length;
  const dis    = vals.filter(v => v.vote==='disagree').length;
  const pend   = total - Math.min(agrees + dis, total);
  document.getElementById('vote-counts').innerHTML =
    '<b>' + total + '</b> total cells<br>' +
    '<span style="color:var(--green)">✓ Agree: <b>' + agrees + '</b></span><br>' +
    '<span style="color:var(--red)">✗ Disagree: <b>' + dis + '</b></span><br>' +
    '<span style="color:var(--muted)">— Pending: <b>' + pend + '</b></span>';
}

/* ── Export ──────────────────────────────────────────────────────────────── */
function rowContext(cellId) {
  const td = document.querySelector('td[data-cell-id="' + cellId + '"]');
  if (!td) return cellId;
  const row   = td.closest('tr');
  if (!row) return cellId;
  const first = row.querySelector('td:not(.admin-cell)');
  return first ? first.innerText.replace(/\s+/g,' ').trim().slice(0,70) : cellId;
}

function exportFeedback() {
  const lines = ['LEGENDARY FFXI — ADMIN REVIEW EXPORT', '='.repeat(50), ''];
  const byAdmin = {};
  ADMINS.forEach(a => byAdmin[a] = {agrees:[], disagrees:[]});

  Object.values(allVotes).forEach(v => {
    if (!v.vote || !v.admin) return;
    if (!byAdmin[v.admin]) byAdmin[v.admin] = {agrees:[], disagrees:[]};
    const ctx = rowContext(v.cellId);
    if (v.vote === 'agree')    byAdmin[v.admin].agrees.push(ctx);
    if (v.vote === 'disagree') byAdmin[v.admin].disagrees.push({ctx, notes: v.notes||''});
  });

  const totalCells = document.querySelectorAll('select.vote').length;
  const voted = Object.values(allVotes).filter(v => v.vote).length;
  lines.push('SUMMARY');
  lines.push('  Voted on: ' + voted + ' / ' + totalCells + ' cells');
  lines.push('  Agrees:   ' + Object.values(allVotes).filter(v=>v.vote==='agree').length);
  lines.push('  Disagrees:' + Object.values(allVotes).filter(v=>v.vote==='disagree').length);
  lines.push('');

  ADMINS.forEach(admin => {
    const data = byAdmin[admin];
    if (!data || (data.agrees.length + data.disagrees.length === 0)) return;
    lines.push('-- ' + admin.toUpperCase() + ' ' + '-'.repeat(40));
    if (data.disagrees.length > 0) {
      lines.push('  DISAGREES:');
      data.disagrees.forEach(({ctx, notes}) => {
        lines.push('    * ' + ctx);
        if (notes) lines.push('      -> ' + notes);
      });
    }
    if (data.agrees.length > 0) {
      lines.push('  AGREES (' + data.agrees.length + '):');
      data.agrees.forEach(ctx => lines.push('    + ' + ctx));
    }
    lines.push('');
  });

  document.getElementById('export-text').value = lines.join('\n');
  document.getElementById('modal').classList.add('show');
}

function copyExport() {
  const ta = document.getElementById('export-text');
  ta.select();
  document.execCommand('copy');
  const btn = document.querySelector('.btn-copy');
  btn.textContent = '✓ Copied!';
  setTimeout(() => { btn.textContent = 'Copy to Clipboard'; }, 2000);
}

function closeModal() { document.getElementById('modal').classList.remove('show'); }

function clearMyVotes() {
  if (!myAdmin) { alert('Select your name first.'); return; }
  if (!confirm('Clear ALL your votes? Other admins are not affected.')) return;
  const mine = Object.keys(allVotes).filter(id => allVotes[id].admin === myAdmin);
  mine.forEach(id => deleteVote(id));
  setTimeout(() => { fetchAllVotes(); }, 500);
}

/* ── Init ────────────────────────────────────────────────────────────────── */
window.addEventListener('load', () => {
  const saved = sessionStorage.getItem('lgnd-admin');
  if (saved && (ADMINS.includes(saved) || saved === 'Richard')) {
    setAdmin(saved);
  } else {
    // Load existing votes as read-only so everyone can see status on load
    fetchAllVotes();
    startPoll();
  }
});
"""

# ── Page template ──────────────────────────────────────────────────────────────

def build_page(body, nav):
    admin_buttons = '\n'.join(
        f'    <button class="admin-id-btn" data-admin="{a}" onclick="setAdmin(\'{a}\')">{a}</button>'
        for a in ADMINS + ['Richard']
    )
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Legendary FFXI — Relaunch Plan (Admin Review)</title>
<style>{CSS}</style>
</head>
<body>

<!-- Identity bar: admins click their name once, stored in sessionStorage -->
<div id="admin-bar">
  <span class="label">I am:</span>
{admin_buttons}
  <span id="admin-status">— click your name to vote</span>
  <span id="poll-status"><span id="poll-dot"></span>connecting…</span>
</div>

<div id="layout">

<nav id="sidebar">
  <div class="logo">&#9876; Legendary FFXI<span>Admin Review · Live</span></div>
  <div class="nav-section">Sections</div>
  {nav}
  <hr>
  <div class="nav-section">Tools</div>
  <button class="sb-btn export" onclick="exportFeedback()">&#128203; Export All Feedback</button>
  <button class="sb-btn clr"    onclick="clearMyVotes()">&#128465; Clear My Votes</button>
  <div id="vote-counts"></div>
</nav>

<main id="content">
  <div class="plan-banner">
    <h1>&#9876; Legendary FFXI &mdash; Relaunch Plan</h1>
    <p>Admin review document &middot; Click your name above, then use the dropdowns in each row to vote.</p>
    <div class="legend">
      <span class="leg-a">&#10003; Agree &mdash; approved as written</span>
      <span class="leg-d">&#10007; Disagree &mdash; leave a note explaining why</span>
      <span class="leg-p">&mdash; Pending &mdash; not yet reviewed</span>
    </div>
  </div>
  {body}
</main>

</div><!-- #layout -->

<div id="modal">
  <div class="modal-box">
    <h3>&#128203; Feedback Export &mdash; All Admins</h3>
    <textarea id="export-text" readonly></textarea>
    <div class="modal-actions">
      <button class="btn-copy" onclick="copyExport()">Copy to Clipboard</button>
      <button class="btn-close" onclick="closeModal()">Close</button>
    </div>
  </div>
</div>

<script>{JS}</script>
</body>
</html>"""

# ── Main ───────────────────────────────────────────────────────────────────────

def main():
    if not os.path.exists(PANDOC):
        sys.exit(f'Pandoc not found at {PANDOC}')

    print('Converting markdown...')
    r = subprocess.run([PANDOC, MD_IN, '--to=html5'],
                       capture_output=True, text=True, encoding='utf-8')
    if r.returncode != 0:
        sys.exit(f'Pandoc error:\n{r.stderr}')

    html = r.stdout

    print('Processing tables...')
    tidx = [0]
    def do_table(m):
        i = tidx[0]; tidx[0] += 1
        return process_table(m.group(0), i)
    html = re.sub(r'<table>.*?</table>', do_table, html, flags=re.DOTALL)

    print('Adding heading IDs...')
    html = add_heading_ids(html)
    nav  = build_nav(html)

    print('Writing HTML...')
    page = build_page(html, nav)
    with open(HTML_OUT, 'w', encoding='utf-8') as f:
        f.write(page)

    size_kb = os.path.getsize(HTML_OUT) // 1024
    print(f'Done -> {HTML_OUT} ({size_kb} KB)')

if __name__ == '__main__':
    main()
