## Augmented Btrees
This library contains implementations of different Btree variants.

- [x] B+ Tree ([BpTree](./src/BpTree/lib.mo))
- [ ] Max Value B+ Tree ([MaxBpTree](./src/MaxBpTree/lib.mo)) `in-progress`

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
    assert BpTree.getRank(bptree, Char.compare, 'A') == 0;

    // get the key and value at a given position
    assert BpTree.getByRank(bptree, 0) == ('A', 0);
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
    let results = BpTree.scan(bptree, Char.compare, 'B', 'D');
    assert Iter.toArray(results) == [('B', 1), ('C', 2), ('D', 3)];
    
    let results2 = BpTree.scan(bptree, Char.compare, 'A', 'C');
    assert Iter.toArray(results2.rev()) == [('C', 2), ('B', 1), ('A', 0)];

    // retrieve elements by their rank
    let range1 = BpTree.range(bptree, 2, 4);
    assert Iter.toArray(range1) == [('C', 2), ('D', 3), ('E', 4)];

    // retrieve the next 3 elements after a given key
    let rankB = BpTree.getRank(bptree, Char.compare, 'B');
    assert rankB == 1;
    
    let range2 = BpTree.range(bptree, rankB + 1, rankB + 3);
    assert Iter.toArray(range2) == [('C', 2), ('D', 3), ('E', 4)];
```

#### Benchmarks
Comparing RBTree, BTree and B+Tree (BpTree)

Benchmarking the performance with 10k entries

**Instructions**

|        |    insert() |   replace() |      get() |  entries() |    remove() |
| :----- | ----------: | ----------: | ---------: | ---------: | ----------: |
| RBTree | 102_063_058 | 100_298_176 | 42_450_532 | 17_274_007 | 157_803_838 |
| BTree  | 111_679_483 |  80_763_969 | 75_048_439 | 10_681_262 | 125_977_277 |
| B+Tree | 123_631_604 |  91_690_650 | 80_891_078 |  4_897_328 | 130_781_388 |
					

**Heap**

|        |  insert() |   replace() |   get() | entries() |   remove() |
| :----- | --------: | ----------: | ------: | --------: | ---------: |
| RBTree | 9_025_916 | -22_114_244 |  13_408 | 1_889_084 | 17_129_008 |
| BTree  | 1_221_728 |   1_158_612 | 485_888 |   602_524 |  1_956_932 |
| B+Tree |   791_284 |     623_260 | 223_256 |    17_340 |    347_548 |
		