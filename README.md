# Benchmark Results



<details>

<summary>bench/BpTree.bench.mo $({\color{gray}0\%})$</summary>

### Comparing B+Tree and Max B+Tree

_Benchmarking the performance with 10k entries_


Instructions: ${\color{gray}0\\%}$
Heap: ${\color{gray}0\\%}$
Stable Memory: ${\color{gray}0\\%}$
Garbage Collection: ${\color{gray}0\\%}$


**Instructions**

|                |                             B+Tree |                         Max B+Tree |
| :------------- | ---------------------------------: | ---------------------------------: |
| getFromIndex() |  59_607_817 $({\color{gray}0\\%})$ |  64_364_142 $({\color{gray}0\\%})$ |
| getIndex()     | 151_145_134 $({\color{gray}0\\%})$ | 151_510_359 $({\color{gray}0\\%})$ |
| getFloor()     |  75_126_652 $({\color{gray}0\\%})$ |  75_127_828 $({\color{gray}0\\%})$ |
| getCeiling()   |  75_127_177 $({\color{gray}0\\%})$ |  75_128_445 $({\color{gray}0\\%})$ |
| removeMin()    | 132_390_029 $({\color{gray}0\\%})$ | 106_541_717 $({\color{gray}0\\%})$ |
| removeMax()    | 104_330_921 $({\color{gray}0\\%})$ |  60_255_588 $({\color{gray}0\\%})$ |


**Heap**

|                |                            B+Tree |                        Max B+Tree |
| :------------- | --------------------------------: | --------------------------------: |
| getFromIndex() | 322.33 KiB $({\color{gray}0\\%})$ | 322.33 KiB $({\color{gray}0\\%})$ |
| getIndex()     | 584.76 KiB $({\color{gray}0\\%})$ | 584.84 KiB $({\color{gray}0\\%})$ |
| getFloor()     | 213.27 KiB $({\color{gray}0\\%})$ | 213.27 KiB $({\color{gray}0\\%})$ |
| getCeiling()   | 213.27 KiB $({\color{gray}0\\%})$ | 213.27 KiB $({\color{gray}0\\%})$ |
| removeMin()    | 212.86 KiB $({\color{gray}0\\%})$ | 478.09 KiB $({\color{gray}0\\%})$ |
| removeMax()    | 206.89 KiB $({\color{gray}0\\%})$ | 526.55 KiB $({\color{gray}0\\%})$ |


**Garbage Collection**

|                |                     B+Tree |                 Max B+Tree |
| :------------- | -------------------------: | -------------------------: |
| getFromIndex() | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| getIndex()     | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| getFloor()     | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| getCeiling()   | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| removeMin()    | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |
| removeMax()    | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |


</details>
Saving results to .bench/BpTree.bench.json

<details>

<summary>bench/SortedMap.bench.mo $({\color{gray}0\%})$</summary>

### Comparing RBTree, BTree and B+Tree (BpTree)

_Benchmarking the performance with 10k entries_


Instructions: ${\color{gray}0\\%}$
Heap: ${\color{gray}0\\%}$
Stable Memory: ${\color{gray}0\\%}$
Garbage Collection: ${\color{gray}0\\%}$


**Instructions**

|                       |                             RBTree |                              BTree |                             B+Tree |                         Max B+Tree |
| :-------------------- | ---------------------------------: | ---------------------------------: | ---------------------------------: | ---------------------------------: |
| insert()              | 123_966_513 $({\color{gray}0\\%})$ | 108_895_034 $({\color{gray}0\\%})$ | 106_596_885 $({\color{gray}0\\%})$ | 134_608_483 $({\color{gray}0\\%})$ |
| replace() higher vals | 117_971_104 $({\color{gray}0\\%})$ |  81_599_825 $({\color{gray}0\\%})$ |  85_099_290 $({\color{gray}0\\%})$ | 115_920_822 $({\color{gray}0\\%})$ |
| replace() lower vals  | 117_821_865 $({\color{gray}0\\%})$ |  81_600_623 $({\color{gray}0\\%})$ |  85_100_111 $({\color{gray}0\\%})$ | 167_926_704 $({\color{gray}0\\%})$ |
| get()                 |  38_612_988 $({\color{gray}0\\%})$ |  73_722_692 $({\color{gray}0\\%})$ |  76_440_091 $({\color{gray}0\\%})$ |  76_441_684 $({\color{gray}0\\%})$ |
| entries()             |  22_845_560 $({\color{gray}0\\%})$ |  11_986_538 $({\color{gray}0\\%})$ |   3_869_650 $({\color{gray}0\\%})$ |   3_871_335 $({\color{gray}0\\%})$ |
| scan()                |       4_518 $({\color{gray}0\\%})$ |  24_148_386 $({\color{gray}0\\%})$ |   5_601_084 $({\color{gray}0\\%})$ |   5_585_611 $({\color{gray}0\\%})$ |
| remove()              | 166_045_804 $({\color{gray}0\\%})$ | 125_125_677 $({\color{gray}0\\%})$ | 113_776_950 $({\color{gray}0\\%})$ | 159_817_301 $({\color{gray}0\\%})$ |


**Heap**

|                       |                            RBTree |                             BTree |                            B+Tree |                        Max B+Tree |
| :-------------------- | --------------------------------: | --------------------------------: | --------------------------------: | --------------------------------: |
| insert()              |   8.65 MiB $({\color{gray}0\\%})$ |   1.17 MiB $({\color{gray}0\\%})$ | 723.52 KiB $({\color{gray}0\\%})$ | -25.56 MiB $({\color{gray}0\\%})$ |
| replace() higher vals |   7.81 MiB $({\color{gray}0\\%})$ |   1.11 MiB $({\color{gray}0\\%})$ |  603.9 KiB $({\color{gray}0\\%})$ | 767.38 KiB $({\color{gray}0\\%})$ |
| replace() lower vals  |   7.81 MiB $({\color{gray}0\\%})$ |   1.11 MiB $({\color{gray}0\\%})$ |  603.9 KiB $({\color{gray}0\\%})$ |   3.01 MiB $({\color{gray}0\\%})$ |
| get()                 |  15.11 KiB $({\color{gray}0\\%})$ | 476.85 KiB $({\color{gray}0\\%})$ | 213.27 KiB $({\color{gray}0\\%})$ | 213.27 KiB $({\color{gray}0\\%})$ |
| entries()             |    1.8 MiB $({\color{gray}0\\%})$ | 589.27 KiB $({\color{gray}0\\%})$ |   9.95 KiB $({\color{gray}0\\%})$ |   9.95 KiB $({\color{gray}0\\%})$ |
| scan()                |   9.78 KiB $({\color{gray}0\\%})$ | 987.75 KiB $({\color{gray}0\\%})$ |  31.73 KiB $({\color{gray}0\\%})$ |  31.73 KiB $({\color{gray}0\\%})$ |
| remove()              | -14.26 MiB $({\color{gray}0\\%})$ |   1.87 MiB $({\color{gray}0\\%})$ |  212.8 KiB $({\color{gray}0\\%})$ |   1.06 MiB $({\color{gray}0\\%})$ |


**Garbage Collection**

|                       |                           RBTree |                      BTree |                     B+Tree |                       Max B+Tree |
| :-------------------- | -------------------------------: | -------------------------: | -------------------------: | -------------------------------: |
| insert()              |       0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 26.69 MiB $({\color{gray}0\\%})$ |
| replace() higher vals |       0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |       0 B $({\color{gray}0\\%})$ |
| replace() lower vals  |       0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |       0 B $({\color{gray}0\\%})$ |
| get()                 |       0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |       0 B $({\color{gray}0\\%})$ |
| entries()             |       0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |       0 B $({\color{gray}0\\%})$ |
| scan()                |       0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |       0 B $({\color{gray}0\\%})$ |
| remove()              | 28.62 MiB $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ | 0 B $({\color{gray}0\\%})$ |       0 B $({\color{gray}0\\%})$ |


</details>
Saving results to .bench/SortedMap.bench.json
