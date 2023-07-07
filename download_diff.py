from difflib import unified_diff
import os

from tqdm import tqdm
import gitbox
from gitbox import vul_db
from loguru import logger
import subprocess as sp
import pandas as pd

cpool = vul_db.get_connection_pool()
conn = cpool.get_connection()

cdr = vul_db.execute("""
    SELECT cdr.id,
        cdr.vuln_project_id, cdr.vuln_commit_id, cdr.vuln_file_path, cdr.vuln_func_name,
        cdr.vuln_func_code once_vuln_code, cvcf.after_code once_fixed_code,
        cvcf.raw_file_diff, cvcf.func_diff,
        cdr.rollback_commit_id
    FROM clone_detection_result cdr
    JOIN combined_vuln_commit_functions cvcf
    ON cdr.vuln_commit_id = cvcf.commit_id
    AND cdr.vuln_file_path = cvcf.file_path
    AND cdr.vuln_func_name = cvcf.func_name
""")

cdr = pd.DataFrame(
    cdr,
    columns=['id',
             'vuln_project_id', 'vuln_commit_id',
             'vuln_file_path', 'vuln_func_name',
             'once_vuln_code', 'once_fixed_code',
             'raw_file_diff', 'func_diff',
             'rollback_commit_id'])

for resultchunk in tqdm(gitbox.util.chunked(cdr.itertuples())):
    for result in resultchunk:
        if not os.path.exists(f"output/{result.vuln_project_id}/{result.vuln_func_name}"):
            continue
        out = f"output/{result.vuln_project_id}/{result.vuln_func_name}/{result.vuln_commit_id}.raw_file.diff"
        with open(out, 'w') as f:
            f.write(result.raw_file_diff)

        out = f"output/{result.vuln_project_id}/{result.vuln_func_name}/{result.vuln_commit_id}.func.diff"
        with open(out, 'w') as f:
            f.write(result.func_diff)

        gitrepo = gitbox.open_git_repo(result.vuln_project_id)
        assert gitrepo is not None

        gitcommit = gitbox.get_commit(gitrepo, result.vuln_commit_id)
        assert gitcommit is not None

        patch = gitbox.get_commit_patch(gitcommit)
        out = f"output/{result.vuln_project_id}/{result.vuln_func_name}/{result.vuln_commit_id}.patch"
        with open(out, 'w') as f:
            f.write(patch)

        if result.rollback_commit_id is not None:
            gitcommit = gitbox.get_commit(gitrepo, result.rollback_commit_id)
            assert gitcommit is not None

            patch = gitbox.get_commit_patch(gitcommit)
            out = f"output/{result.vuln_project_id}/{result.vuln_func_name}/rollback_{result.rollback_commit_id}.patch"
            with open(out, 'w') as f:
                f.write(patch)
