#!/bin/sh

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script assumes that it is being run from the top level directory of the
# HCatalog distribution tarball

function usage() {
    echo "Usage: $0 -r root -d dbroot -h hadoop_home -p server_port"
    echo "    root is the directory where you like to install the HCatalog server"
    echo "        /usr/local/hcat is suggested."
    echo "    dbroot is the directory where your mysql connector jar is located."
    echo "    hadoop_home is the directory of your Hadoop installation."
    echo "    server_port is the listening port of the HCatalog server"
    echo "    All paths must be absolute"
}

dir_check=`head -1 NOTICE.txt`
if [ "${dir_check}" != "Apache HCatalog" ] ; then
    echo "This script must be run in the top level directory of your HCatalog" \
        "distribution."
    exit 1
fi

root="unknown"
dbroot="unknown"
hadoop_home="unknown"
server_port="9080"

while [ "${1}x" != "x" ] ; do
    if [ $1 == "-r" ] || [ $1 == "--root" ] ; then
        shift
        root=$1
        shift
    elif [ $1 == "-d" ] || [ $1 == "--dbroot" ] ; then
        shift
        dbroot=$1
        shift
    elif [ $1 == "-h" ] || [ $1 == "--hadoop" ] ; then
        shift
        hadoop_home=$1
        shift
    elif [ $1 == "-p" ] || [ $1 == "--port" ] ; then
        shift
        server_port=$1
        shift
    else
        echo "Unknown option $1"
        shift
    fi

done

for var in $root $dbroot $hadoop_home ; do
    if [ $var == "unknown" ] ; then
        usage
        exit 1
    fi
done

# Make sure root and dbroot are absolute paths

for var in $root $dbroot $hadoop_home ; do
    if [ ${var:0:1} != "/" ] ; then
        usage
        exit 1
    fi
done

# Make sure root is writable and has the necessary directories
root_owner=`ls -ld $root | awk '{print $3}'`
if [ $root_owner != `whoami` ] ; then
    echo "You must run this as the user that will run HCatalog and that user" \
        "must own the root directory."
    exit 1
fi

root_perms=`ls -ld $root | awk '{print $1}'`
if [ ${root_perms:0:4} != "drwx" ] ; then
    echo "Your root directory must be readable, writable, and executable by" \
        "its owner."
    exit 1
fi

# Check that the required Mysql driver is in the dbroot
mysql_jar=`ls ${dbroot}/mysql-connector-java-*.jar 2>/dev/null | grep mysql-connector-java`
if [ "${mysql_jar}x" == "x" ] ; then
    echo "The required jar file mysql-connector-java-version.jar is not in " \
        "$dbroot or is not readable"
    exit 1
fi

# Create the needed directories in root
for dir in var conf var/log bin lib ; do
    if [ ! -d $root/$dir ] ; then
        mkdir $root/$dir
    fi
done

# Move files into the appropriate directories
for dir in bin conf lib ; do
    for file in ./$dir/* ; do
        cp -R $file $root/$dir
    done
done

# Put the start and stop scripts into bin
for file in hcat_server_start.sh hcat_server_stop.sh ; do
	cp scripts/$file $root/bin
done

# Move the proto-hive-site.xml to hive-site.xml
cp $root/conf/proto-hive-site.xml $root/conf/hive-site.xml

# Set permissions on hive-site.xml to 700, since it will contain the password to the 
# database
chmod 700 $root/conf/hive-site.xml

# Write out an environment file so that the start file can use it later
cat > $root/conf/hcat-env.sh <<!!
ROOT=$root
DBROOT=$dbroot
USER=`whoami`
HADOOP_HOME=$hadoop_home
export METASTORE_PORT=$server_port
!!

echo "Installation successful"



    
