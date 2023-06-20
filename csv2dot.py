
import sys
import graphviz
import pandas as pd
import os

prelevel = int(os.environ.get('PRELEVEL', 3))
postlevel = int(os.environ.get('POSTLEVEL', 3))

def plot(edge_df, entry_sym, input_filename):
    dot = graphviz.Digraph(name=input_filename + "_" + entry_sym)

    flags = set()
    interests = set([entry_sym])
    for _ in range(prelevel):
        interest2 = set()
        has_next = False
        for interest in interests:
            for edge in edge_df[edge_df.referee==interest].itertuples():
                if edge.Index not in flags:
                    has_next = True
                    flags.add(edge.Index)
                    dot.edge(edge.referer, edge.referee)
                interest2.add(edge.referer)
        if not has_next:
            break
        interests = interest2

    interests = set([entry_sym])
    for _ in range(postlevel):
        interest2 = set()
        has_next = False
        for interest in interests:
            for edge in edge_df[edge_df.referer==interest].itertuples():
                if edge.Index not in flags:
                    has_next = True
                    flags.add(edge.Index)
                    dot.edge(edge.referer, edge.referee)
                interest2.add(edge.referee)
        if not has_next:
            break
        interests = interest2

    print(dot)


argv = sys.argv
if len(argv) < 3:
    print("Usage: python3 csv2dot.py <csv_file> <entry>")
    exit(1)

csv_file = argv[1]
entry = argv[2]

graph = pd.read_csv(csv_file, header=None, names=['type', 'referer', 'referee'])
plot(graph, entry, csv_file)
