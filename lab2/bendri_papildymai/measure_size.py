"""Measure only frozen, tracked Dart/JavaScript sources; no working-tree edits."""
import subprocess, pathlib, json, hashlib, collections
ROOT = pathlib.Path(__file__).resolve().parent
REPO = pathlib.Path(r'C:\Users\pedse\Downloads\musicreal')
REV = 'd90e75ae77d128f895771bfc709856d50ddaf8d6'
CLOC = ROOT/'tools/cloc-2.10.exe'
snapshot = ROOT/'source_snapshot'
snapshot.mkdir(exist_ok=True)
paths = subprocess.check_output(['git','ls-tree','-r','--name-only',REV],cwd=REPO,text=True).splitlines()
selected = [p for p in paths if
    ((p.startswith('lib/') or p.startswith('test/')) and p.endswith('.dart')) or
    (p.startswith('firebase/functions/') and p.endswith('.js') and not pathlib.PurePosixPath(p).name.startswith('.'))]
manifest = []
for path in selected:
    content = subprocess.check_output(['git','show',f'{REV}:{path}'],cwd=REPO)
    target = snapshot/path
    target.parent.mkdir(parents=True,exist_ok=True)
    target.write_bytes(content)
    manifest.append({'path':path,'sha256':hashlib.sha256(content).hexdigest()})
(ROOT/'source_manifest.json').write_text(json.dumps({'commit':REV,'files':manifest},indent=2),encoding='utf-8')
command=[str(CLOC),str(snapshot),'--by-file','--json','--skip-uniqueness',f'--out={ROOT / "cloc_by_file.json"}']
result=subprocess.run(command,capture_output=True,text=True)
(ROOT/'cloc_run.log').write_text('COMMAND: '+' '.join(command)+'\n'+result.stdout+'\n'+result.stderr,encoding='utf-8')
result.check_returncode()
data=json.loads((ROOT/'cloc_by_file.json').read_text(encoding='utf-8-sig'))
groups={}
for filename,counts in data.items():
    if filename in ['header','SUM']: continue
    path=pathlib.Path(filename).relative_to(snapshot).as_posix()
    if path.startswith('test/'): group='Esami testai (test/, HEAD)'
    elif path.endswith('.g.dart'): group='Generuoti *.g.dart failai (lib/)'
    elif path.startswith('lib/flutter_flow/'): group='FlutterFlow pagalbiniai failai (lib/flutter_flow/)'
    elif path.startswith('lib/'): group='Kiti programos Dart failai (lib/)'
    else: group='Serverio JavaScript (firebase/functions/)'
    row=groups.setdefault(group,{'files':0,'LOC':0,'CLOC':0,'NCLOC':0,'blank':0})
    row['files']+=1
    row['LOC']+=counts['blank']+counts['comment']+counts['code']
    row['CLOC']+=counts['comment'];row['NCLOC']+=counts['code'];row['blank']+=counts['blank']
app={k:sum(v[k] for n,v in groups.items() if not n.startswith('Esami testai')) for k in ['files','LOC','CLOC','NCLOC','blank']}
report={'commit':REV,'tool':'cloc 2.10','groups':groups,'application_total':app,'all_including_tests':data['SUM'],
 'definitions':{'LOC':'blank + comment + code','CLOC':'cloc comment: comment-only lines','NCLOC':'cloc code: nonblank code lines, including code with trailing comments'},
 'scope':'Tracked lib/**/*.dart, test/**/*.dart, firebase/functions/**/*.js except dotfiles. Tests reported separately; later untracked LD2 tests excluded.'}
(ROOT/'size_summary.json').write_text(json.dumps(report,indent=2,ensure_ascii=False),encoding='utf-8')
print(json.dumps(report,indent=2,ensure_ascii=False))
