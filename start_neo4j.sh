# make sure container name safe, only [a-zA-Z0-9][a-zA-Z0-9_.-] are allowed
FORMULA_NAME=$(sed -e 's/[^a-zA-Z0-9_.-]//g' <<< $(basename $1))

docker \
    run \
    --rm \
    --publish=7474:7474 \
    --publish=7687:7687 \
    --volume=$(realpath $1):/data \
    --name=neo4j-$FORMULA_NAME \
    --env=NEO4J_AUTH=none \
    ${@:2} \
    neo4j:5.10.0
    # neo4j:2.3.12

    # --env=NEO4J_ALLOW_STORE_UPGRADE=true \
    # --env=NEO4J_dbms_allow__upgrade=true \
    # --env=NEO4J_dbms_allow__format__migration=true \
    # --env=NEO4J_server_config_strict__validation_enabled=false \
    # --volume $(pwd)/xxx:/var/lib/neo4j/import