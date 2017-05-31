\ REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) ords.*.zip
#     Download Oracle Rest Data Services from
#     http://www.oracle.com/technetwork/developer-tools/rest-data-services/downloads/index.html
#
# OPTIONS FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) sqlcl.*.zip
#     Download SQLcl from
#     http://www.oracle.com/technetwork/developer-tools/sqlcl/downloads/index.html
#
# (2) apex*.zip
#     Download SQLcl from
#     http://www.oracle.com/technetwork/developer-tools/apex/downloads/download-085147.html
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put the downloaded file in the same directory as this Dockerfile
#
#
# To Build:
#   Edit and Run:
#      $ docker build -t krisrice/ords:3.0.10  --build-arg DBHOST=192.168.3.119 --build-arg DBSERVICE=orcl --build-arg DBPORT=1521 --build-arg DBPASSWD=oracle  .
# To Run:
#      $ docker run -p 8888:8888 -p 8443:8443  -it krisrice/ords:3.0.10
#
# To Run with existing apex/images
#
#      $ docker run -p 8888:8888 -p 8443:8443  -v /Users/klrice/workspace/apex_trunk/images/:/opt/oracle/ords/doc_root/i  -it krisrice/ords:3.0.10
#
# Pull base image
# ---------------
FROM openjdk:8

ARG DBHOST
ARG DBPORT
ARG DBPASSWD
ARG DBSERVICE

# Maintainer
# ----------
MAINTAINER Kris Rice <kris.rice@jokr.net>

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV ORACLE_BASE=/opt/oracle \
    ORDS_HOME=/opt/oracle/ords \
    INSTALL_FILE="ords.*.zip" \
    SQLCL_FILE="sqlcl*.zip" \
    APEX_HOME=/opt/oracle/apex \
    APEX_FILE="apex*.zip" \
    CONFIG_PROPS="ords_params.properties" \
    STANDALONE_PROPS="standalone.properties" \
    RUN_FILE="runOrds.sh" \
    CONFIG_FILE="setupOrds.sh"

# Copy binaries
# -------------
COPY $INSTALL_FILE $SQLCL_FILE $CONFIG_PROPS $RUN_FILE $CONFIG_FILE $STANDALONE_PROPS $ORDS_HOME/
COPY $SQLCL_FILE $ORACLE_BASE/
COPY $APEX_FILE $ORACLE_BASE/

# Setup filesystem and oracle user
# Adjust file permissions, go to /opt/oracle as user 'oracle' to proceed with ORDS installation
# ------------------------------------------------------------
RUN mkdir -p $ORDS_HOME/config && \
    chmod ug+x $ORDS_HOME/$CONFIG_FILE  $ORDS_HOME/$RUN_FILE && \
    groupadd -g 500 dba && \
    useradd -d /home/oracle -g dba -m -s /bin/bash oracle && \
    echo oracle:oracle | chpasswd && \
    if [ -f $ORACLE_BASE/$SQLCL_FILE ]; then cd $ORACLE_BASE && jar -xf $ORACLE_BASE/$SQLCL_FILE &&  chmod 755 $ORACLE_BASE/sqlcl/bin/sql; rm $ORACLE_BASE/$SQLCL_FILE; fi && \
    if [ -f $ORACLE_BASE/$APEX_FILE ];  then cd $ORACLE_BASE && jar -xf $ORACLE_BASE/$APEX_FILE; rm $ORACLE_BASE/$APEX_FILE; fi && \
    cd $ORDS_HOME && \
    jar -xf $INSTALL_FILE && \
    rm $INSTALL_FILE && \
    $ORDS_HOME/$CONFIG_FILE && \
    chown -R oracle:dba $ORACLE_BASE


# Start installation
# -------------------
ENV PATH="${PATH}:$ORACLE_BASE/sqlcl/bin"

USER oracle

WORKDIR /home/oracle

EXPOSE 8888

VOLUME $ORDS_HOME/config

# Define default command to start Oracle Database.
CMD $ORDS_HOME/$RUN_FILE
