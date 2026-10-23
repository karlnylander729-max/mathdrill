#!/bin/zsh
# Usage: scripts/selftest.sh index.html  (headless Chrome runs index.html#test and prints the results)
f=${1:?usage: selftest.sh path/to/index.html}
f=${f:A}
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu --no-first-run --user-data-dir=$(mktemp -d) --virtual-time-budget=15000 --dump-dom "file://$f#test" 2>/dev/null | python3 -c "
import sys,re,html,json
m=re.search(r'<pre id=\"selftest\"[^>]*>(.*?)</pre>',sys.stdin.read(),re.S)
if not m or not m.group(1).strip(): print('FAIL: NO OUTPUT (runSelfTest threw?)'); sys.exit(1)
d=json.loads(html.unescape(m.group(1)))
print('OK' if d['ok'] else 'FAIL', 'checker passed', d['checker']['passed'], 'syntax cases', d['syntax']['cases'], d['syntax']['failed']); print('incentives', json.dumps(d['incentives'])); print('mastery', d['mastery']['failed'])
for f in d['checker']['failed']: print('  CHK', f)
for f in d.get('concepts', ['concepts missing']): print('  CONCEPT', f)
for g in d['generators']:
  flag = '!!' if g['errors'] else '  '
  print(flag, g['id'], 'wk', g['week'], 'distinct', g['distinct'], 'true%', g.get('trueRatio',''), *g['errors'][:3])
"
