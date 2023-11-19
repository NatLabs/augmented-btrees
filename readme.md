## Augmented Btrees
This library contains implementations of different Btree variants.

- [x] B+ Tree ([BpTree](./src/BpTree/lib.mo))
- [ ] Max Value B+ Tree ([MaxBpTree](./src/MaxBpTree/lib.mo)) `in-progress`
- [ ] B* Tree (BsTree) 

#### Benchmarks
Comparing RBTree, BTree and B+Tree (BpTree)
			
Benchmarking the performance with 10k entries

**Instructions**

|        |    insert() |  replace() |      get() |  entries() |    delete() |
| :----- | ----------: | ---------: | ---------: | ---------: | ----------: |
| RBTree | 101_928_691 | 99_788_499 | 42_362_302 | 17_274_007 | 147_963_852 |
| BTree  | 112_005_321 | 81_100_859 | 75_045_684 | 10_681_481 | 122_344_758 |
| B+Tree | 122_018_941 | 83_300_936 | 80_891_362 |  2_947_925 | 126_306_183 |
			

**Heap**

|        |  insert() |   replace() |   get() | entries() |    delete() |
| :----- | --------: | ----------: | ------: | --------: | ----------: |
| RBTree | 9_000_932 | -22_165_380 |  12_088 | 1_889_084 |  16_289_008 |
| BTree  | 1_225_556 |   1_157_476 | 484_800 |   602_476 |   5_609_008 |
| B+Tree |   580_628 |     412_852 | 212_848 |     9_020 | -26_647_532 |
		