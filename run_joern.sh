#!/bin/bash
# usage: $0 project_src revision
set -e -o pipefail # exit on error

DIR=$(dirname $0)
SRC=$(realpath $1)
REV=$2
PROJECT=$(basename $SRC)
NEO4J_OUTPUT=$DIR/${PROJECT}_${REV}
mkdir -p $NEO4J_OUTPUT

TMP_SRC=$(mktemp -d || exit -1)
echo "Copying source code to $TMP_SRC"

pushd $SRC || exit -1
git restore --staged .
git restore .
git clean -dfx
git checkout $REV

find . \
    -type f \
    -regextype posix-extended \
    -regex '.*\.(c|h|cc|hh|cpp|cxx|hpp)' \
    -not -path '*/samples/*' \
    -not -path '*/testing/*' \
    -not -path '*/test/*' \
    -not -path '*/Documentation/*' \
    -size -450k \
    -exec sh -c "dst=\"$TMP_SRC/{}\"; mkdir -p \$(dirname \$dst); echo {}; cp {} \$dst" \;
popd || exit -1

TMP_WORKSPACE=$(mktemp -d || exit -1)

pushd $TMP_WORKSPACE || exit -1
mkdir workspace
echo "Output cpg to $TMP_WORKSPACE"
joern-parse $TMP_SRC && rm -rf $TMP_SRC

echo "Exporting cpg as neo4j csv to $TMP_EXPORTED"
joern-export -o all_neo4jcsv --repr all --format neo4jcsv cpg.bin && rm -rf cpg.bin
pushd all_neo4jcsv || exit -1
nodes=$(ls nodes_*_data.csv)
edges=$(ls edges_*_data.csv)
for node in $nodes; do
    node_header=$(echo $node | sed 's/data/header/')
    params="--nodes $node_header,$node $params"
done
for edge in $edges; do
    edge_header=$(echo $edge | sed 's/data/header/')
    params="--relationships $edge_header,$edge $params"
done
popd || exit -1
popd || exit -1

echo "Starting neo4j at $NEO4J_OUTPUT"
container_id=$(./start_neo4j.sh $NEO4J_OUTPUT --volume $TMP_WORKSPACE/all_neo4jcsv:/var/lib/neo4j/import -d)

echo "Container id: $container_id"

sleep 5

echo "Importing cpg to neo4j"
docker exec $container_id /bin/bash -c "cd /var/lib/neo4j/import \
&& neo4j-admin database import full --overwrite-destination --multiline-fields=true $params" &&
    sudo rm -rf $TMP_WORKSPACE

echo "Stopping neo4j"
docker stop $container_id

echo "Done. Neo4j database is located at $NEO4J_OUTPUT"
