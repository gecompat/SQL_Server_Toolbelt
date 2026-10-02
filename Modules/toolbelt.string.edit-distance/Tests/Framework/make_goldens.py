import itertools
import sys
from pathlib import Path
import reference
samples=['']+[''.join(p) for n in range(1,5) for p in itertools.product('ab',repeat=n)]
samples += ['\U0001F600','\U0001F601','\U0001F600a','a\U0001F600','é','e\u0301','A','a ','\0','CA','ABC','kitten','sitting']
rows=[]
for left in samples:
 for right in samples:
  for osa in (False,True):
   distance=reference.matrix(reference.scalars(left),reference.scalars(right),osa)
   for k in (None,0,1,2,3,4,2147483647):
    expected=distance if k is None or distance<=k else -1
    rows.append('|'.join((str(int(osa)),left.encode('utf-16-le').hex(),right.encode('utf-16-le').hex(),str(-1 if k is None else k),str(expected))))
Path(sys.argv[1]).write_text('\n'.join(rows),encoding='ascii')
print('GOLDEN_ROWS='+str(len(rows)))