import sys
from gitbox import vul_db
from loguru import logger
import subprocess as sp
import pandas as pd

clone_detection_result = vul_db.execute("""
    SELECT id,
           project_id, revision, func_name,
           vuln_project_id, vuln_commit_id, vuln_func_name
    FROM clone_detection_result
    WHERE project_id IN ('ffmpeg', 'openssl', 'php-src', 'imagemagick', 'linux', 'qemu', 'redis')
""")

clone_detection_result = pd.DataFrame(
    clone_detection_result, columns=[
        'id',
        'project_id', 'revision', 'func_name',
        'vuln_project_id', 'vuln_commit_id', 'vuln_func_name'
    ])


def subcall(cmd):
    logger.info(cmd)
    rv = sp.call(cmd, shell=True, stdout=sp.DEVNULL, stderr=sp.DEVNULL)
    if rv != 0:
        logger.error(f"Failed to execute {cmd}, {rv}")


def make_graph(project_id):
    data = clone_detection_result[clone_detection_result.project_id == project_id]
    l = {}
    tasks = []
    for task in data.itertuples():
        l.setdefault(task.revision, []).append(task)
    while True:
        found = 0
        for revision in l.keys():
            if l[revision]:
                tasks.append(l[revision].pop())
                found = 1
        if not found:
            break
    print(tasks)
    for task in tasks:
        subcall(f"make PROJECT={project_id} REVISION={task.vuln_commit_id}^ REVISION2={task.revision} ENTRY={task.vuln_func_name} diff")


if len(sys.argv) > 1:
    make_graph(sys.argv[1])
else:
    # with mp.Pool(2) as pool:
    #     pool.map(make_graph, clone_detection_result.project_id.unique())
    for project_id in clone_detection_result.project_id.unique():
        make_graph(project_id)
