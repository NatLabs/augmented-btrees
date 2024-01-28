## Augmented Btrees
This library contains implementations of different Btree variants.

- [x] B+ Tree ([BpTree](https://mops.one/augmented-btrees/docs/BpTree/lib#new))
- [ ] Max Value B+ Tree ([MaxBpTree](https://mops.one/augmented-btrees/docs/MaxBpTree/lib#new)) `in-progress`

### Usage
- Import the library 
  
```motoko
    import { BpTree } "mo:augmented-btrees";
```

- Create a new B+ Tree 
    - When creating a new B+ Tree, you can specify the order of the tree. The order of the tree is the maximum number of children a node can have. The order must be between 4 and 512. The default order is 32.

```motoko
    let bptree = BpTree.new(?32);
```

- Examples of operations on a B+ Tree
```motoko
    let bptree = BpTree.fromArray(?32, [('A', 0), ('B', 1), ('C', 2), ('D', 3), ('E', 4)], Char.compare);

    assert Iter.toArray(BpTree.keys(bptree)) == ['A', 'B', 'C', 'D'];

    assert BpTree.get(bptree, 'A') == 0;

    ignore BpTree.insert(bptree, 'E', 4);
    assert Iter.toArray(BpTree.vals(bptree)) == ['A', 'B', 'C', 'D', 'E'];

    // replace
    assert BpTree.insert(bptree, 'C', 33) == ?3;

    assert BpTree.remove(bptree, Char.compare, 'C') == ?33;
    assert BpTree.toArray(bptree) == [('A', 0), ('B', 1), ('D', 3), ('E', 4)];

    assert BpTree.min(bptree, Char.compare) == ?('A', 0);
    assert BpTree.max(bptree, Char.compare) == ?('E', 4);

    // get sorted position of a key
    assert BpTree.getIndex(bptree, Char.compare, 'A') == 0;

    // get the key and value at a given position
    assert BpTree.getFromIndex(bptree, 0) == ('A', 0);
```

- Iterating over a B+ Tree
    - Each iterator is implemented as a `DoubleEndedIter` and can be iterated in both directions.
    - An iter can be created from a B+ Tree using the `entries()`, `keys()`, `vals()`, `scan()`, or `range()` functions.
    - The iterator can be reversed just by calling the `rev()` function on the iterator.

```motoko
    let bptree = BpTree.fromArray(?32, [('A', 0), ('B', 1), ('C', 2), ('D', 3), ('E', 4)], Char.compare);

    let entries = BpTree.entries(bptree);
    assert Iter.toArray(entries.rev()) == [('E', 4), ('D', 3), ('C', 2), ('B', 1), ('A', 0)];

    // search for elements bounded by the given keys (the keys are inclusive)
    let results = BpTree.scan(bptree, Char.compare, ?'B', ?'D');
    assert Iter.toArray(results) == [('B', 1), ('C', 2), ('D', 3)];
    
    let results2 = BpTree.scan(bptree, Char.compare, ?'A', ?'C');
    assert Iter.toArray(results2.rev()) == [('C', 2), ('B', 1), ('A', 0)];

    // retrieve elements by their index
    let range1 = BpTree.range(bptree, 2, 4);
    assert Iter.toArray(range1) == [('C', 2), ('D', 3), ('E', 4)];

    // retrieve the next 3 elements after a given key
    let index_of_B = BpTree.getIndex(bptree, Char.compare, 'B');
    assert index_of_B == 1;
    
    let range2 = BpTree.range(bptree, index_of_B + 1, indexB + 3);
    assert Iter.toArray(range2) == [('C', 2), ('D', 3), ('E', 4)];
```

### Benchmarks
Benchmarking the performance with 10k entries


#### Comparing RBTree, BTree and B+Tree (BpTree)

**Instructions**

|            |    insert() |   replace() |      get() |  entries() |     scan() |    remove() |
| :--------- | ----------: | ----------: | ---------: | ---------: | ---------: | ----------: |
| RBTree     | 102_760_231 | 100_751_391 | 43_261_986 | 17_455_239 |      4_794 | 138_125_976 |
| BTree      | 112_161_650 |  81_750_392 | 76_377_317 | 10_684_662 | 23_773_096 | 127_731_251 |
| B+Tree     | 115_675_829 |  89_551_271 | 79_441_789 |  4_802_879 |  6_541_589 | 127_821_524 |
| Max B+Tree | 155_073_391 | 134_448_918 | 81_163_571 |  4_898_717 |  6_647_119 | 192_655_744 |
			

**Heap**

|            |  insert() | replace() |   get() | entries() |    scan() |    remove() |
| :--------- | --------: | --------: | ------: | --------: | --------: | ----------: |
| RBTree     | 9_051_876 | 8_268_740 |  13_008 | 1_889_084 |     8_952 |  16_689_008 |
| BTree      | 1_234_048 | 1_157_052 | 484_648 |   602_324 | 1_014_620 |   1_968_892 |
| B+Tree     |   772_632 |   613_852 | 213_848 |     9_132 |    31_472 |     344_164 |
| Max B+Tree | 2_438_292 | 3_079_864 | 230_264 |    25_548 |    47_888 |   2_922_652 |
	

#### Other B+Tree functions

**Instructions**

|                |      B+Tree |  Max B+Tree |
| :------------- | ----------: | ----------: |
| getFromIndex() |  71_925_427 |  79_316_767 |
| getIndex()     | 203_900_151 | 218_410_671 |
| getFloor()     |  77_868_282 |  79_589_842 |
| getCeiling()   |  77_868_925 |  79_590_577 |
| removeMin()    | 150_790_687 | 211_728_742 |
| removeMax()    | 116_471_729 | 167_714_299 |
			

**Heap**

|                |    B+Tree | Max B+Tree |
| :------------- | --------: | ---------: |
| getFromIndex() |   345_424 |    345_424 |
| getIndex()     | 5_195_228 |  5_195_228 |
| getFloor()     |   230_268 |    230_268 |
| getCeiling()   |   230_268 |    230_268 |
| removeMin()    |   529_504 |  2_903_368 |
| removeMax()    |   525_640 |  2_687_668 |
