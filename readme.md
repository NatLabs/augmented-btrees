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

|            |    insert() |   replace() |      get() |  entries() |     scan() |    remove() |
| :--------- | ----------: | ----------: | ---------: | ---------: | ---------: | ----------: |
| RBTree     | 102_239_215 |  99_685_403 | 42_312_591 | 17_274_017 |      3_500 | 177_484_438 |
| BTree      | 111_950_356 |  81_437_239 | 75_722_656 | 10_682_220 | 23_841_859 | 126_472_969 |
| B+Tree     | 123_392_156 |  91_655_408 | 80_925_648 |  4_897_351 |  6_631_051 | 130_666_828 |
| Max B+Tree | 152_630_753 | 104_439_293 | 80_927_112 |  4_898_907 |  6_632_699 | 179_500_644 |	


**Heap**

|            |  insert() |   replace() |   get() | entries() |    scan() |   remove() |
| :--------- | --------: | ----------: | ------: | --------: | --------: | ---------: |
| RBTree     | 9_044_064 | -22_307_788 |  12_608 | 1_889_084 |     8_952 | 18_809_008 |
| BTree      | 1_226_540 |   1_157_156 | 484_560 |   602_436 | 1_014_196 |  1_962_020 |
| B+Tree     |   792_992 |     624_780 | 221_256 |    17_340 |    39_680 |    342_588 |
| Max B+Tree | 2_381_092 |   1_709_468 | 229_464 |    25_548 |    47_888 |  2_548_040 |
