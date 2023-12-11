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
    let bptree = BpTree.fromArray(?32, [('A', "one"), ('B', "two"), ('C', "three"), ('D', "four"), ('E', "five")], Char.compare);

    assert BpTree.get(bptree, 'A') == "one";

    assert Iter.toArray(BpTree.keys(bptree)) == ['A', 'B', 'C', 'D'];

    ignore BpTree.insert(bptree, 'E', "five");
    assert Iter.toArray(BpTree.keys(bptree)) == ['A', 'B', 'C', 'D', 'E'];

    // replace
    assert BpTree.replace(bptree, 'C', "3") == ?"three";

    assert BpTree.remove(bptree, Char.compare, 'C') == ?"3";

    assert BpTree.toArray(bptree) == [('A', "one"), ('B', "two"), ('D', "four"), ('E', "five")];

    assert BpTree.min(bptree, Char.compare) == ?('A', "one");
    assert BpTree.max(bptree, Char.compare) == ?('E', "five");

    // get sorted position of a key
    assert BpTree.getRank(bptree, Char.compare, 'A') == 0;

    // get the key and value at a given position
    assert BpTree.getByRank(bptree, 0) == ('A', "one");
```

- Iterating over a B+ Tree
    - Each iterator is implemented as a `DoubleEndedIter` and can be iterated in both directions.
    - An iter can be created from a B+ Tree using the `entries()`, `keys()` and `vals()`, `scan()`, or `range()` functions.
    - The iterator can be reversed just by calling the `rev()` function on the iterator.

```motoko
    let bptree = BpTree.fromArray(?32, [('A', "one"), ('B', "two"), ('C', "three"), ('D', "four"), ('E', "five")], Char.compare);

    let entries = BpTree.entries(bptree);
    assert Iter.toArray(entries.rev()) == [('E', "five"), ('D', "four"), ('C', "three"), ('B', "two"), ('A', "one")];

    // search for elements bounded by the given keys (the keys are inclusive)
    let results = BpTree.scan(bptree, Char.compare, 'B', 'D');
    assert Iter.toArray(results) == [('B', "two"), ('C', "three"), ('D', "four")];
    
    let results2 = BpTree.scan(bptree, Char.compare, 'A', 'C');
    assert Iter.toArray(results2.rev()) == [('C', "three"), ('B', "two"), ('A', "one")];

    // retrieve elements by their rank
    let range1 = BpTree.range(bptree, 2, 4);
    assert Iter.toArray(range1) == [('C', "three"), ('D', "four"), ('E', "five")];

    // retrieve the next 3 elements after a given key
    let rank = BpTree.getRank(bptree, Char.compare, 'B');
    let range2 = BpTree.range(bptree, rank + 1, rank + 3);
    assert Iter.toArray(range2) == [('C', "three"), ('D', "four"), ('E', "five")];
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
		