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

|        |    insert() |   replace() |      get() |  entries() |    delete() |
| :----- | ----------: | ----------: | ---------: | ---------: | ----------: |
| RBTree | 102_061_616 | 100_293_742 | 42_658_641 | 17_274_007 | 161_733_838 |
| BTree  | 112_433_856 |  81_398_138 | 75_343_434 | 10_681_930 | 115_974_772 |
| B+Tree | 121_831_264 |  83_277_663 | 80_868_089 |  2_944_524 | 120_396_197 |
			

Heap

|        |  insert() |   replace() |   get() | entries() |    delete() |
| :----- | --------: | ----------: | ------: | --------: | ----------: |
| RBTree | 9_011_092 | -22_135_020 |  14_648 | 1_889_084 |  17_569_008 |
| BTree  | 1_226_592 |   1_159_348 | 486_736 |   602_452 |   5_209_008 |
| B+Tree |   636_748 |     415_012 | 215_008 |     9_020 | -27_051_704 |

#### Combine array operations to improve delete() performance (turns out the performance was reduced)


Instructions

|        |    insert() |   replace() |      get() |  entries() |    delete() |
| :----- | ----------: | ----------: | ---------: | ---------: | ----------: |
| RBTree | 102_480_363 | 100_262_336 | 42_814_647 | 17_274_007 | 151_893_852 |
| BTree  | 112_604_581 |  82_020_687 | 75_967_406 | 10_682_963 | 119_114_772 |
| B+Tree | 121_872_014 |  83_290_850 | 80_881_276 |  2_946_314 | 120_396_197 |

Heap

|        |  insert() |   replace() |   get() | entries() |    delete() |
| :----- | --------: | ----------: | ------: | --------: | ----------: |
| RBTree | 9_061_892 | -22_162_980 |  16_088 | 1_889_084 |  16_729_008 |
| BTree  | 1_234_776 |   1_161_124 | 488_704 |   602_300 |   5_209_008 |
| B+Tree |   580_928 |     417_812 | 217_808 |     9_020 | -27_046_888 |

#### Using a circular buffer to improve delete() performance