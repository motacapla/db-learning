# Optimizing SELECT Statements

- To make a slow SELECT ... WHERE query faster, the first thing to check is whether you can add an index.
Indexes are especially important for queries that reference different tables, using features such as joins and foreign keys. You can use the EXPLAIN statement to determine which indexes are used for a SELECT.
See Section 8.3.1, “How MySQL Uses Indexes” and Section 8.8.1, “Optimizing Queries with EXPLAIN”.
- Isolate and tune any part of the query, such as a function call, that takes excessive time.
- Minimize the number of full table scans in your queries, particularly for big tables.
- Keep table statistics up to date by using the ANALYZE TABLE statement periodically, so the optimizer has the information needed to construct an efficient execution plan.
- Learn the tuning techniques, indexing techniques, and configuration parameters that are specific to the storage engine for each table
See Section 8.5.6, “Optimizing InnoDB Queries” and Section 8.6.1, “Optimizing MyISAM Queries”.
- You can optimize single-query transactions for InnoDB tables, using the technique in Section 8.5.3, “Optimizing InnoDB Read-Only Transactions”.
- Avoid transforming the query in ways that make it hard to understand, especially if the optimizer does some of the same transformations automatically.
- If a performance issue is not easily solved by one of the basic guidelines, investigate the internal details of the specific query by reading the EXPLAIN plan and adjusting your indexes, WHERE clauses, join clauses, and so on. 
(When you reach a certain level of expertise, reading the EXPLAIN plan might be your first step for every query.)
- Adjust the size and properties of the memory areas that MySQL uses for caching.
- Deal with locking issues, where the speed of your query might be affected by other sessions accessing the tables at the same time.


## WHERE
The examples use SELECT statements, but the same optimizations apply for WHERE clauses in DELETE and UPDATE statements.

- Removal of unnecessary parentheses:
```
NG:
   ((a AND b) AND c OR (((a AND b) AND (c AND d))))
OK:
   (a AND b AND c) OR (a AND b AND c AND d)
```

- Constant folding:
```
NG:
   (a<b AND b=c) AND a=5
OK:
   b>5 AND b=c AND a=5
```

- Constant condition removal:
*In MySQL 8.0.14 and later, this takes place during preparation rather than during the optimization phase, which helps in simplification of joins.
```
NG:
   (b>=5 AND b=5) OR (b=6 AND 5=5) OR (b=7 AND 5=6)
OK:
   b=5 OR b=6
```
- Constant expressions used by indexes are evaluated only once

- Comparisons of columns of numeric types with constant values
```
NG:
  SELECT * FROM t WHERE c ≪ 256;
OK:
  SELECT * FROM t WHERE 1;
```

- COUNT(*) on a single table without a WHERE is retrieved directly from the table information for MyISAM and MEMORY tables.

- Early detection of invalid constant expressions. 
MySQL quickly detects that some SELECT statements are impossible and returns no rows.

- HAVING is merged with WHERE if you do not use GROUP BY or aggregate functions (COUNT(), MIN(), and so on).

- For each table in a join, a simpler WHERE is constructed to get a fast WHERE evaluation for the table and also to skip rows as soon as possible

- All constant tables are read first before any other tables in the query. A constant table is any of the following:
1. An empty table or a table with one row.
2. A table that is used with a WHERE clause on a PRIMARY KEY or a UNIQUE index, where all index parts are compared to constant expressions and are defined as NOT NULL.

All of the following tables are used as constant tables:
SELECT * FROM t WHERE primary_key=1;
SELECT * FROM t1,t2
  WHERE t1.primary_key=1 AND t2.primary_key=t1.id;

- If all columns in ORDER BY and GROUP BY clauses come from the same table, that table is preferred first when joining.

- If there is an ORDER BY clause and a different GROUP BY clause, or if the ORDER BY or GROUP BY contains columns from tables other than the first table in the join queue, a temporary table is created.

- If you use the SQL_SMALL_RESULT modifier, MySQL uses an in-memory temporary table.

- Each table index is queried, and the best index is used unless the optimizer believes that it is more efficient to use a table scan.

- In some cases, MySQL can read rows from the index without even consulting the data file. If all columns used from the index are numeric, only the index tree is used to resolve the query.

- Before each row is output, those that do not match the HAVING clause are skipped.


### Best practices
```
SELECT COUNT(*) FROM tbl_name;

SELECT MIN(key_part1),MAX(key_part1) FROM tbl_name;

SELECT MAX(key_part2) FROM tbl_name
  WHERE key_part1=constant;

SELECT ... FROM tbl_name
  ORDER BY key_part1,key_part2,... LIMIT 10;

SELECT ... FROM tbl_name
  ORDER BY key_part1 DESC, key_part2 DESC, ... LIMIT 10;
```

MySQL resolves the following queries using only the index tree, assuming that the indexed columns are numeric:
```
SELECT key_part1,key_part2 FROM tbl_name WHERE key_part1=val;

SELECT COUNT(*) FROM tbl_name
  WHERE key_part1=val1 AND key_part2=val2;

SELECT key_part2 FROM tbl_name GROUP BY key_part1;
```

The following queries use indexing to retrieve the rows in sorted order without a separate sorting pass:
```
SELECT ... FROM tbl_name
  ORDER BY key_part1,key_part2,... ;

SELECT ... FROM tbl_name
  ORDER BY key_part1 DESC, key_part2 DESC, ... ;
```

## Range 

