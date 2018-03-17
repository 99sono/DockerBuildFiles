https://hub.docker.com/r/sath89/oracle-12c/

docker pull sath89/oracle-12c


docker run -d -p 8080:8080 -p 1521:1521 sath89/oracle-12c
Run with data on host and reuse it:

docker run -d -p 8080:8080 -p 1521:1521 -v /my/oracle/data:/u01/app/oracle sath89/oracle-12c
Run with Custom DBCA_TOTAL_MEMORY (in Mb):

docker run -d -p 8080:8080 -p 1521:1521 -v /my/oracle/data:/u01/app/oracle -e DBCA_TOTAL_MEMORY=1024 sath89/oracle-12c


username: system
password: oracle
Password for SYS & SYSTEM: