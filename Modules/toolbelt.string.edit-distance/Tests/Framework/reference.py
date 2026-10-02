"""Unabhängige Scalar-/Vollmatrixreferenz; kein SQL-/Provider-Nachweis."""
import itertools
import json
from pathlib import Path

assertions = 0
def check(condition):
    global assertions
    assert condition
    assertions += 1

def scalars(text):
    raw = text.encode("utf-16-le", "surrogatepass")
    values = [raw[i] | raw[i+1] << 8 for i in range(0, len(raw), 2)]
    result, i = [], 0
    while i < len(values):
        cp = values[i]
        if 0xD800 <= cp <= 0xDBFF:
            if i+1 == len(values) or not 0xDC00 <= values[i+1] <= 0xDFFF:
                raise ValueError("UTF16")
            result.append(0x10000 + ((cp-0xD800) << 10) + values[i+1]-0xDC00)
            i += 2
        elif 0xDC00 <= cp <= 0xDFFF:
            raise ValueError("UTF16")
        else:
            result.append(cp)
            i += 1
    return result

def matrix(a, b, osa):
    d = [[0]*(len(b)+1) for _ in range(len(a)+1)]
    for i in range(len(a)+1): d[i][0] = i
    for j in range(len(b)+1): d[0][j] = j
    for i in range(1, len(a)+1):
        for j in range(1, len(b)+1):
            d[i][j] = min(d[i-1][j]+1, d[i][j-1]+1, d[i-1][j-1]+(a[i-1] != b[j-1]))
            if osa and i > 1 and j > 1 and a[i-1] == b[j-2] and a[i-2] == b[j-1]:
                d[i][j] = min(d[i][j], d[i-2][j-2]+1)
    return d[-1][-1]

def cells(n, m, threshold):
    if threshold is None: return n*m
    k = min(threshold, max(n, m))
    return sum(max(0, min(m, i+k)-max(1, i-k)+1) for i in range(1, n+1))

def banded(a, b, threshold, osa):
    n, m = len(a), len(b)
    if abs(n-m) > threshold: return None
    k = min(threshold, max(n, m))
    inf = max(n, m)+1
    previous = {j:j for j in range(min(m,k)+1)}
    older = {}
    for i in range(1, n+1):
        current = {0:i} if i <= k else {}
        for j in range(max(1,i-k), min(m,i+k)+1):
            value = min(previous.get(j,inf)+1, current.get(j-1,inf)+1,
                        previous.get(j-1,inf)+(a[i-1] != b[j-1]))
            if osa and i > 1 and j > 1 and a[i-1] == b[j-2] and a[i-2] == b[j-1]:
                value = min(value, older.get(j-2,inf)+1)
            current[j] = min(value, inf)
        older, previous = previous, current
    value = previous.get(m, inf)
    return value if value <= threshold else None

def contract(left, right, max_distance=None, profile="standard", osa=False):
    # Referenz zum schriftlich festgelegten Profilvertrag.
    if left is None or right is None: return (None, None, 0)
    if profile not in ("standard", "large"): return (None, None, 1)
    if max_distance is not None and (not isinstance(max_distance,int) or max_distance < 0 or max_distance > 2147483647):
        return (None, None, 2)
    scalar_limit, unit_limit, work_limit = (1024,2048,1048576) if profile == "standard" else (32768,65536,16777216)
    if any(len(t.encode("utf-16-le","surrogatepass"))//2 > unit_limit for t in (left,right)):
        return (None,None,3)
    try: a,b = scalars(left),scalars(right)
    except ValueError: return (None,None,4)
    if max(len(a),len(b)) > scalar_limit: return (None,None,5)
    if max_distance is not None and abs(len(a)-len(b)) > max_distance: return (None,True,0)
    if cells(len(a),len(b),max_distance) > work_limit: return (None,None,6)
    value = matrix(a,b,osa) if max_distance is None else banded(a,b,max_distance,osa)
    return (None,True,0) if value is None else (value,False,0)

def run():
    samples = [""] + ["".join(p) for n in range(1,5) for p in itertools.product("ab",repeat=n)]
    for left in samples:
        for right in samples:
            a,b = scalars(left),scalars(right)
            for osa in (False,True):
                distance = matrix(a,b,osa)
                check(distance == matrix(b,a,osa))
                for threshold in range(5):
                    check(banded(a,b,threshold,osa) == (distance if distance <= threshold else None))
                    check(cells(len(a),len(b),threshold) == sum(1 for i in range(1,len(a)+1) for j in range(1,len(b)+1) if abs(i-j)<=threshold))
    for left,right,lev,osa in [("kitten","sitting",3,3),("CA","AC",2,1),("CA","ABC",3,3),
                               ("\U0001F600","",1,1),("\U0001F600","\U0001F601",1,1),
                               ("\U0001F600a","a\U0001F600",2,1),("é","e\u0301",2,2),
                               ("A","a",1,1),("a ","a",1,1),("\0","",1,1)]:
        check(matrix(scalars(left),scalars(right),False) == lev)
        check(matrix(scalars(left),scalars(right),True) == osa)
    check(scalars("\U00010000\U0010ffff") == [0x10000,0x10ffff])
    for invalid in ("\ud800","\udfff","\ud800x","x\udc00","\udc00\ud800"):
        check(contract(invalid,"a")[2] == 4)
    check(contract(None,"a",-1,"invalid") == (None,None,0))
    check(contract("\ud800","a",-1,"invalid")[2] == 1)
    check(contract("\ud800","a",-1)[2] == 2)
    check(contract("a"*2049,"a")[2] == 3)
    check(contract("a"*1025,"a")[2] == 5)
    check(contract("\U0001F600"*1024,"")[0] == 1024)
    check(contract("a"*32768,"",profile="large")[0] == 32768)
    check(contract("a"*32769,"",profile="large")[2] == 5)
    check(contract("a"*65537,"",profile="large")[2] == 3)
    check(cells(1024,1024,None) == 1048576)
    check(cells(4096,4096,None) == 16777216)
    check(cells(4096,4097,None) == 16781312)
    check(contract("a"*4096,"b"*4097,profile="large")[2] == 6)
    check(cells(32768,32768,1) == 98302)
    check(banded(scalars("a"*32768),scalars("a"*32768),1,True) == 0)
    check(contract("a"*32768,"",0,"large") == (None,True,0))
    check(contract("a","b",2147483647) == (1,False,0))
    return assertions

if __name__ == "__main__":
    result={"status":"PASS","assertions":run(),"scope":"Python private reference; SQL/Framework/provider NOT_EXECUTED",
            "standard":{"scalars":1024,"utf16Units":2048,"cells":1048576},
            "large":{"scalars":32768,"utf16Units":65536,"cells":16777216}}
    print(json.dumps(result))
