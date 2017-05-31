#!/bin/bash
#
# simple function to replace strings in param files
function replace(){
   FROM=$1
   TO=$2
   IN=$3
   sed -i -e "s|###${FROM}###|${TO}|g" $IN
}

function setupAPEX(){
  if [ -f $APEX_HOME/apexins.sql ]; then
    echo "#####################"
    echo "INSTALLING APEX..."
    echo "#####################"

  # setup apex images for the ords install
  APEXI=$APEX_HOME/images

  cd $APEX_HOME
  # setting passwords to abc xyz since setupORDS scrambles them
/opt/oracle/sqlcl/bin/sql /nolog <<EOF
conn SYS/$DBPASSWD@//$DBHOST:$DBPORT/$DBSERVICE as sysdba
@apexins SYSAUX SYSAUX TEMP /i/
@apex_rest_config_core.sql abc xyz
EOF
fi;
  cd -
}

function setupOrds() {

   # Default for $ORDS_TS_DEFAULT SID
   if [ "$ORDS_TS_DEFAULT" == "" ]; then
      export ORDS_TS_DEFAULT=SYSAUX
   fi;

   # Default for ORDS_TS_TEMP
   if [ "$ORDS_TS_TEMP" == "" ]; then
      export ORDS_TS_TEMP=TEMP
   fi;

   # Replace variables
   replace "DBHOST" "$DBHOST" "$ORDS_HOME/$CONFIG_PROPS"
   replace "DBPORT" "$DBPORT" "$ORDS_HOME/$CONFIG_PROPS"
   replace "DBPASSWD" "$DBPASSWD" "$ORDS_HOME/$CONFIG_PROPS"
   replace "DBSERVICE" "$DBSERVICE" "$ORDS_HOME/$CONFIG_PROPS"

   # Create config directory
   java -jar $ORDS_HOME/ords.war configdir $ORDS_HOME/config

   mkdir -p $ORDS_HOME/config/ords/standalone

   mkdir -p  $ORDS_HOME/doc_root

   # Randomize the password for all the ORDS connection pool accounts
   PASSWD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 28 | head -n 1)
   /opt/oracle/sqlcl/bin/sql /nolog <<EOF
conn SYS/$DBPASSWD@//$DBHOST:$DBPORT/$DBSERVICE as sysdba
alter user APEX_LISTENER account unlock identified by "$PASSWD";
alter user APEX_PUBLIC_USER account unlock identified by "$PASSWD";
alter user APEX_REST_PUBLIC_USER account unlock identified by "$PASSWD";
alter user ORDS_PUBLIC_USER account unlock identified by "$PASSWD";
EOF

  replace "RANDOMPASSWD" "$PASSWD" "$ORDS_HOME/$CONFIG_PROPS"


   cp $ORDS_HOME/$STANDALONE_PROPS $ORDS_HOME/config/ords/standalone
   # Replace in standalone file
   # set the port to 8888
   if [ "$PORT" == "" ]; then
      PORT=8888
   fi;
   if [ "$SPORT" == "" ]; then
      SPORT=8443
   fi;
   replace "PORT"  "$PORT" "$ORDS_HOME/config/ords/standalone/$STANDALONE_PROPS"
   replace "SPORT" "$SPORT" "$ORDS_HOME/config/ords/standalone/$STANDALONE_PROPS"

   # Doc root to host static files
   replace "DOCROOT" "$ORDS_HOME/doc_root" "$ORDS_HOME/config/ords/standalone/$STANDALONE_PROPS"

   # If no APEXI passed in make it the doc_root/i
   if [ "$APEXI" == "" ]; then
      APEXI="$ORDS_HOME/doc_root/i"
   fi;

   replace "APEXI" "$APEXI" "$ORDS_HOME/config/ords/standalone/$STANDALONE_PROPS"

   # Copy config file into place
   cp $ORDS_HOME/$CONFIG_PROPS $ORDS_HOME/params/

   # Start ODRDS setup
   java -jar $ORDS_HOME/ords.war install simple

   echo Setup
}

########### SIGTERM handler ############
function _term() {
   echo "Stopping container."
   echo "SIGTERM received, shutting down ORDS!"
   pkill ords;
}

########### SIGKILL handler ############
function _kill() {
   echo "SIGKILL received, shutting down ORDS!"
   pkill -9 ords;
}

############# MAIN ################

# Set SIGTERM handler
trap _term SIGTERM

# Set SIGKILL handler
trap _kill SIGKILL

# Check whether ords is already setup
if [ "$DBHOST" != "" ]; then
   setupAPEX;
   setupOrds;
fi;
echo "#####################"
echo "ORDS IS Configured!"
echo "#####################"


# tail -f $ORDS_HOME/logs/*.log &
#childPID=$!
#wait $childPID
