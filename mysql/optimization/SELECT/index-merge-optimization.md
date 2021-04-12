# Index Merge Optimization
The Index Merge access method retrieves rows with multiple range scans and merges their results into one.
This access method merges index scans from a single table only, not scans across multiple tables.
The merge can produce unions, intersections, or unions-of-intersections of its underlying scans.

Example queries for which Index Merge may be used:

```
SELECT * FROM tbl_name WHERE key1 = 10 OR key2 = 20;

SELECT * FROM tbl_name
  WHERE (key1 = 10 OR key2 = 20) AND non_key = 30;

SELECT * FROM t1, t2
  WHERE (t1.key1 IN (1,2) OR t1.key2 LIKE 'value%')
  AND t2.key1 = t1.some_col;

SELECT * FROM t1, t2
  WHERE t1.key1 = 1
  AND (t2.key1 = t1.some_col OR t2.key2 = t1.some_col2);
```

The Index Merge optimization algorithm has the following known limitations:

- If your query has a complex WHERE clause with deep AND/OR nesting and MySQL does not choose the optimal plan, try distributing terms using the following identity transformations:
(x AND y) OR z => (x OR z) AND (y OR z)
(x OR y) AND z => (x AND z) OR (y AND z)

- Index Merge is not applicable to full-text indexes.

The optimizer chooses between different possible Index Merge algorithms and other access methods based on cost estimates of the various available options.

## Index Merge Intersection Access Algorithm
This access algorithm is applicable when a WHERE clause is converted to several range conditions on different keys combined with AND, and each condition is one of the following:

- An N-part expression of this form, where the index has exactly N parts (that is, all index parts are covered):
```
key_part1 = const1 AND key_part2 = const2 ... AND key_partN = constN
```

- Any range condition over the primary key of an InnoDB table.

Examples:
```
SELECT * FROM innodb_table
  WHERE primary_key < 10 AND key_col1 = 20;

SELECT * FROM tbl_name
  WHERE key1_part1 = 1 AND key1_part2 = 2 AND key2 = 2;
```

## Index Merge Union Access Algorithm
The criteria for this algorithm are similar to those for the Index Merge intersection algorithm. The algorithm is applicable when the table's WHERE clause is converted to several range conditions on different keys combined with OR, and each condition is one of the following:

- An N-part expression of this form, where the index has exactly N parts (that is, all index parts are covered):
```
key_part1 = const1 AND key_part2 = const2 ... AND key_partN = constN
```

- Any range condition over a primary key of an InnoDB table.

- A condition for which the Index Merge intersection algorithm is applicable.

Examples:
```
SELECT * FROM t1
  WHERE key1 = 1 OR key2 = 2 OR key3 = 3;

SELECT * FROM innodb_table
  WHERE (key1 = 1 AND key2 = 2)
     OR (key3 = 'foo' AND key4 = 'bar') AND key5 = 5;
```

## Index Merge Sort-Union Access Algorithm
This access algorithm is applicable when the WHERE clause is converted to several range conditions combined by OR, but the Index Merge union algorithm is not applicable.

Examples:
```
SELECT * FROM tbl_name
  WHERE key_col1 < 10 OR key_col2 < 20;

SELECT * FROM tbl_name
  WHERE (key_col1 > 10 OR key_col2 = 20) AND nonkey_col = 30;
```

The difference between the sort-union algorithm and the union algorithm is that the sort-union algorithm must first fetch row IDs for all rows and sort them before returning any rows.