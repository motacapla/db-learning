FROM mysql:8.0
EXPOSE 3306
ADD ./tomoya.cnf /etc/mysql/conf.d/tomoya.cnf
RUN mkdir /var/log/mysql
RUN chown mysql:mysql /var/log/mysql

CMD ["mysqld"]
