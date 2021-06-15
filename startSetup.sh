#!/bin/bash

if [ ! -f jboss.started ]; then
JBOSS_CLI=$JBOSS_HOME/bin/jboss-cli.sh

function wait_for_server() {
  until `$JBOSS_CLI -c "ls /deployment" &> /dev/null`; do
    echo "Waiting"
    sleep 1
  done
}

echo "=> Starting WildFly server"
$JBOSS_HOME/bin/standalone.sh -b=0.0.0.0 -c standalone-openshift.xml > /dev/null &

echo "=> Waiting for the server to boot"
wait_for_server

echo "=> Setup Datagrid Host"
$JBOSS_CLI -c << EOF
batch
# Add Datagrid Configuration
/socket-binding-group=standard-sockets/remote-destination-outbound-socket-binding=remote-rhdg-server1:add(host=$DATAGRID_URL1, port=11222)
/socket-binding-group=standard-sockets/remote-destination-outbound-socket-binding=remote-rhdg-server2:add(host=$DATAGRID_URL2, port=11222)
# Execute the batch
run-batch
EOF

echo "=> Remote Cache Container"
$JBOSS_CLI -c << EOF
batch
# Add Remote Cache Container
/subsystem=infinispan/cache-container=web/invalidation-cache=rhdg:add(mode=SYNC)
/subsystem=infinispan/cache-container=web/invalidation-cache=rhdg/component=locking:write-attribute(name=isolation,value=REPEATABLE_READ)
/subsystem=infinispan/cache-container=web/invalidation-cache=rhdg/component=transaction:write-attribute(name=mode,value=BATCH)
/subsystem=infinispan/cache-container=web/invalidation-cache=rhdg/store=remote:add(remote-servers=["remote-rhdg-server1","remote-rhdg-server2"], cache=default, socket-timeout=60000, passivation=false, purge=false, shared=true)
# Execute the batch
run-batch
EOF

FILES=$CLI_DIR/*.cli
for f in $FILES
do
  echo "Processing $f file..."
  $JBOSS_CLI -c --file=$f
done

echo "=> Shutdown JBoss"
$JBOSS_CLI -c ":shutdown"

echo "=> DEPLOY WARs"
cp ${DEPLOY_DIR}/* ${JBOSS_HOME}/standalone/deployments/

touch jboss.started
fi

echo "=> Start JBoss"
$JBOSS_HOME/bin/standalone.sh -b=0.0.0.0 -c standalone-openshift.xml