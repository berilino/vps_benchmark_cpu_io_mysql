#!/bin/bash

# Package sources update
apt-get update

sleep 5s

# mysql install and set root password to 123PAssword
debconf-set-selections <<< 'mysql-server mysql-server/root_password password 123PAssword'
sleep 1s
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password 123PAssword'
sleep 1s
apt-get -y install mysql-server

sleep 5s

# Installation of Sysench - benchmarking tool
apt-get install sysbench

sleep 1s

# create directory for logs
mkdir /root/sysbench_log/

# Create directory for CPU logs
mkdir /root/sysbench_log/cpu/

echo "Starting CPU test"

# 10x CPU test for up to 20 threads
for i in `seq 1 10`;
    do
        echo "test cpu $i"
        sysbench --test=cpu --cpu-max-prime=20000 --num-threads=2 run > /root/sysbench_log/cpu/$i.log
    done

    echo "CPU test finished"

# Create directory for I/O logs
mkdir /root/sysbench_log/io/

# Create 500MB sample file fot I/O test
sysbench --test=fileio --file-total-size=500M prepare

echo "Starting IO test"

# 10x I/O test
for i in `seq 1 10`;
    do
        echo "IO test $i"
        sysbench --test=fileio --file-total-size=500M --file-test-mode=rndrw --init-rng=on --max-time=300 --max-requests=0 run > /root/sysbench_log/io/$i.log
    done

    echo "IO test finished"

# Remove sample file
sysbench --test=fileio --file-total-size=500M cleanup

echo "Starting MySQL test"

# Create database
mysql -uroot -p123PAssword -e 'CREATE DATABASE test;' 

# Create directory for MySQL test logs
mkdir /root/sysbench_log/mysql/

# Creation of sample record in test database 
sysbench --test=oltp --oltp-table-size=1000000 --mysql-db=test --mysql-user=root --mysql-password=123PAssword prepare

# 10x MySQL test
for i in `seq 1 10`;
    do
        echo "MySQL test $i"
        sysbench --test=oltp --oltp-table-size=1000000 --mysql-db=test --mysql-user=root --mysql-password=123PAssword --max-time=60 --oltp-read-only=on --max-requests=0 --num-threads=8 run > /root/sysbench_log/mysql/$i.log
    done

    echo "MySQL test finished"

# Remove sample records form test database
sysbench --test=oltp --mysql-db=test --mysql-user=root --mysql-password=123PAssword cleanup

echo "All test finished. Check results at /root/sysbench_log/"
