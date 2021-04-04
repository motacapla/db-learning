# References
https://dev.mysql.com/doc/refman/5.6/ja/server-administration.html
https://dev.mysql.com/doc/refman/8.0/en/server-administration.html

# Logs
https://dev.mysql.com/doc/refman/8.0/en/server-logs.html

## Log maintenance
> FLUSH LOGS

If binary logging is enabled, the server closes the current binary log file and opens a new log file with the next sequence number.
If general query logging or slow query logging to a log file is enabled, the server closes and reopens the log file.
If the server was started with the --log-error option to cause the error log to be written to a file, the server closes and reopens the log file.

# User-Defined Functions
https://dev.mysql.com/doc/refman/8.0/en/server-udfs.html
