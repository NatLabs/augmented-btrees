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
| getFromIndex() |  69_204_867 |  74_121_324 |
| getIndex()     | 167_962_193 | 168_349_590 |
| getFloor()     |  80_759_274 |  80_760_606 |
| getCeiling()   |  80_759_855 |  80_761_291 |
| removeMin()    | 152_231_327 | 128_429_901 |
| removeMax()    | 116_853_985 |  73_302_664 |


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
| insert()              | 138_706_916 | 120_533_154 | 118_812_383 | 152_597_750 |
| replace() higher vals | 131_778_919 |  88_440_356 |  94_242_249 | 127_612_276 |
| replace() lower vals  | 131_599_779 |  88_441_226 |  94_243_145 | 184_310_971 |
| get()                 |  42_870_927 |  79_585_205 |  82_173_082 |  82_174_940 |
| entries()             |  25_616_267 |  13_309_973 |   4_858_051 |   4_860_013 |
| scan()                |       5_076 |  27_175_661 |   6_734_038 |   6_717_558 |
| remove()              | 186_866_519 | 139_058_541 | 129_523_865 | 184_573_715 |


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
