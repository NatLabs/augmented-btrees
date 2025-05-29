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
| getFromIndex() |  69_684_951 |  74_659_599 |
| getIndex()     | 169_321_208 | 169_710_758 |
| getFloor()     |  80_555_894 |  80_557_226 |
| getCeiling()   |  80_556_475 |  80_557_911 |
| removeMin()    | 152_560_473 | 128_191_077 |
| removeMax()    | 116_475_106 |  73_393_021 |


**Heap**

|                |     B+Tree | Max B+Tree |
| :------------- | ---------: | ---------: |
| getFromIndex() | 322.33 KiB | 322.33 KiB |
| getIndex()     | 574.09 KiB | 574.09 KiB |
| getFloor()     | 209.88 KiB | 209.88 KiB |
| getCeiling()   | 209.88 KiB | 209.88 KiB |
| removeMin()    | 209.93 KiB | 477.17 KiB |
| removeMax()    | 206.11 KiB |  521.7 KiB |


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
| insert()              | 139_050_931 | 120_608_259 | 118_892_740 | 152_783_739 |
| replace() higher vals | 134_119_276 |  89_607_566 |  94_039_031 | 126_318_342 |
| replace() lower vals  | 133_940_257 |  89_608_346 |  94_039_837 | 184_072_575 |
| get()                 |  44_278_684 |  80_754_059 |  81_969_702 |  81_971_560 |
| entries()             |  25_616_267 |  13_310_873 |   4_855_667 |   4_857_629 |
| scan()                |       5_076 |  27_252_992 |   6_724_505 |   6_708_025 |
| remove()              | 193_726_515 | 139_830_442 | 129_289_227 | 181_173_324 |


**Heap**

|                       |     RBTree |      BTree |     B+Tree | Max B+Tree |
| :-------------------- | ---------: | ---------: | ---------: | ---------: |
| insert()              |   8.63 MiB |   1.18 MiB | 718.98 KiB |   1.13 MiB |
| replace() higher vals |   7.89 MiB |    1.1 MiB |  600.5 KiB | 761.01 KiB |
| replace() lower vals  | -21.22 MiB |    1.1 MiB |  600.5 KiB |   3.02 MiB |
| get()                 |  13.74 KiB | 474.32 KiB | 209.87 KiB | 209.87 KiB |
| entries()             |    1.8 MiB | 589.24 KiB |   9.95 KiB |   9.95 KiB |
| scan()                |   9.78 KiB | 991.88 KiB |  31.77 KiB |  31.77 KiB |
| remove()              | -11.83 MiB |   1.88 MiB |  209.6 KiB |   1.01 MiB |


**Garbage Collection**

|                       |    RBTree | BTree | B+Tree | Max B+Tree |
| :-------------------- | --------: | ----: | -----: | ---------: |
| insert()              |       0 B |   0 B |    0 B |        0 B |
| replace() higher vals |       0 B |   0 B |    0 B |        0 B |
| replace() lower vals  | 29.11 MiB |   0 B |    0 B |        0 B |
| get()                 |       0 B |   0 B |    0 B |        0 B |
| entries()             |       0 B |   0 B |    0 B |        0 B |
| scan()                |       0 B |   0 B |    0 B |        0 B |
| remove()              | 26.56 MiB |   0 B |    0 B |        0 B |


</details>
Saving results to .bench/SortedMap.bench.json
