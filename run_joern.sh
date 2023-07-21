#!/bin/bash
# usage: $0 project_src revision
DIR=$(dirname $0)
SRC=$(realpath $1)
REV=$2
OUTPUT=$(realpath ./$1_$REV)


WORKSPACE=$(mktemp -d)
echo "Copying source code to $WORKSPACE"

pushd $SRC
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
        -exec sh -c "dst=\"$WORKSPACE/{}\"; mkdir -p \$(dirname \$dst); echo {}; cp {} \$dst" \;
popd

rm -rf $OUTPUT
$DIR/octopus-joern/joern-parse -outformat neo4j -outdir $OUTPUT $WORKSPACE
rm -rf $WORKSPACE

mkdir -p $OUTPUT/graph.db && mv $OUTPUT/* $OUTPUT/graph.db/

