# docker-ords-sqlcl-apex
Build scripts to make a docker image with Oracle REST Data Services, Oracle SQLcl, and Oracle Application Express


# Prerequisites

Download from OTN ORDS 


Required: [Download ORDS](http://www.oracle.com/technetwork/developer-tools/rest-data-services/downloads/index.html)

Optional SQLcl: [Download SQLcl](http://www.oracle.com/technetwork/developer-tools/sqlcl/downloads/index.html)
    
Optional APEX:    [Download APEX](http://www.oracle.com/technetwork/developer-tools/apex/downloads/download-085147.html)
    


# Build Process

The docker build is parameterized to allow the database to reside anywhere.
Build Parameters

	DBHOST    : IP Address of the database host
	DBSERVICE : DB Service name to connect
	DBPORT    : DB Port to connect
	DBPASSWD  : SYS password

Optional

	PORT  : HTTP Port for ORDS (Default: 8888)
	SPORT : HTTPS Port for ORDS (Default: 8443)
	APEXI : path to the apex images folder INSIDE the doc


# Example Build    
```
docker build -t krisrice/ords:3.0.10  --build-arg DBHOST=192.168.3.119 --build-arg DBSERVICE=orcl --build-arg DBPORT=1521 --build-arg DBPASSWD=oracle  .
```

# Run the docker

Once the image is built, use docker run. Being sure to port forward the ports specified to be accesible.

In this case, the default, Forward 8888 and 8433


```
docker run -p 8888:8888 -p 8443:8443 -it krisrice/ords:3.0.10

```

## Docker image layout and env

All the software is installed in the image in /opt/oracle
```
$ ls -ltr
drwxr-xr-x 4 oracle dba     4096 May 31 19:58 sqlcl
drwxr-xr-x 6 oracle dba     4096 May 31 19:58 apex
drwxr-xr-x 1 oracle dba     4096 May 31 19:58 ords

```

## Bash Env variables

SQLcl is added to the PATH

There are some variables in the env for reference use

```
$ env | sort
APEX_FILE=apex*.zip
APEX_HOME=/opt/oracle/apex
CONFIG_FILE=setupOrds.sh
CONFIG_PROPS=ords_params.properties
INSTALL_FILE=ords.*.zip
ORACLE_BASE=/opt/oracle
ORDS_HOME=/opt/oracle/ords
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/oracle/sqlcl/bin
RUN_FILE=runOrds.sh
SQLCL_FILE=sqlcl*.zip
STANDALONE_PROPS=standalone.properties
```
    

## Serve files in the DOC ROOT from the host

Using the -v command docker can map a filesystem from the host into the image.  This would allow for serving host files as part of the ORDS docroot
```
docker run -p 8888:8888 -p 8443:8443  -v /Users/klrice/workspace/apex_trunk/images/:/opt/oracle/ords/doc_root/i  -it krisrice/ords:3.0.10

```
