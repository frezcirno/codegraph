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
        cdr.vuln_project_id, cdr.vuln_commit_id,
        cdr.file_path, cdr.func_name, 
        cdr.vuln_func_code once_vuln_code, cvcf.after_code once_fixed_code,
        cvcf.raw_file_diff, cvcf.func_diff
    FROM clone_detection_result cdr
    JOIN combined_vuln_commit_functions cvcf
    ON cdr.vuln_commit_id = cvcf.commit_id
    AND cdr.file_path = cvcf.file_path
    AND cdr.func_name = cvcf.func_name
""")

cdr = pd.DataFrame(
    cdr,
    columns=['id', 'vuln_project_id', 'vuln_commit_id', 'file_path', 'func_name', 'once_vuln_code', 'once_fixed_code', 'raw_file_diff', 'func_diff'])

for resultchunk in tqdm(gitbox.util.chunked(cdr.itertuples())):
    for result in resultchunk:
        if not os.path.exists(f"output/{result.vuln_project_id}/{result.func_name}"):
            continue
        out = f"output/{result.vuln_project_id}/{result.func_name}/{result.vuln_commit_id}.raw_file.diff"
        with open(out, 'w') as f:
            f.write(result.raw_file_diff)

        out = f"output/{result.vuln_project_id}/{result.func_name}/{result.vuln_commit_id}.func.diff"
        with open(out, 'w') as f:
            f.write(result.func_diff)

        gitrepo = gitbox.open_git_repo(result.vuln_project_id)
        assert gitrepo is not None

        gitcommit = gitbox.get_commit(gitrepo, result.vuln_commit_id)
        assert gitcommit is not None

        commit_msg = gitcommit.message
        out = f"output/{result.vuln_project_id}/{result.func_name}/{result.vuln_commit_id}.commit_msg"
        with open(out, 'w') as f:
            f.write(commit_msg)

        patch = gitbox.get_commit_patch(gitcommit)
        out = f"output/{result.vuln_project_id}/{result.func_name}/{result.vuln_commit_id}.patch"
        with open(out, 'w') as f:
            f.write(patch)
