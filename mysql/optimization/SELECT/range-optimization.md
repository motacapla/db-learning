# Range Optimization
The range access method uses a single index to retrieve a subset of table rows that are contained within one or several index value intervals.
## Range Access Method for Single-Part Indexes
- For a single-part index, index value intervals can be conveniently represented by corresponding conditions in the WHERE clause, denoted as range conditions rather than “intervals.”

The definition of a range condition for a single-part index is as follows:
1. For both BTREE and HASH indexes, comparison of a key part with a constant value is a range condition when using the =, <=>, IN(), IS NULL, or IS NOT NULL operators.
2. Additionally, for BTREE indexes, comparison of a key part with a constant value is a range condition when using the >, <, >=, <=, BETWEEN, !=, or <> operators, or LIKE comparisons if the argument to LIKE is a constant string that does not start with a wildcard character.
3. For all index types, multiple range conditions combined with OR or AND form a range condition.

“Constant value” in the preceding descriptions means one of the following:
1. A constant from the query string
2. A column of a const or system table from the same join
3. The result of an uncorrelated subquery
4. Any expression composed entirely from subexpressions of the preceding types

Examples in the WHERE clause:
```
SELECT * FROM t1
  WHERE key_col > 1
  AND key_col < 10;

SELECT * FROM t1
  WHERE key_col = 1
  OR key_col IN (15,18,20);

SELECT * FROM t1
  WHERE key_col LIKE 'ab%'
  OR key_col BETWEEN 'bar' AND 'foo';
```

MySQL tries to extract range conditions from the WHERE clause for each of the possible indexes.
During the extraction process, conditions that cannot be used for constructing the range condition are dropped, conditions that produce overlapping ranges are combined, and conditions that produce empty ranges are removed.

Consider the following statement, where key1 is an indexed column and nonkey is not indexed:
```
SELECT * FROM t1 WHERE
  (key1 < 'abc' AND (key1 LIKE 'abcde%' OR key1 LIKE '%b')) OR
  (key1 < 'bar' AND nonkey = 4) OR
  (key1 < 'uux' AND key1 > 'z');
```

The extraction process for key key1 is as follows:
1. Start with original WHERE clause:
```
(key1 < 'abc' AND (key1 LIKE 'abcde%' OR key1 LIKE '%b')) OR
(key1 < 'bar' AND nonkey = 4) OR
(key1 < 'uux' AND key1 > 'z')
```

2. Remove nonkey = 4 and key1 LIKE '%b' because they cannot be used for a range scan. 
The correct way to remove them is to replace them with TRUE, so that we do not miss any matching rows when doing the range scan. Replacing them with TRUE yields:
```
(key1 < 'abc' AND (key1 LIKE 'abcde%' OR TRUE)) OR
(key1 < 'bar' AND TRUE) OR
(key1 < 'uux' AND key1 > 'z')
```

3. Collapse conditions that are always true or false:
(key1 LIKE 'abcde%' OR TRUE) is always true
(key1 < 'uux' AND key1 > 'z') is always false

Replacing these conditions with constants yields:
```
(key1 < 'abc' AND TRUE) OR (key1 < 'bar' AND TRUE) OR (FALSE)
```

Removing unnecessary TRUE and FALSE constants yields:
```
(key1 < 'abc') OR (key1 < 'bar')
```

4. Combining overlapping intervals into one yields the final condition to be used for the range scan:
```
(key1 < 'bar')
```

In general (and as demonstrated by the preceding example), the condition used for a range scan is less restrictive than the WHERE clause. 
MySQL performs an additional check to filter out rows that satisfy the range condition but not the full WHERE clause.

## Range Access Method for Multiple-Part Indexes
Range conditions on a multiple-part index are an extension of range conditions for a single-part index.

For example, consider a multiple-part index defined as key1(key_part1, key_part2, key_part3), and the following set of key tuples listed in key order:
```
key_part1  key_part2  key_part3
  NULL       1          'abc'
  NULL       1          'xyz'
  NULL       2          'foo'
   1         1          'abc'
   1         1          'xyz'
   1         2          'abc'
   2         1          'aaa'
```

The condition key_part1 = 1 defines this interval:
```
(1,-inf,-inf) <= (key_part1,key_part2,key_part3) < (1,+inf,+inf)
```
The interval covers the 4th, 5th, and 6th tuples in the preceding data set and can be used by the range access method.

By contrast, the condition key_part3 = 'abc' does not define a single interval and cannot be used by the range access method.

The following descriptions indicate how range conditions work for multiple-part indexes in greater detail.
1. For HASH indexes, each interval containing identical values can be used. This means that the interval can be produced only for conditions in the following form:
```
    key_part1 cmp const1
AND key_part2 cmp const2
AND ...
AND key_partN cmp constN;
```

Here, const1, const2, … are constants, cmp is one of the =, <=>, or IS NULL comparison operators, and the conditions cover all index parts. 
(That is, there are N conditions, one for each part of an N-part index.) 
For example, the following is a range condition for a three-part HASH index:
```
key_part1 = 1 AND key_part2 IS NULL AND key_part3 = 'foo'
```

2. For a BTREE index, an interval might be usable for conditions combined with AND, where each condition compares a key part with a constant value using =, <=>, IS NULL, >, <, >=, <=, !=, <>, BETWEEN, or LIKE 'pattern' (where 'pattern' does not start with a wildcard).

The optimizer attempts to use additional key parts to determine the interval as long as the comparison operator is =, <=>, or IS NULL. 
If the operator is >, <, >=, <=, !=, <>, BETWEEN, or LIKE, the optimizer uses it but considers no more key parts.
For the following expression, the optimizer uses = from the first comparison. It also uses >= from the second comparison but considers no further key parts and does not use the third comparison for interval construction:
```
key_part1 = 'foo' AND key_part2 >= 10 AND key_part3 > 10
```

The single interval is:
```
('foo',10,-inf) < (key_part1,key_part2,key_part3) < ('foo',+inf,+inf)
```
It is possible that the created interval contains more rows than the initial condition. For example, the preceding interval includes the value ('foo', 11, 0), which does not satisfy the original condition.

If conditions that cover sets of rows contained within intervals are combined with OR, they form a condition that covers a set of rows contained within the union of their intervals. 

If the conditions are combined with AND, they form a condition that covers a set of rows contained within the intersection of their intervals. For example, for this condition on a two-part index:
```
(key_part1 = 1 AND key_part2 < 2) OR (key_part1 > 5)
```

The intervals are:
```
(1,-inf) < (key_part1,key_part2) < (1,2)
(5,-inf) < (key_part1,key_part2)
```

In this example, the interval on the first line uses one key part for the left bound and two key parts for the right bound. 
The interval on the second line uses only one key part. The key_len column in the EXPLAIN output indicates the maximum length of the key prefix used.

In some cases, key_len may indicate that a key part was used, but that might be not what you would expect. Suppose that key_part1 and key_part2 can be NULL. Then the key_len column displays two key part lengths for the following condition:
```
key_part1 >= 1 AND key_part2 < 2
```

But, in fact, the condition is converted to this:
```
key_part1 >= 1 AND key_part2 IS NOT NULL
```
## Equality Range Optimization of Many-Valued Comparisons
```
col_name IN(val1, ..., valN)
col_name = val1 OR ... OR col_name = valN
```
Each expression is true if col_name is equal to any of several values.
The optimizer estimates the cost of reading qualifying rows for equality range comparisons as follows:
1. If there is a unique index on col_name, the row estimate for each range is 1 because at most one row can have the given value.
2. Otherwise, any index on col_name is nonunique and the optimizer can estimate the row count for each range using dives into the index or index statistics.

## Skip Scan Range Access Method
```
CREATE TABLE t1 (f1 INT NOT NULL, f2 INT NOT NULL, PRIMARY KEY(f1, f2));
INSERT INTO t1 VALUES
  (1,1), (1,2), (1,3), (1,4), (1,5),
  (2,1), (2,2), (2,3), (2,4), (2,5);
INSERT INTO t1 SELECT f1, f2 + 5 FROM t1;
INSERT INTO t1 SELECT f1, f2 + 10 FROM t1;
INSERT INTO t1 SELECT f1, f2 + 20 FROM t1;
INSERT INTO t1 SELECT f1, f2 + 40 FROM t1;
ANALYZE TABLE t1;

EXPLAIN SELECT f1, f2 FROM t1 WHERE f2 > 40;
```
To execute this query, MySQL can choose an index scan to fetch all rows (the index includes all columns to be selected), then apply the f2 > 40 condition from the WHERE clause to produce the final result set.

A range scan is more efficient than a full index scan, but cannot be used in this case because there is no condition on f1, the first index column. 
However, as of MySQL 8.0.13, the optimizer can perform multiple range scans, one for each value of f1, using a method called Skip Scan that is similar to Loose Index Scan (see Section 8.2.1.17, “GROUP BY Optimization”):
1. Skip between distinct values of the first index part, f1 (the index prefix).
2. Perform a subrange scan on each distinct prefix value for the f2 > 40 condition on the remaining index part.

## Range Optimization of Row Constructor Expressions
The optimizer is able to apply the range scan access method to queries of this form:
```
SELECT ... FROM t1 WHERE ( col_1, col_2 ) IN (( 'a', 'b' ), ( 'c', 'd' ));
```

Previously, for range scans to be used, it was necessary to write the query as:
```
SELECT ... FROM t1 WHERE ( col_1 = 'a' AND col_2 = 'b' )
OR ( col_1 = 'c' AND col_2 = 'd' );
```

For the optimizer to use a range scan, queries must satisfy these conditions:
- Only IN() predicates are used, not NOT IN().
- On the left side of the IN() predicate, the row constructor contains only column references.
- On the right side of the IN() predicate, row constructors contain only runtime constants, which are either literals or local column references that are bound to constants during execution.
- On the right side of the IN() predicate, there is more than one row constructor.

## Limiting Memory Use for Range Optimization
- A value of 0 means “no limit.”
- With a value greater than 0, the optimizer tracks the memory consumed when considering the range access method. 
If the specified limit is about to be exceeded, the range access method is abandoned and other methods, including a full table scan, are considered instead. This could be less optimal. If this happens, the following warning occurs (where N is the current range_optimizer_max_mem_size value):
```
Warning    3170    Memory capacity of N bytes for
                   'range_optimizer_max_mem_size' exceeded. Range
                   optimization was not done for this query.
```
- For UPDATE and DELETE statements, if the optimizer falls back to a full table scan and the sql_safe_updates system variable is enabled, an error occurs rather than a warning because, in effect, no key is used to determine which rows to modify.


To estimate the amount of memory needed to process a range expression, use these guidelines:
- For a simple query such as the following, where there is one candidate key for the range access method, each predicate combined with OR uses approximately 230 bytes:
```
SELECT COUNT(*) FROM t
WHERE a=1 OR a=2 OR a=3 OR .. . a=N;
```
- Similarly for a query such as the following, each predicate combined with AND uses approximately 125 bytes:
```
SELECT COUNT(*) FROM t
WHERE a=1 AND b=1 AND c=1 ... N;
```

For a query with IN() predicates:
```
SELECT COUNT(*) FROM t
WHERE a IN (1,2, ..., M) AND b IN (1,2, ..., N);
```
Each literal value in an IN() list counts as a predicate combined with OR. If there are two IN() lists, the number of predicates combined with OR is the product of the number of literal values in each list. Thus, the number of predicates combined with OR in the preceding case is M × N.
-> Not good

# References
- Range optimization
https://dev.mysql.com/doc/refman/8.0/en/range-optimization.html#range-access-single-part
- range
https://dev.mysql.com/doc/refman/8.0/en/explain-output.html#jointype_range