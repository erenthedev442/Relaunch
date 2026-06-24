#!/usr/bin/env python3
"""Generate interactive HTML review from RELAUNCH_PLAN.md.
Output: D:/server/RELAUNCH_PLAN.html
"""
import subprocess, re, os, sys

PANDOC  = os.path.join(os.environ.get('LOCALAPPDATA',''), 'Pandoc', 'pandoc.exe')
MD_IN   = 'D:/server/RELAUNCH_PLAN.md'
HTML_OUT = 'D:/server/RELAUNCH_PLAN.html'
ADMINS  = ['Bro', 'Ririn', 'Kirin', 'Sivart']

FIRESTORE      = 'https://firestore.googleapis.com/v1/projects/legendary-relaunch/databases/(default)/documents/votes'
FIRESTORE_CMT  = 'https://firestore.googleapis.com/v1/projects/legendary-relaunch/databases/(default)/documents/comments'

# ── Admin cell HTML (inside table rows) ───────────────────────────────────────

def admin_cell(admin_name, cell_id):
    return (
        f'<td class="admin-cell" data-admin="{admin_name}" data-cell-id="{cell_id}">'
        f'<select class="vote" data-cell-id="{cell_id}" onchange="onVote(this)">'
        f'<option value="">—</option>'
        f'<option value="agree">✓ Agree</option>'
        f'<option value="disagree">✗ Disagree</option>'
        f'</select>'
        f'<textarea class="notes" data-cell-id="{cell_id}" '
        f'placeholder="Reason…" oninput="onNote(this)"></textarea>'
        f'</td>'
    )

# ── Section commentary block (added after every h2) ───────────────────────────

def section_feedback(section_id):
    rows = ''.join(
        f'<div class="sfb-row">'
        f'<span class="sfb-name">{a}</span>'
        f'<textarea class="sfb-ta" data-section="{section_id}" data-admin="{a}"'
        f' placeholder="Notes on this section…" oninput="onCmt(this)"></textarea>'
        f'</div>'
        for a in ADMINS
    )
    return (
        f'<div class="sec-fb" data-section="{section_id}">'
        f'<button class="sfb-toggle" onclick="toggleSFB(this)">'
        f'&#9998; Admin Notes'
        f'<span class="sfb-ct"></span>'
        f'</button>'
        f'<div class="sfb-body" hidden>{rows}</div>'
        f'</div>'
    )

# ── Table transformer ──────────────────────────────────────────────────────────

def process_table(tbl, tidx):
    # Always wrap in scrollable div
    thead_m = re.search(r'<thead>(.*?)</thead>', tbl, re.DOTALL)
    if not thead_m:
        return f'<div class="tbl-wrap">{tbl}</div>'

    th_cells = re.findall(r'<th[^>]*>(.*?)</th>', thead_m.group(1), re.DOTALL)
    th_texts  = [re.sub(r'<[^>]+>', '', t).strip() for t in th_cells]
    admin_map = {i: name for i, name in enumerate(th_texts) if name in ADMINS}

    if not admin_map:
        return f'<div class="tbl-wrap">{tbl}</div>'

    # Mark admin <th> cells
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

    # Transform <td> cells in tbody
    tbody_m = re.search(r'(<tbody>)(.*?)(</tbody>)', tbl, re.DOTALL)
    if not tbody_m:
        return f'<div class="tbl-wrap">{tbl}</div>'

    row_idx = [0]
    def process_row(rm):
        ridx = row_idx[0]; row_idx[0] += 1
        row_html = rm.group(0)
        tds = list(re.finditer(r'<td[^>]*>.*?</td>', row_html, re.DOTALL))
        # Replace admin cells that pandoc kept
        for ci, td_m in reversed(list(enumerate(tds))):
            if ci in admin_map:
                cid  = f't{tidx}r{ridx}c{ci}'
                row_html = (row_html[:td_m.start()]
                            + admin_cell(admin_map[ci], cid)
                            + row_html[td_m.end():])
        # Append admin cells pandoc dropped (trailing empty <td>s are omitted by pandoc)
        for ci in sorted(admin_map.keys()):
            if ci >= len(tds):
                cid = f't{tidx}r{ridx}c{ci}'
                row_html = row_html.replace('</tr>', admin_cell(admin_map[ci], cid) + '</tr>', 1)
        return row_html

    new_tbody = re.sub(r'<tr[^>]*>.*?</tr>', process_row,
                       tbody_m.group(2), flags=re.DOTALL)
    tbl = tbl.replace(tbody_m.group(0),
                      tbody_m.group(1) + new_tbody + tbody_m.group(3), 1)
    return f'<div class="tbl-wrap">{tbl}</div>'

# ── Heading IDs + section feedback injection ───────────────────────────────────

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

def inject_section_feedback(html):
    """Insert a per-admin commentary block after every h2 heading."""
    def replace_h2(m):
        slug = re.search(r'id="([^"]+)"', m.group(0))
        if not slug:
            return m.group(0)
        return m.group(0) + '\n' + section_feedback(slug.group(1))
    return re.sub(r'<h2[^>]*id="[^"]*"[^>]*>.*?</h2>', replace_h2, html, flags=re.DOTALL)

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
  padding:9px 18px;display:flex;align-items:center;
  gap:8px;flex-shrink:0;
}
#admin-bar span.label{font-size:12px;color:var(--muted);font-weight:600;
  letter-spacing:.5px;white-space:nowrap}
.admin-id-btn{
  background:var(--bg3);color:var(--text);
  border:1px solid var(--border);border-radius:5px;
  padding:4px 14px;cursor:pointer;font-size:13px;font-weight:700;
  transition:all .15s;letter-spacing:.3px}
.admin-id-btn:hover{border-color:var(--gold2);color:var(--gold)}
.admin-id-btn.active{background:var(--gold2);color:#fff;border-color:var(--gold)}
#admin-status{font-size:12px;font-style:italic;color:var(--orange);margin-left:6px}
#poll-status{margin-left:auto;font-size:11px;color:var(--muted);white-space:nowrap}
#poll-dot{display:inline-block;width:7px;height:7px;border-radius:50%;
  background:var(--muted);margin-right:5px;vertical-align:middle}
#poll-dot.live{background:var(--green);animation:pulse 2s infinite}
@keyframes pulse{0%,100%{opacity:1}50%{opacity:.4}}

/* Layout */
#layout{display:flex;flex:1;overflow:hidden}

/* Sidebar */
#sidebar{width:var(--side);min-height:100%;background:#07070f;
  border-right:1px solid var(--border);flex-shrink:0;
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
#content{flex:1;min-width:0;padding:36px 48px 100px;overflow-x:hidden}
.plan-banner{padding-bottom:24px;margin-bottom:32px;border-bottom:1px solid var(--border)}
.plan-banner h1{font-size:28px;color:var(--gold);margin-bottom:4px}
.plan-banner p{color:var(--muted);font-size:14px;margin-bottom:12px}
.legend{display:flex;gap:18px;font-size:12px;flex-wrap:wrap}
.leg-a{color:var(--green)}.leg-d{color:var(--red)}.leg-p{color:var(--muted)}

/* Typography */
h1{font-size:22px;color:var(--gold);margin:40px 0 10px}
h2{font-size:19px;color:var(--gold);margin:38px 0 0;
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

/* Section feedback (per-h2 commentary) */
.sec-fb{margin:10px 0 20px;border:1px solid var(--border);border-radius:6px;
  background:var(--bg2);overflow:hidden}
.sfb-toggle{width:100%;background:none;border:none;color:var(--muted);
  padding:9px 14px;text-align:left;cursor:pointer;font-size:12px;font-weight:600;
  display:flex;align-items:center;gap:8px;letter-spacing:.3px;transition:color .12s}
.sfb-toggle:hover{color:var(--gold)}
.sfb-toggle.has-notes{color:var(--orange)}
.sfb-ct{margin-left:8px;font-weight:400;font-style:italic}
.sfb-arrow{margin-left:auto;font-size:10px;transition:transform .2s}
.sfb-toggle.open .sfb-arrow{transform:rotate(90deg)}
.sfb-body{padding:10px 12px 12px;display:flex;flex-direction:column;gap:8px;
  border-top:1px solid var(--border)}
.sfb-row{display:flex;align-items:flex-start;gap:10px}
.sfb-name{font-size:12px;font-weight:700;color:var(--orange);min-width:46px;
  padding-top:7px;flex-shrink:0}
.sfb-ta{flex:1;background:var(--bg);color:var(--text);
  border:1px solid var(--border);border-radius:4px;
  padding:6px 9px;font-size:12px;font-family:'Segoe UI',sans-serif;
  resize:vertical;min-height:44px;outline:none;line-height:1.5;transition:border .15s}
.sfb-ta:focus{border-color:var(--gold2)}
.sfb-ta[readonly]{opacity:.55;cursor:default;background:var(--bg)}
.sfb-ta.has-text{border-color:#3a3a60}

/* Tables */
.tbl-wrap{overflow-x:auto;margin:14px 0;border-radius:6px;
  border:1px solid var(--border)}
.tbl-wrap table{width:100%;border-collapse:collapse;font-size:13px;margin:0;
  min-width:500px}
th{background:var(--bg3);color:var(--gold);font-weight:600;
  padding:8px 12px;text-align:left;border:1px solid var(--border);
  white-space:nowrap;font-size:13px}
th.admin-th{color:var(--orange);background:#13132a;text-align:center;
  width:90px;min-width:90px;max-width:110px;font-size:11px}
td{padding:8px 12px;border:1px solid var(--border);vertical-align:top;
  word-break:break-word}
tr:nth-child(odd)  td{background:var(--bg)}
tr:nth-child(even) td{background:var(--bg2)}
tr:hover td{background:#141424}

/* Admin vote cells */
td.admin-cell{background:#090916 !important;padding:5px 6px;
  width:90px;min-width:90px;max-width:110px;text-align:center}
select.vote{width:100%;background:var(--bg3);color:var(--muted);
  border:1px solid var(--border);border-radius:4px;padding:4px 4px;
  font-size:11px;cursor:pointer;outline:none;transition:all .15s}
select.vote:focus{border-color:var(--gold2)}
select.vote.agreed{background:var(--green-bg);border-color:var(--green);
  color:var(--green);font-weight:700}
select.vote.disagreed{background:var(--red-bg);border-color:var(--red);
  color:var(--red);font-weight:700}
select.vote:disabled{opacity:.45;cursor:not-allowed}
textarea.notes{display:none;width:100%;margin-top:4px;background:#130808;
  color:var(--text);border:1px solid #3a1a1a;border-radius:4px;
  padding:4px 6px;font-size:11px;font-family:'Segoe UI',sans-serif;
  resize:vertical;min-height:50px;outline:none;transition:border .15s}
textarea.notes:focus{border-color:var(--red)}
textarea.notes.open{display:block}
textarea.notes[readonly]{opacity:.5;cursor:default}
td.admin-cell.other{opacity:.7}

/* Export modal */
#modal{display:none;position:fixed;inset:0;background:rgba(0,0,0,.82);
  align-items:center;justify-content:center;z-index:999}
#modal.show{display:flex}
.modal-box{background:var(--bg2);border:1px solid var(--border);border-radius:8px;
  padding:24px;width:700px;max-width:94vw;max-height:82vh;
  display:flex;flex-direction:column;gap:12px}
.modal-box h3{color:var(--gold);font-size:16px}
.modal-box textarea{flex:1;background:var(--bg);color:var(--text);
  border:1px solid var(--border);border-radius:4px;padding:12px;
  font-family:Consolas,monospace;font-size:12px;resize:none;min-height:300px;outline:none}
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
const FIRESTORE     = 'https://firestore.googleapis.com/v1/projects/legendary-relaunch/databases/(default)/documents/votes';
const FIRESTORE_CMT = 'https://firestore.googleapis.com/v1/projects/legendary-relaunch/databases/(default)/documents/comments';
const POLL_MS       = 15000;
const ADMINS        = ['Bro','Ririn','Kirin','Sivart'];

let myAdmin    = '';
let allVotes   = {};   // cellId  -> { admin, vote, notes }
let allCmts    = {};   // docId   -> { admin, section, text }
let pollTimer  = null;
let pollTick   = null;
let lastPoll   = null;

/* ── Identity ────────────────────────────────────────────────────────────── */
function setAdmin(name) {
  myAdmin = name;
  sessionStorage.setItem('lgnd-admin', name);
  document.querySelectorAll('.admin-id-btn').forEach(b =>
    b.classList.toggle('active', b.dataset.admin === name));
  document.getElementById('admin-status').textContent = 'Voting as: ' + name;
  renderAllVotes();
  renderAllCmts();
  startPoll();
}

/* ── Firestore helpers ───────────────────────────────────────────────────── */
function toFS(obj) {
  const f = {};
  for (const [k,v] of Object.entries(obj)) f[k] = {stringValue: String(v)};
  return {fields: f};
}
function fromFS(doc) {
  const out = {};
  for (const [k,v] of Object.entries(doc.fields||{}))
    out[k] = v.stringValue !== undefined ? v.stringValue : '';
  return out;
}

async function fetchAll() {
  try {
    const [rv, rc] = await Promise.all([
      fetch(FIRESTORE     + '?pageSize=2000').then(r=>r.json()),
      fetch(FIRESTORE_CMT + '?pageSize=2000').then(r=>r.json()),
    ]);
    allVotes = {};
    (rv.documents||[]).forEach(d => {
      const id = decodeURIComponent(d.name.split('/').pop());
      allVotes[id] = fromFS(d);
    });
    allCmts = {};
    (rc.documents||[]).forEach(d => {
      const id = decodeURIComponent(d.name.split('/').pop());
      allCmts[id] = fromFS(d);
    });
    renderAllVotes();
    renderAllCmts();
    refreshCounts();
    lastPoll = Date.now();
    const dot = document.getElementById('poll-dot');
    if (dot) { dot.classList.add('live'); setTimeout(()=>dot.classList.remove('live'), 800); }
  } catch(e) { console.error('Firestore fetch error:', e); }
}

async function saveVote(cellId, vote, notes) {
  if (!myAdmin) return;
  const body = toFS({admin:myAdmin, cellId, vote:vote||'', notes:notes||''});
  try {
    await fetch(FIRESTORE + '/' + encodeURIComponent(cellId), {
      method:'PATCH', headers:{'Content-Type':'application/json'}, body:JSON.stringify(body)
    });
    allVotes[cellId] = {admin:myAdmin, cellId, vote:vote||'', notes:notes||''};
    refreshCounts();
  } catch(e) { console.error('Firestore vote save error:', e); }
}

async function saveCmt(section, admin, text) {
  const docId = section + '_' + admin;
  const body  = toFS({admin, section, text});
  try {
    await fetch(FIRESTORE_CMT + '/' + encodeURIComponent(docId), {
      method:'PATCH', headers:{'Content-Type':'application/json'}, body:JSON.stringify(body)
    });
    allCmts[docId] = {admin, section, text};
    updateSFBHeader(section);
  } catch(e) { console.error('Firestore comment save error:', e); }
}

/* ── Render votes ────────────────────────────────────────────────────────── */
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

    if (vote === 'disagree') { ta.value = notes; ta.classList.add('open'); }
    else { ta.value = ''; ta.classList.remove('open'); }

    const isMyCol = myAdmin && admin === myAdmin;
    sel.disabled = !isMyCol;
    ta.readOnly  = !isMyCol;
    td.classList.toggle('other', !!myAdmin && !isMyCol);
  });
}

/* ── Render section comments ─────────────────────────────────────────────── */
function renderAllCmts() {
  document.querySelectorAll('.sec-fb').forEach(sf => {
    const section = sf.dataset.section;
    sf.querySelectorAll('.sfb-ta').forEach(ta => {
      const admin  = ta.dataset.admin;
      const docId  = section + '_' + admin;
      const v      = allCmts[docId];
      ta.value     = v ? v.text : '';
      ta.classList.toggle('has-text', !!(v && v.text));
      const isMe   = myAdmin && admin === myAdmin;
      ta.readOnly  = !isMe;
    });
    updateSFBHeader(section);
  });
}

function updateSFBHeader(section) {
  const sf = document.querySelector('.sec-fb[data-section="' + section + '"]');
  if (!sf) return;
  const count = ADMINS.filter(a => {
    const v = allCmts[section + '_' + a];
    return v && v.text && v.text.trim();
  }).length;
  const btn = sf.querySelector('.sfb-toggle');
  const ct  = sf.querySelector('.sfb-ct');
  if (ct)  ct.textContent = count ? ' (' + count + ' note' + (count===1?'':'s') + ')' : '';
  if (btn) btn.classList.toggle('has-notes', count > 0);
}

/* ── Event handlers ──────────────────────────────────────────────────────── */
function onVote(sel) {
  if (!myAdmin) { alert('Click your name at the top first.'); sel.value=''; return; }
  const td    = sel.closest('td');
  if (td.dataset.admin !== myAdmin) return;
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
  const td = ta.closest('td');
  if (td.dataset.admin !== myAdmin) return;
  saveVote(ta.dataset.cellId, ta.previousElementSibling.value, ta.value);
}

function onCmt(ta) {
  if (!myAdmin) return;
  if (ta.dataset.admin !== myAdmin) return;
  ta.classList.toggle('has-text', !!ta.value.trim());
  saveCmt(ta.dataset.section, myAdmin, ta.value);
}

function toggleSFB(btn) {
  const body = btn.nextElementSibling;
  const open = !body.hidden;
  body.hidden = open;
  btn.classList.toggle('open', !open);
  if (!open) {
    // Make sure readonly state is current
    renderAllCmts();
  }
}

/* ── Poll ────────────────────────────────────────────────────────────────── */
function startPoll() {
  if (pollTimer) clearInterval(pollTimer);
  if (pollTick)  clearInterval(pollTick);
  fetchAll();
  pollTimer = setInterval(fetchAll, POLL_MS);
  pollTick  = setInterval(() => {
    const el = document.getElementById('poll-status');
    if (!el || !lastPoll) return;
    el.textContent = 'Live \xb7 ' + Math.round((Date.now()-lastPoll)/1000) + 's ago';
  }, 1000);
}

/* ── Counts ──────────────────────────────────────────────────────────────── */
function refreshCounts() {
  const total  = document.querySelectorAll('select.vote').length;
  const vals   = Object.values(allVotes);
  const agrees = vals.filter(v=>v.vote==='agree').length;
  const dis    = vals.filter(v=>v.vote==='disagree').length;
  const pend   = total - Math.min(agrees+dis, total);
  document.getElementById('vote-counts').innerHTML =
    '<b>' + total + '</b> vote cells<br>' +
    '<span style="color:var(--green)">&#10003; Agree: <b>' + agrees + '</b></span><br>' +
    '<span style="color:var(--red)">&#10007; Disagree: <b>' + dis + '</b></span><br>' +
    '<span style="color:var(--muted)">&mdash; Pending: <b>' + pend + '</b></span>';
}

/* ── Export ──────────────────────────────────────────────────────────────── */
function rowContext(cellId) {
  const td = document.querySelector('td[data-cell-id="' + cellId + '"]');
  if (!td) return cellId;
  const row = td.closest('tr');
  const first = row && row.querySelector('td:not(.admin-cell)');
  return first ? first.innerText.replace(/\s+/g,' ').trim().slice(0,70) : cellId;
}

function exportFeedback() {
  const lines = ['LEGENDARY FFXI — ADMIN REVIEW EXPORT', '='.repeat(52), ''];
  const byAdmin = {};
  ADMINS.forEach(a => byAdmin[a] = {agrees:[], disagrees:[], cmts:[]});

  Object.values(allVotes).forEach(v => {
    if (!v.vote || !v.admin || !byAdmin[v.admin]) return;
    const ctx = rowContext(v.cellId);
    if (v.vote==='agree')    byAdmin[v.admin].agrees.push(ctx);
    if (v.vote==='disagree') byAdmin[v.admin].disagrees.push({ctx, notes:v.notes||''});
  });

  // Collect section comments
  Object.values(allCmts).forEach(c => {
    if (!c.text || !c.admin || !byAdmin[c.admin]) return;
    const h = document.getElementById(c.section);
    const label = h ? h.innerText.replace(/\s+/g,' ').trim() : c.section;
    byAdmin[c.admin].cmts.push({label, text: c.text});
  });

  const totalCells = document.querySelectorAll('select.vote').length;
  const voted = Object.values(allVotes).filter(v=>v.vote).length;
  const cmtCount = Object.values(allCmts).filter(c=>c.text&&c.text.trim()).length;
  lines.push('SUMMARY');
  lines.push('  Vote cells: ' + voted + ' / ' + totalCells);
  lines.push('  Agrees:     ' + Object.values(allVotes).filter(v=>v.vote==='agree').length);
  lines.push('  Disagrees:  ' + Object.values(allVotes).filter(v=>v.vote==='disagree').length);
  lines.push('  Comments:   ' + cmtCount);
  lines.push('');

  ADMINS.forEach(admin => {
    const d = byAdmin[admin];
    const total = d.agrees.length + d.disagrees.length + d.cmts.length;
    if (total === 0) return;
    lines.push('== ' + admin.toUpperCase() + ' ' + '='.repeat(48 - admin.length));
    if (d.cmts.length) {
      lines.push('  SECTION NOTES:');
      d.cmts.forEach(({label, text}) => {
        lines.push('    [' + label + ']');
        lines.push('    ' + text.replace(/\n/g, '\n    '));
      });
      lines.push('');
    }
    if (d.disagrees.length) {
      lines.push('  DISAGREES:');
      d.disagrees.forEach(({ctx, notes}) => {
        lines.push('    • ' + ctx);
        if (notes) lines.push('      -> ' + notes);
      });
    }
    if (d.agrees.length) {
      lines.push('  AGREES (' + d.agrees.length + '):');
      d.agrees.forEach(ctx => lines.push('    ✓ ' + ctx));
    }
    lines.push('');
  });

  document.getElementById('export-text').value = lines.join('\n');
  document.getElementById('modal').classList.add('show');
}

function copyExport() {
  const ta = document.getElementById('export-text');
  ta.select(); document.execCommand('copy');
  const btn = document.querySelector('.btn-copy');
  btn.textContent = '✓ Copied!';
  setTimeout(() => btn.textContent = 'Copy to Clipboard', 2000);
}

function closeModal() { document.getElementById('modal').classList.remove('show'); }

function clearMyVotes() {
  if (!myAdmin) { alert('Select your name first.'); return; }
  if (!confirm('Clear all YOUR row-votes? Section notes are kept.')) return;
  Object.keys(allVotes).filter(id => allVotes[id].admin === myAdmin).forEach(async id => {
    await fetch(FIRESTORE + '/' + encodeURIComponent(id), {method:'DELETE'});
    delete allVotes[id];
  });
  setTimeout(fetchAll, 400);
}

/* ── Init ────────────────────────────────────────────────────────────────── */
window.addEventListener('load', () => {
  const saved = sessionStorage.getItem('lgnd-admin');
  if (saved) setAdmin(saved);
  else startPoll();
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

<div id="admin-bar">
  <span class="label">I am:</span>
{admin_buttons}
  <span id="admin-status">— click your name to vote &amp; comment</span>
  <span id="poll-status"><span id="poll-dot"></span>connecting…</span>
</div>

<div id="layout">

<nav id="sidebar">
  <div class="logo">&#9876; Legendary FFXI<span>Admin Review &middot; Live</span></div>
  <div class="nav-section">Sections</div>
  {nav}
  <hr>
  <div class="nav-section">Tools</div>
  <button class="sb-btn export" onclick="exportFeedback()">&#128203; Export All Feedback</button>
  <button class="sb-btn clr"    onclick="clearMyVotes()">&#128465; Clear My Row Votes</button>
  <div id="vote-counts"></div>
</nav>

<main id="content">
  <div class="plan-banner">
    <h1>&#9876; Legendary FFXI &mdash; Relaunch Plan</h1>
    <p>Click your name above. Vote on table rows &middot; Leave section notes via the &#9998; Admin Notes button under each heading.</p>
    <div class="legend">
      <span class="leg-a">&#10003; Agree</span>
      <span class="leg-d">&#10007; Disagree + notes</span>
      <span class="leg-p">&mdash; Pending</span>
    </div>
  </div>
  {body}
</main>

</div>

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
    html = re.sub(r'<table[^>]*>.*?</table>', do_table, html, flags=re.DOTALL)

    print('Adding heading IDs...')
    html = add_heading_ids(html)

    print('Injecting section feedback blocks...')
    html = inject_section_feedback(html)

    nav  = build_nav(html)

    print('Writing HTML...')
    page = build_page(html, nav)
    with open(HTML_OUT, 'w', encoding='utf-8') as f:
        f.write(page)

    size_kb = os.path.getsize(HTML_OUT) // 1024
    print(f'Done -> {HTML_OUT} ({size_kb} KB)')

if __name__ == '__main__':
    main()
