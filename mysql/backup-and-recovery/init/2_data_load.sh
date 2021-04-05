mysql -uroot -pblah --local-infile=1 tomoya -e "LOAD DATA LOCAL INFILE '/docker-entrypoint-initdb.d/data.csv' INTO TABLE pet FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\n' (name)"
