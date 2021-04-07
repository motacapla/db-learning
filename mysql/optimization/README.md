# Optimizing
## Database level
- Are the tables structured properly?
- Are the right indexes in place to make queries efficient?
- Are you using the appropriate storage engine for each table, and taking advantage of the strengths and features of each storage engine you use?
- Does each table use an appropriate row format?
- Does the application use an appropriate locking strategy?
- Are all memory areas used for caching sized correctly?

## Hardware level
System bottlenecks typically arise from these sources:
- Disk seeks. With modern disks, the mean time for this is usually lower than 10ms, so we can in theory do about 100 seeks a second.
- Disk reading and writing. When the disk is at the correct position, we need to read or write the data. With modern disks, one disk delivers at least 10–20MB/s throughput.
- CPU cycles. When the data is in main memory, we must process it to get our result. Having large tables compared to the amount of memory is the most common limiting factor.
- Memory bandwidth. When the CPU needs more data than can fit in the CPU cache, main memory bandwidth becomes a bottleneck.
