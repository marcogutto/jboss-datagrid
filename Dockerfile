FROM registry.redhat.io/jboss-eap-7/eap73-openjdk8-openshift-rhel7

ENV JBOSS_HOME /opt/eap
ENV DEPLOY_DIR ${JBOSS_HOME}/standalone/deployments/

ENV DATAGRID_URL1 datagrid.url.1
ENV DATAGRID_URL2 datagrid.url.2

# create temporary deployment dir, because wars can deploy after the datasource is created
RUN mkdir /tmp/deploments
ENV DEPLOY_DIR /tmp/deploments

RUN mkdir /tmp/jboss-cli
ENV CLI_DIR /tmp/jboss-cli

COPY startSetup.sh $JBOSS_HOME/bin

USER root
RUN chown jboss:root $JBOSS_HOME/bin/startSetup.sh
RUN chmod 755 $JBOSS_HOME/bin/startSetup.sh
USER jboss

ENTRYPOINT $JBOSS_HOME/bin/startSetup.sh