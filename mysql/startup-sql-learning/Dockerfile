FROM mysql:8.0
EXPOSE 3306
ADD ./tomoya.cnf /etc/mysql/conf.d/tomoya.cnf
COPY ./init/* /docker-entrypoint-initdb.d/
CMD ["mysqld"]
