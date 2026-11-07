"""project_name.py: the name of the project a file belongs to, for the pages ck publishes.

The name is the folder of the git repository's main checkout, found from the common git
directory, so a file in a worktree under .claude/worktrees/ still names the project. With
no repository, it is the file's own folder. Imported by render-review.py and render-gallery.py.
"""
import pathlib, re, subprocess

def project_name(path):
    d = pathlib.Path(path).resolve()
    if not d.is_dir(): d = d.parent
    while not d.exists(): d = d.parent
    try:
        out = subprocess.run(['git', '-C', str(d), 'rev-parse', '--path-format=absolute', '--git-common-dir'],
                             capture_output=True, text=True, check=True).stdout.strip()
    except (OSError, subprocess.CalledProcessError):
        return d.name
    common = pathlib.Path(out)
    return common.parent.name if common.name == '.git' else re.sub(r'\.git$', '', common.name)

def _key(s): return re.sub(r'[^a-z0-9]', '', s.lower())

def with_project(title, project):
    """'<project>: <title>', unless the title already starts with the project's name."""
    if not project or _key(title).startswith(_key(project)): return title
    return f'{project}: {title}' if title else project
