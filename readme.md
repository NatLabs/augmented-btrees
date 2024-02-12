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
    - Each iterator is implemented as a Reversible Iterator (`RevIter`) and can be iterated in both directions.
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
| Map        |  24_598_150 |   9_032_975 |  8_459_600 |      3_836 |      3_232 |   8_769_418 |
| RBTree     | 105_236_358 | 103_166_554 | 44_269_891 | 17_795_354 |      4_891 | 141_566_127 |
| BTree      | 114_964_951 |  83_757_726 | 78_246_105 | 10_944_900 | 24_351_645 | 130_728_937 |
| B+Tree     | 116_660_293 |  91_628_770 | 81_339_298 |  4_854_853 |  6_635_837 | 130_971_230 |
| Max B+Tree | 142_346_011 | 131_460_306 | 81_341_110 |  4_856_757 |  6_619_287 | 179_615_500 |

**Heap**

|            |  insert() | replace() |   get() | entries() |    scan() |    remove() |
| :--------- | --------: | --------: | ------: | --------: | --------: | ----------: |
| Map        |   534_660 |     9_204 |   9_200 |     9_036 |     8_904 |     255_520 |
| RBTree     | 9_051_828 | 8_268_692 |  12_960 | 1_889_036 |     8_904 | -15_479_996 |
| BTree      | 1_234_000 | 1_157_004 | 484_600 |   602_276 | 1_014_572 |   1_968_844 |
| B+Tree     |   772_584 |   613_804 | 213_800 |     9_084 |    31_424 |     344_116 |
| Max B+Tree |   950_360 | 1_924_204 | 213_800 |     9_084 |    31_424 |   1_761_648 |

#### Other B+Tree functions

**Instructions**

|                |      B+Tree |  Max B+Tree |
| :------------- | ----------: | ----------: |
| getFromIndex() |  68_084_521 |  73_059_451 |
| getIndex()     | 167_272_699 | 167_274_197 |
| getFloor()     |  79_745_701 |  79_747_291 |
| getCeiling()   |  79_746_354 |  79_748_036 |
| removeMin()    | 154_673_724 | 204_129_959 |
| removeMax()    | 118_557_851 | 160_697_206 |

**Heap**

|                |  B+Tree | Max B+Tree |
| :------------- | ------: | ---------: |
| getFromIndex() | 328_960 |    328_960 |
| getIndex()     | 586_764 |    586_764 |
| getFloor()     | 213_804 |    213_804 |
| getCeiling()   | 213_804 |    213_804 |
| removeMin()    | 513_040 |  1_908_884 |
| removeMax()    | 509_176 |  1_908_676 |