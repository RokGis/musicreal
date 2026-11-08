import json,pathlib
root=pathlib.Path(__file__).resolve().parent
entries=json.loads((root/'statistics_map.json').read_text())
counts=json.loads(next(line.split('STATISTICS_PROBE=',1)[1] for line in (root/'statistics_probe.log').read_text(encoding='utf-8-sig').splitlines() if 'STATISTICS_PROBE=' in line))
metrics=json.loads((root/'statistics_metrics.json').read_text(encoding='utf-8-sig'))
functions={name.split('.')[-1]:(r,fn) for r in metrics['records'] for name,fn in r['functions'].items() if name.split('.')[-1] in ['_topSongs','_emotionTotals']}
lcov=(root/'statistics_lcov.info').read_text(encoding='utf-8-sig')
result={}
for name,(record,fn) in functions.items():
    nodes=[e for e in entries if e['method']==name]
    statements=[e for e in nodes if e['kind']=='statement']
    decisions=[e for e in nodes if e['kind'] in ['decision','loop-decision']]
    start=fn['codeSpan']['start']['line'];end=fn['codeSpan']['end']['line']
    target=next(x for x in lcov.split('end_of_record') if any(line.startswith('SF:') and line[3:].strip().replace('\\','/').endswith('lib/statistics/statistics_widget.dart') for line in x.splitlines()))
    lines=[];branches=[]
    for line in target.splitlines():
        if line.startswith('DA:'):
            num,n=line[3:].split(',')[:2]
            if start<=int(num)<=end: lines.append(int(n))
        if line.startswith('BRDA:'):
            num,_,_,n=line[5:].split(',')
            if start<=int(num)<=end: branches.append(n)
    result[name]={'statements':[sum(counts['statements'].get(e['id'],0)>0 for e in statements),len(statements)],
        'decisions':[sum(counts['decisions'].get(e['id'],{}).get(v,0)>0 for e in decisions for v in ['true','false']),2*len(decisions)],
        'lines':[sum(n>0 for n in lines),len(lines)],'vm_branches':[sum(n not in ['0','-'] for n in branches),len(branches)],
        'line_range':[start,end]}
report={'run':'additional statistics check, 2026-10-26','tests':'3 PASS; separate from original Rokas tests','functions':result,'counts':counts}
(root/'statistics_summary.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(result,ensure_ascii=False,indent=2))
