"""Generate/check the complete SQL-readable known-object Skill catalogue."""
from pathlib import Path
import argparse
import usage_skills

ROOT=Path(__file__).resolve().parents[2]


def generate(root=ROOT,output=None,check=False,write=False):
    text=usage_skills.render_catalogue(root)
    target=root/usage_skills.VIEW_TARGET
    usage_skills.require(not (output is not None and (check or write)), 'Getrennte Ausgabeoperation erforderlich')
    if check:
        if not target.is_file() or target.read_text(encoding='utf-8-sig')!=text:
            raise ValueError('USAGE_SKILL_VIEW_DRIFT')
    elif write:
        target.parent.mkdir(parents=True,exist_ok=True)
        target.write_text(text,encoding='utf-8',newline='\n')
    elif output is not None:
        output=Path(output)
        usage_skills.require(not output.exists(), 'Neue Ausgabedatei erforderlich')
        output.parent.mkdir(parents=True,exist_ok=True)
        with output.open('x',encoding='utf-8',newline='\n') as stream:stream.write(text)
    return len(usage_skills.inventory(root))


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    mode=parser.add_mutually_exclusive_group()
    mode.add_argument('--check',action='store_true')
    mode.add_argument('--write',action='store_true')
    mode.add_argument('--output',type=Path)
    args=parser.parse_args()
    print('USAGE_SKILL_CATALOGUE_PASS objects='+str(generate(output=args.output,check=args.check,write=args.write))+'; NO_SQL_EXECUTED')
