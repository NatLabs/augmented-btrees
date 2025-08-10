# Benchmark Results


No previous results found "/home/runner/work/augmented-btrees/augmented-btrees/.bench/BpTree.bench.json"

<details>

<summary>bench/BpTree.bench.mo $({\color{gray}0\%})$</summary>

### Comparing B+Tree and Max B+Tree

_Benchmarking the performance with 10k entries_


Instructions: ${\color{gray}0\\%}$
Heap: ${\color{gray}0\\%}$
Stable Memory: ${\color{gray}0\\%}$
Garbage Collection: ${\color{gray}0\\%}$


**Instructions**

|                |      B+Tree |  Max B+Tree |
| :------------- | ----------: | ----------: |
| getFromIndex() |  59_607_817 |  64_364_142 |
| getIndex()     | 151_145_134 | 151_510_359 |
| getFloor()     |  75_126_652 |  75_127_828 |
| getCeiling()   |  75_127_177 |  75_128_445 |
| removeMin()    | 132_390_029 | 106_541_717 |
| removeMax()    | 104_330_921 |  60_255_588 |


**Heap**

|                |     B+Tree | Max B+Tree |
| :------------- | ---------: | ---------: |
| getFromIndex() | 322.33 KiB | 322.33 KiB |
| getIndex()     | 584.76 KiB | 584.84 KiB |
| getFloor()     | 213.27 KiB | 213.27 KiB |
| getCeiling()   | 213.27 KiB | 213.27 KiB |
| removeMin()    | 212.86 KiB | 478.09 KiB |
| removeMax()    | 206.89 KiB | 526.55 KiB |


**Garbage Collection**

|                | B+Tree | Max B+Tree |
| :------------- | -----: | ---------: |
| getFromIndex() |    0 B |        0 B |
| getIndex()     |    0 B |        0 B |
| getFloor()     |    0 B |        0 B |
| getCeiling()   |    0 B |        0 B |
| removeMin()    |    0 B |        0 B |
| removeMax()    |    0 B |        0 B |


</details>
Saving results to .bench/BpTree.bench.json
No previous results found "/home/runner/work/augmented-btrees/augmented-btrees/.bench/SortedMap.bench.json"

<details>

<summary>bench/SortedMap.bench.mo $({\color{gray}0\%})$</summary>

### Comparing RBTree, BTree and B+Tree (BpTree)

_Benchmarking the performance with 10k entries_


Instructions: ${\color{gray}0\\%}$
Heap: ${\color{gray}0\\%}$
Stable Memory: ${\color{gray}0\\%}$
Garbage Collection: ${\color{gray}0\\%}$


**Instructions**

|                       |      RBTree |       BTree |      B+Tree |  Max B+Tree |
| :-------------------- | ----------: | ----------: | ----------: | ----------: |
| insert()              | 123_966_513 | 108_895_034 | 106_596_885 | 134_608_483 |
| replace() higher vals | 117_971_104 |  81_599_825 |  85_099_290 | 115_920_822 |
| replace() lower vals  | 117_821_865 |  81_600_623 |  85_100_111 | 167_926_704 |
| get()                 |  38_612_988 |  73_722_692 |  76_440_091 |  76_441_684 |
| entries()             |  22_845_560 |  11_986_538 |   3_869_650 |   3_871_335 |
| scan()                |       4_518 |  24_148_386 |   5_601_084 |   5_585_611 |
| remove()              | 166_045_804 | 125_125_677 | 113_776_950 | 159_817_301 |


**Heap**

|                       |     RBTree |      BTree |     B+Tree | Max B+Tree |
| :-------------------- | ---------: | ---------: | ---------: | ---------: |
| insert()              |   8.65 MiB |   1.17 MiB | 723.52 KiB | -25.56 MiB |
| replace() higher vals |   7.81 MiB |   1.11 MiB |  603.9 KiB | 767.38 KiB |
| replace() lower vals  |   7.81 MiB |   1.11 MiB |  603.9 KiB |   3.01 MiB |
| get()                 |  15.11 KiB | 476.85 KiB | 213.27 KiB | 213.27 KiB |
| entries()             |    1.8 MiB | 589.27 KiB |   9.95 KiB |   9.95 KiB |
| scan()                |   9.78 KiB | 987.75 KiB |  31.73 KiB |  31.73 KiB |
| remove()              | -14.26 MiB |   1.87 MiB |  212.8 KiB |   1.06 MiB |


**Garbage Collection**

|                       |    RBTree | BTree | B+Tree | Max B+Tree |
| :-------------------- | --------: | ----: | -----: | ---------: |
| insert()              |       0 B |   0 B |    0 B |  26.69 MiB |
| replace() higher vals |       0 B |   0 B |    0 B |        0 B |
| replace() lower vals  |       0 B |   0 B |    0 B |        0 B |
| get()                 |       0 B |   0 B |    0 B |        0 B |
| entries()             |       0 B |   0 B |    0 B |        0 B |
| scan()                |       0 B |   0 B |    0 B |        0 B |
| remove()              | 28.62 MiB |   0 B |    0 B |        0 B |


</details>
Saving results to .bench/SortedMap.bench.json
