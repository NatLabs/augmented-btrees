#### Sequential Insertions of 0..512
Comparing RBTree, BTree and B+Tree (BpTree)

Benchmarking the performance with 10k entries


Instructions

|        |  insert() |     get() | entries() |
| :----- | --------: | --------: | --------: |
| RBTree | 3_704_462 |   612_307 |   887_680 |
| BTree  | 2_701_214 | 1_700_789 |   551_455 |
| B+Tree | 2_694_566 | 1_793_684 |   148_522 |


Heap

|        | insert() |  get() | entries() |
| :----- | -------: | -----: | --------: |
| RBTree |  426_044 |  9_008 |   105_340 |
| BTree  |   57_700 | 24_928 |    39_396 |
| B+Tree |   48_472 | 19_248 |     9_020 |

#### Random insertions of 512 elements between 1 - 10_000
Comparing RBTree, BTree and B+Tree (BpTree)

Benchmarking the performance with 10k entries


Instructions

|        |  insert() |     get() | entries() |
| :----- | --------: | --------: | --------: |
| RBTree | 2_808_282 |   686_006 |   806_511 |
| BTree  | 3_426_841 | 1_795_698 |   500_790 |
| B+Tree | 3_677_833 | 1_848_020 |   137_008 |


Heap
|        | insert() |  get() | entries() |
| :----- | -------: | -----: | --------: |
| RBTree |  328_484 |  9_008 |    96_504 |
| BTree  |   53_952 | 25_056 |    36_720 |
| B+Tree |   44_272 | 19_248 |     9_020 |

#### 10k entries
Instructions

|        |    insert() |  replace() |      get() |  entries() |
| :----- | ----------: | ---------: | ---------: | ---------: |
| RBTree | 102_032_825 | 99_776_185 | 42_359_469 | 17_274_007 |
| BTree  | 112_686_471 | 81_451_715 | 75_398_201 | 10_682_660 |
| B+Tree | 124_871_591 | 83_401_380 | 80_863_236 |  2_952_966 |


Heap

|        |  insert() |   replace() |   get() | entries() |
| :----- | --------: | ----------: | ------: | --------: |
| RBTree | 9_009_524 | -22_163_744 |  16_048 | 1_889_084 |
| BTree  | 1_234_272 |   1_159_348 | 486_896 |   602_292 |
| B+Tree |   645_812 |     416_932 | 215_488 |     9_020 |

#### Trivial delete() implementation

Instructions

|        |    insert() |  replace() |      get() |  entries() |    delete() |
| :----- | ----------: | ---------: | ---------: | ---------: | ----------: |
| RBTree | 102_142_489 | 99_535_290 | 42_490_275 | 17_274_007 | 167_643_824 |
| BTree  | 112_497_603 | 82_325_536 | 76_271_536 | 10_682_682 | 115_974_772 |
| B+Tree | 122_133_309 | 83_434_084 | 81_024_510 |  2_947_388 | 126_306_183 |
			

Heap

|        |  insert() |   replace() |   get() | entries() |    delete() |
| :----- | --------: | ----------: | ------: | --------: | ----------: |
| RBTree | 9_067_256 | -22_215_304 |  12_768 | 1_889_084 |  17_969_008 |
| BTree  | 1_230_988 |   1_157_476 | 484_960 |   602_436 |   5_209_008 |
| B+Tree |   642_892 |     413_012 | 213_008 |     9_020 | -26_646_204 |
		

#### Using a circular buffer to improve delete() performance