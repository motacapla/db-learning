CREATE DATABASE IF NOT EXISTS tomoya;

USE tomoya;

SET GLOBAL local_infile=1;

CREATE TABLE pet (
     id MEDIUMINT NOT NULL AUTO_INCREMENT,
     name CHAR(30) NOT NULL,
     PRIMARY KEY (id)
);
