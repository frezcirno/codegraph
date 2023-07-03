from difflib import unified_diff

from tqdm import tqdm
import gitbox
from gitbox import vul_db
from loguru import logger
import subprocess as sp
import pandas as pd

cpool = vul_db.get_connection_pool()
conn = cpool.get_connection()

combined_vuln_commit_functions = vul_db.execute("""
    SELECT id, project_id, commit_id, file_path, func_name, before_code, after_code
    FROM combined_vuln_commit_functions
""")

combined_vuln_commit_functions = pd.DataFrame(
    combined_vuln_commit_functions,
    columns=['id', 'project_id', 'commit_id', 'file_path', 'func_name', 'before_code', 'after_code'])

for resultchunk in tqdm(gitbox.util.chunked(combined_vuln_commit_functions.itertuples())):
    for result in resultchunk:
        raw_diff = None

        gitrepo = gitbox.open_git_repo(result.project_id)
        assert gitrepo is not None
        gitcommit = gitbox.get_commit(gitrepo, result.commit_id)
        if gitcommit:
            di = gitbox.get_commit_diff(gitcommit, [result.file_path], create_patch=True)
            raw_diff = "".join([d.diff.decode('utf-8', errors='ignore') for d in di])

        func_diff = "\n".join(list(unified_diff(result.before_code.splitlines(), result.after_code.splitlines(), lineterm=''))[2:])

        vul_db.execute("""
            UPDATE combined_vuln_commit_functions
            SET raw_diff = %s, func_diff = %s
            WHERE id = %s
        """, (raw_diff, func_diff, result.id), conn=conn, commit=False)

    conn.commit()
