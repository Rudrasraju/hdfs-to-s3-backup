#! /bin/bash
##variable
#############################################################################################
#HdfsPath="datalake_dev"
s3_access_key="<s3_access_key>"
s3_secret_key="<s3_secret_key>"
s3_location="<s3 bucket>/<folder path>/"

user="hdfs"   ## user who can execute hadoop command - For ex. on an ec2 POC instance, use ec2-user or hdfs

TIME=`/bin/date +%d-%m-%Y_%H-%M-%S`
################################################################
###ensure only one instance of distcp is running...
###############################################################################################
LOCKFILE=/tmp/lock.txt
if [ -e ${LOCKFILE} ] && kill -0 `cat ${LOCKFILE}`; then   ##check pid of last distcp
    echo "already running"
    exit
fi

# make sure the lockfile is removed when we exit ( ex. kill -9 on last distcp )
trap "rm -f ${LOCKFILE}; exit" INT TERM EXIT
echo $$ > ${LOCKFILE}

##############################################################################################
###check if you can execute hdfs  command
isBinaryAccessible=`which hdfs > /dev/null 2>&1`
status=$?
if [ $status -ne 0 ]; then
    echo "Could not locate hdfs executable. Please set HADOOP_HOME properly or add hdfs binary in your default PATH"
    exit 1
fi

###############################################################################################
##Find Active NameNode Name in HA Cluster
haClusterName=`hdfs getconf -confKey dfs.nameservices`
if [ $? -ne 0 -o -z "$haClusterName" ]; then
    echo "Unable to fetch HA ClusterName"
    exit 1
fi
nameNodeIdString=`hdfs getconf -confKey dfs.ha.namenodes.$haClusterName`
for nameNodeId in `echo $nameNodeIdString | tr "," " "`
do
    status=`hdfs haadmin -getServiceState $nameNodeId`
  if [ $status = "active" ]; then
    #if [  = "active" ]; then
        nameNode=`hdfs getconf -confKey dfs.namenode.https-address.$haClusterName.$nameNodeId`
        ActiveNameNode=`echo $nameNode|cut -d":" -f1`
    fi
done
##################################################################################################
###backup hdfs from CDH to s3
##################################################################################################
#su $user -c "hadoop distcp -Dfs.s3a.access.key="$s3_access_key" -Dfs.s3a.secret#.key="$s3_secret_key" hdfs://$ActiveNameNode/$HdfsPath s3a://"$s3_location""
#rm -f ${LOCKFILE}

#hadoop distcp -Dfs.s3a.access.key="$s3_access_key" -Dfs.s3a.secret.key="$s3_secret_key" hdfs://$ActiveNameNode/<folder-path> s3a://"$s3_location/$TIME/"
################################################################
