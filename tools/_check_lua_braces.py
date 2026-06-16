#!/usr/bin/env python3
# Lua-aware bracket balance checker. Skips line comments (--), long comments
# (--[[ ]]), and single/double-quoted strings (with backslash escapes). Not a
# full parser, but catches the structural errors a big block-edit pass can
# introduce. Usage: python tools/_check_lua_braces.py <file.lua>
import sys

path = sys.argv[1]
s = open(path, encoding='utf-8').read()
i, n, line = 0, len(s), 1
stack = []
counts = {'{': 0, '}': 0, '(': 0, ')': 0, '[': 0, ']': 0}
errors = []
state = 'code'

while i < n:
    c = s[i]
    if c == '\n':
        line += 1
    if state == 'code':
        if c == '-' and s[i+1:i+2] == '-':
            if s[i+2:i+4] == '[[':
                state = 'long'; i += 4; continue
            state = 'lc'; i += 2; continue
        if c == "'":
            state = 'sq'; i += 1; continue
        if c == '"':
            state = 'dq'; i += 1; continue
        if c in '{([':
            counts[c] += 1; stack.append((c, line))
        elif c in '})]':
            counts[c] += 1
            pair = {'}': '{', ')': '(', ']': '['}[c]
            if not stack:
                errors.append('line %d: unmatched %s' % (line, c))
            else:
                o, ol = stack.pop()
                if o != pair:
                    errors.append('line %d: %s closes %s opened line %d' % (line, c, o, ol))
        i += 1
    elif state == 'lc':
        if c == '\n':
            state = 'code'
        i += 1
    elif state == 'long':
        if c == ']' and s[i+1:i+2] == ']':
            state = 'code'; i += 2; continue
        i += 1
    elif state == 'sq':
        if c == '\\':
            i += 2; continue
        if c == "'":
            state = 'code'
        i += 1
    elif state == 'dq':
        if c == '\\':
            i += 2; continue
        if c == '"':
            state = 'code'
        i += 1

for k in ('{}', '()', '[]'):
    o, c = k
    ok = 'OK' if counts[o] == counts[c] else 'MISMATCH'
    print('%s %d  %s %d  %s' % (o, counts[o], c, counts[c], ok))
if stack:
    print('UNCLOSED (first 5):', stack[:5])
for e in errors[:10]:
    print(e)
print('PARSE_CLEAN' if not errors and not stack and counts['{'] == counts['}'] and counts['('] == counts[')'] else 'PROBLEMS')
