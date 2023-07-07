import sys
import os
import re
import graphviz
from graphviz import Digraph


def load_dotfile(dotfile):
    """Load a DOT file and return a list of nodes and a list of edges."""
    with open(dotfile, 'r') as f:
        lines = f.readlines()
    for line in lines:
        if line.startswith('digraph'):
            graph_name = line.split()[1].strip('"')
            break
    nodes = []
    edges = []

    for line in lines:
        if edge := re.findall(r'"?([\w\.]+)"?\s*->\s*"?([\w\.]+)"?', line):
            edge = edge[0]
            edges.append(edge)
        elif node := re.findall(r'"?([\w\.]+)"?\s*\[', line):
            node = node[0]
            nodes.append(node)

    # if some node is not in the node list, add it
    for edge in edges:
        if edge[0] not in nodes:
            nodes.append(edge[0])
        if edge[1] not in nodes:
            nodes.append(edge[1])

    return {'nodes': nodes, 'edges': edges, 'graph_name': graph_name}


def calculate_diff(dotfile1, dotfile2):
    """Calculate the difference between two DOT files."""

    graph1 = load_dotfile(dotfile1)
    graph2 = load_dotfile(dotfile2)

    diff_graph = Digraph(format='png', name=f"{graph1['graph_name']}__||__{graph2['graph_name']}")

    # Find nodes and edges that are in the first dot file but not in the second dot file
    for node in graph1['nodes']:
        if node not in graph2['nodes']:
            diff_graph.node(node, color='red')

    for edge in graph1['edges']:
        if edge not in graph2['edges']:
            diff_graph.edge(*edge, color='red')

    # Find nodes and edges that are in the second dot file but not in the first dot file
    for node in graph2['nodes']:
        if node not in graph1['nodes']:
            diff_graph.node(node, color='green')

    for edge in graph2['edges']:
        if edge not in graph1['edges']:
            diff_graph.edge(*edge, color='green')

    # Find nodes and edges that are in both dot files
    for node in graph1['nodes']:
        if node in graph2['nodes']:
            diff_graph.node(node)

    for edge in graph1['edges']:
        if edge in graph2['edges']:
            diff_graph.edge(*edge)

    return diff_graph


if __name__ == '__main__':
    # Check the command-line arguments
    if len(sys.argv) < 3:
        print('Usage: dotdiff.py <dotfile1> <dotfile2>')
        sys.exit(1)

    dotfile1 = sys.argv[1]
    dotfile2 = sys.argv[2]

    graph = calculate_diff(dotfile1, dotfile2)

    print(graph)
