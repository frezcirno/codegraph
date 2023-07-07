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

import sys

dry_run = True
if len(sys.argv) > 1:
    dry_run = False

for project_id in os.listdir("output"):
    for func_name in os.listdir(f"output/{project_id}"):
        if func_name == 'bitcode':
            continue
        count = vul_db.execute("""
            SELECT COUNT(*)
            FROM combined_vuln_commit_functions
            WHERE project_id = %s
            AND func_name = %s
        """, (project_id, func_name))

        if count[0][0] == 0:
            logger.info(f"Deleting {project_id} {func_name}")
            if not dry_run:
                sp.call(f"mv output/{project_id}/{func_name} /tmp/{func_name}", shell=True)