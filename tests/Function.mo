import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";
import { test; suite } "mo:test";
import Itertools "mo:itertools/Iter";

import { BpTree; Cmp } "../src";
import ArrayMut "../src/internal/ArrayMut";
import Utils "../src/internal/Utils";
import {Const = C} "../src/BpTree/Types";

func gen_id() : Nat = 0;

func new_leaf(order : Nat, start : Nat, end : Nat) : BpTree.Leaf<Nat, Nat> {
    let size = end - start : Nat;
    let kvs = Utils.tabulate_var<(Nat, Nat)>(
        order,
        size,
        func(i : Nat) : ?(Nat, Nat) {
            if (i < size) return ?(start + i, start + i);
            return null;
        },
    );

    let leaf = BpTree.Leaf.new(6, size, ?kvs, gen_id);
};

func new_branch(order : Nat, start : Nat) : BpTree.Branch<Nat, Nat> {

    let children = Utils.tabulate_var<BpTree.Node<Nat, Nat>>(
        order,
        order,
        func(i : Nat) : ?BpTree.Node<Nat, Nat> {
            return ? #leaf(new_leaf(order, start, start + order));
        },
    );

    let branch = BpTree.Branch.new<Nat, Nat>(6, null, ?children, gen_id);
};

func to_bptree<K, V>(order : Nat, branch : BpTree.Branch<K, V>) : BpTree.BpTree<K, V> {
    {
        order;
        var root = #branch(branch);
        var size = branch.0[C.SUBTREE_SIZE];
        var next_id = 0;
    };
};

func validate_indexes<K, V>(arr : [var ?BpTree.Node<K, V>], count : Nat) : Bool {

    var i = 0;

    while (i < count) {
        switch (arr[i]) {
            case (? #branch(node) or ? #leaf(node)) {
                if (node.0[C.INDEX] != i) return false;
            };
            case (_) Debug.trap("validate_indexes: accessed a null value");
        };
        i += 1;
    };

    true;
};

suite(
    "Function Tests",
    func() {
        test(
            "binary search",
            func() {
                let arr = [var ?1, ?3, ?5, ?7, null];
                var count = 4;

                assert 0 == ArrayMut.binary_search(arr, Cmp.Nat, 1, count);
                assert 1 == ArrayMut.binary_search(arr, Cmp.Nat, 3, count);
                assert 2 == ArrayMut.binary_search(arr, Cmp.Nat, 5, count);
                assert 3 == ArrayMut.binary_search(arr, Cmp.Nat, 7, count);

                assert -1 == ArrayMut.binary_search(arr, Cmp.Nat, 0, count);
                assert -2 == ArrayMut.binary_search(arr, Cmp.Nat, 2, count);
                assert -3 == ArrayMut.binary_search(arr, Cmp.Nat, 4, count);
                assert -4 == ArrayMut.binary_search(arr, Cmp.Nat, 6, count);
                assert -5 == ArrayMut.binary_search(arr, Cmp.Nat, 8, count);

                arr[4] := ?9;
                count := 5;

                assert 4 == ArrayMut.binary_search(arr, Cmp.Nat, 9, count);
                assert -5 == ArrayMut.binary_search(arr, Cmp.Nat, 8, count);
                assert -6 == ArrayMut.binary_search(arr, Cmp.Nat, 10, count);

                arr[4] := null;
                arr[3] := null;
                arr[2] := null;
                arr[1] := null;
                count := 1;

                assert 0 == ArrayMut.binary_search(arr, Cmp.Nat, 1, count);
                assert -1 == ArrayMut.binary_search(arr, Cmp.Nat, 0, count);
                assert -2 == ArrayMut.binary_search(arr, Cmp.Nat, 10, count);

            },
        );
    },
);
suite(
    "distribute & merge",
    func() {
        test(
            "re-distribute data from two leaf nodes",
            func() {
                let left = BpTree.Leaf.new(6, 2, ?[var ?(1, 1), ?(3, 3), null, null, null, null], gen_id);
                assert left.0[C.COUNT] == 2;

                let right = BpTree.Leaf.new(6, 4, ?[var ?(5, 5), ?(7, 7), ?(9, 9), ?(11, 11), null, null], gen_id);
                assert right.0[C.COUNT] == 4;

                let parent = BpTree.Branch.new<Nat, Nat>(6, null, null, gen_id);
                BpTree.Branch.add_child(parent, #leaf(left));
                BpTree.Branch.add_child(parent, #leaf(right));

                Debug.print("parent: " # debug_show parent.0[C.SUBTREE_SIZE]);
                assert parent.0[C.SUBTREE_SIZE] == 6;
                assert parent.0[C.COUNT] == 2;
                // assert Array.freeze(parent.2) == [?5, null, null, null, null];
                assert left.0[C.INDEX] == 0;
                assert right.0[C.INDEX] == 1;

                BpTree.Leaf.redistribute_keys(left);

                assert left.0[C.COUNT] == 3;
                assert right.0[C.COUNT] == 3;

                assert Array.freeze(left.3) == [?(1, 1), ?(3, 3), ?(5, 5), null, null, null];
                assert Array.freeze(right.3) == [?(7, 7), ?(9, 9), ?(11, 11), null, null, null];

                assert parent.0[C.COUNT] == 2;
                // assert Array.freeze(parent.2) == [?7, null, null, null, null];
                assert parent.0[C.SUBTREE_SIZE] == 6;
            },
        );

        test(
            "redistribute keys from the larger adjacent leaf node",
            func() {
                let left = BpTree.Leaf.new(6, 4, ?[var ?(1, 1), ?(3, 3), ?(5, 5), ?(7, 7), null, null], gen_id);
                assert left.0[C.COUNT] == 4;

                let middle = BpTree.Leaf.new(6, 2, ?[var ?(9, 9), ?(11, 11), null, null, null, null], gen_id);
                assert middle.0[C.COUNT] == 2;

                let right = BpTree.Leaf.new(6, 6, ?[var ?(13, 13), ?(15, 15), ?(17, 17), ?(19, 19), ?(21, 21), ?(23, 23)], gen_id);
                assert right.0[C.COUNT] == 6;

                let parent = BpTree.Branch.new<Nat, Nat>(6, null, null, gen_id);
                BpTree.Branch.add_child(parent, #leaf(left));
                BpTree.Branch.add_child(parent, #leaf(middle));
                BpTree.Branch.add_child(parent, #leaf(right));

                assert parent.0[C.COUNT] == 3;
                assert parent.0[C.SUBTREE_SIZE] == 12;
                // assert Array.freeze(parent.2) == [?9, ?13, null, null, null];
                assert left.0[C.INDEX] == 0;
                assert middle.0[C.INDEX] == 1;
                assert right.0[C.INDEX] == 2;

                BpTree.Leaf.redistribute_keys(middle);

                assert left.0[C.COUNT] == 4;
                assert middle.0[C.COUNT] == 4;
                assert right.0[C.COUNT] == 4;

                assert Array.freeze(left.3) == [?(1, 1), ?(3, 3), ?(5, 5), ?(7, 7), null, null];
                assert Array.freeze(middle.3) == [?(9, 9), ?(11, 11), ?(13, 13), ?(15, 15), null, null];
                assert Array.freeze(right.3) == [?(17, 17), ?(19, 19), ?(21, 21), ?(23, 23), null, null];

                assert parent.0[C.COUNT] == 3;
                assert parent.0[C.SUBTREE_SIZE] == 12;
                // assert Array.freeze(parent.2) == [?9, ?17, null, null, null];
               
            },
        );

        test(
            "merge two leaf nodes",
            func() {
                let left = BpTree.Leaf.new(6, 2, ?[var ?(1, 1), ?(3, 3), null, null, null, null], gen_id);
                assert left.0[C.COUNT] == 2;

                let right = BpTree.Leaf.new(6, 2, ?[var ?(5, 5), ?(7, 7), null, null, null, null], gen_id);
                assert right.0[C.COUNT] == 2;

                let parent = BpTree.Branch.new<Nat, Nat>(6, null, null, gen_id);
                BpTree.Branch.add_child(parent, #leaf(left));
                BpTree.Branch.add_child(parent, #leaf(right));

                assert parent.0[C.SUBTREE_SIZE] == 4;
                assert parent.0[C.COUNT] == 2;
                // assert Array.freeze(parent.2) == [?5, null, null, null, null];
                assert left.0[C.INDEX] == 0;
                assert right.0[C.INDEX] == 1;

                BpTree.Leaf.merge(left, right);

                assert left.0[C.COUNT] == 4;

                assert Array.freeze(left.3) == [?(1, 1), ?(3, 3), ?(5, 5), ?(7, 7), null, null];

                assert parent.0[C.SUBTREE_SIZE] == 4;
                assert parent.0[C.COUNT] == 1;
                // assert Array.freeze(parent.2) == [null, null, null, null, null];
            },
        );
    },
);

suite(
    "split leaf node: even order",
    func() {
        test(
            "split and insert at end",
            func() {
                let kvs : [var ?(Nat, Nat)] = [var ?(1, 1), ?(3, 3), ?(5, 5), ?(7, 7), ?(9, 9), ?(11, 11)];
                let leaf = BpTree.Leaf.new(6, 6, ?kvs, gen_id);
                leaf.0[C.COUNT] := 6;

                let right = BpTree.Leaf.split<Nat, Nat>(leaf, 6, (13, 13), func() : Nat = 1);

                let left = leaf;

                assert left.0[C.COUNT] == 4;
                assert right.0[C.COUNT] == 3;

                assert Array.freeze(left.3) == [?(1, 1), ?(3, 3), ?(5, 5), ?(7, 7), null, null];
                assert Array.freeze(right.3) == [?(9, 9), ?(11, 11), ?(13, 13), null, null, null];

                assert left.0[C.INDEX] + 1 == right.0[C.INDEX];

            },
        );

        test(
            "split and insert at start",
            func() {
                let kvs : [var ?(Nat, Nat)] = [var ?(1, 1), ?(3, 3), ?(5, 5), ?(7, 7), ?(9, 9), ?(11, 11)];
                let leaf = BpTree.Leaf.new(6, 6, ?kvs, gen_id);
                leaf.0[C.COUNT] := 6;

                let right = BpTree.Leaf.split<Nat, Nat>(leaf, 0, (0, 0), func() : Nat = 1);

                let left = leaf;

                assert left.0[C.COUNT] == 4;
                assert right.0[C.COUNT] == 3;

                assert Array.freeze(left.3) == [?(0, 0), ?(1, 1), ?(3, 3), ?(5, 5), null, null];
                assert Array.freeze(right.3) == [?(7, 7), ?(9, 9), ?(11, 11), null, null, null];

                assert left.0[C.INDEX] + 1 == right.0[C.INDEX];

            },
        );

        test(
            "split and insert on left",
            func() {
                let kvs : [var ?(Nat, Nat)] = [var ?(1, 1), ?(3, 3), ?(5, 5), ?(7, 7), ?(9, 9), ?(11, 11)];
                let leaf = BpTree.Leaf.new(6, 6, ?kvs, gen_id);
                leaf.0[C.COUNT] := 6;

                let right = BpTree.Leaf.split<Nat, Nat>(leaf, 2, (4, 4), func() : Nat = 1);

                let left = leaf;

                assert left.0[C.COUNT] == 4;
                assert right.0[C.COUNT] == 3;

                assert Array.freeze(left.3) == [?(1, 1), ?(3, 3), ?(4, 4), ?(5, 5), null, null];
                assert Array.freeze(right.3) == [?(7, 7), ?(9, 9), ?(11, 11), null, null, null];

                assert left.0[C.INDEX] + 1 == right.0[C.INDEX];

            },
        );

        test(
            "split and insert on right",
            func() {
                let kvs : [var ?(Nat, Nat)] = [var ?(1, 1), ?(3, 3), ?(5, 5), ?(7, 7), ?(9, 9), ?(11, 11)];
                let leaf = BpTree.Leaf.new(6, 6, ?kvs, gen_id);
                leaf.0[C.COUNT] := 6;

                let right = BpTree.Leaf.split<Nat, Nat>(leaf, 5, (10, 10), func() : Nat = 1);

                let left = leaf;

                assert left.0[C.COUNT] == 4;
                assert right.0[C.COUNT] == 3;

                assert Array.freeze(left.3) == [?(1, 1), ?(3, 3), ?(5, 5), ?(7, 7), null, null];
                assert Array.freeze(right.3) == [?(9, 9), ?(10, 10), ?(11, 11), null, null, null];

                assert left.0[C.INDEX] + 1 == right.0[C.INDEX];

            },
        );

        test(
            "split and insert in middle",
            func() {
                let kvs : [var ?(Nat, Nat)] = [var ?(1, 1), ?(3, 3), ?(5, 5), ?(7, 7), ?(9, 9), ?(11, 11)];
                let leaf = BpTree.Leaf.new(6, 6, ?kvs, gen_id);
                leaf.0[C.COUNT] := 6;

                let right = BpTree.Leaf.split<Nat, Nat>(leaf, 3, (6, 6), func() : Nat = 1);

                let left = leaf;

                assert left.0[C.COUNT] == 4;
                assert right.0[C.COUNT] == 3;

                assert Array.freeze(left.3) == [?(1, 1), ?(3, 3), ?(5, 5), ?(6, 6), null, null];
                assert Array.freeze(right.3) == [?(7, 7), ?(9, 9), ?(11, 11), null, null, null];

                assert left.0[C.INDEX] + 1 == right.0[C.INDEX];

            },
        );
    },
);

suite(
    "split leaf node: odd order",
    func() {
        test(
            "split and insert at end",
            func() {
                let kvs : [var ?(Nat, Nat)] = [var ?(1, 1), ?(3, 3), ?(5, 5), ?(7, 7), ?(9, 9)];
                let leaf = BpTree.Leaf.new(5, 5, ?kvs, gen_id);
                assert leaf.0[C.COUNT] == 5;

                let right = BpTree.Leaf.split<Nat, Nat>(leaf, 5, (11, 11), func() : Nat = 1);

                let left = leaf;

                assert left.0[C.COUNT] == 3;
                assert right.0[C.COUNT] == 3;

                assert Array.freeze(left.3) == [?(1, 1), ?(3, 3), ?(5, 5), null, null];
                assert Array.freeze(right.3) == [?(7, 7), ?(9, 9), ?(11, 11), null, null];

                assert left.0[C.INDEX] + 1 == right.0[C.INDEX];

            },
        );

        test(
            "split and insert at start",
            func() {
                let kvs : [var ?(Nat, Nat)] = [var ?(1, 1), ?(3, 3), ?(5, 5), ?(7, 7), ?(9, 9)];
                let leaf = BpTree.Leaf.new(5, 5, ?kvs, gen_id);
                leaf.0[C.COUNT] := 5;

                let right = BpTree.Leaf.split<Nat, Nat>(leaf, 0, (0, 0), func() : Nat = 1);

                let left = leaf;

                assert left.0[C.COUNT] == 3;
                assert right.0[C.COUNT] == 3;

                assert Array.freeze(left.3) == [?(0, 0), ?(1, 1), ?(3, 3), null, null];
                assert Array.freeze(right.3) == [?(5, 5), ?(7, 7), ?(9, 9), null, null];

                assert left.0[C.INDEX] + 1 == right.0[C.INDEX];

            },
        );

        test(
            "split and insert on left",
            func() {
                let kvs : [var ?(Nat, Nat)] = [var ?(1, 1), ?(3, 3), ?(5, 5), ?(7, 7), ?(9, 9)];
                let leaf = BpTree.Leaf.new(5, 5, ?kvs, gen_id);
                leaf.0[C.COUNT] := 5;

                let right = BpTree.Leaf.split<Nat, Nat>(leaf, 1, (2, 2), func() : Nat = 1);

                let left = leaf;

                assert left.0[C.COUNT] == 3;
                assert right.0[C.COUNT] == 3;

                assert Array.freeze(left.3) == [?(1, 1), ?(2, 2), ?(3, 3), null, null];
                assert Array.freeze(right.3) == [?(5, 5), ?(7, 7), ?(9, 9), null, null];

                assert left.0[C.INDEX] + 1 == right.0[C.INDEX];

            },
        );

        test(
            "split and insert on right",
            func() {
                let kvs : [var ?(Nat, Nat)] = [var ?(1, 1), ?(3, 3), ?(5, 5), ?(7, 7), ?(9, 9)];
                let leaf = BpTree.Leaf.new(5, 5, ?kvs, gen_id);
                leaf.0[C.COUNT] := 5;

                let right = BpTree.Leaf.split<Nat, Nat>(leaf, 4, (8, 8), func() : Nat = 1);

                let left = leaf;

                assert left.0[C.COUNT] == 3;
                assert right.0[C.COUNT] == 3;

                assert Array.freeze(left.3) == [?(1, 1), ?(3, 3), ?(5, 5), null, null];
                assert Array.freeze(right.3) == [?(7, 7), ?(8, 8), ?(9, 9), null, null];

                assert left.0[C.INDEX] + 1 == right.0[C.INDEX];

            },
        );

        test(
            "split and insert in middle",
            func() {
                let kvs : [var ?(Nat, Nat)] = [var ?(1, 1), ?(3, 3), ?(5, 5), ?(7, 7), ?(9, 9)];
                let leaf = BpTree.Leaf.new(5, 5, ?kvs, gen_id);
                leaf.0[C.COUNT] := 5;

                let right = BpTree.Leaf.split<Nat, Nat>(leaf, 3, (6, 6), func() : Nat = 1);

                let left = leaf;

                assert left.0[C.COUNT] == 3;
                assert right.0[C.COUNT] == 3;

                assert Array.freeze(left.3) == [?(1, 1), ?(3, 3), ?(5, 5), null, null];
                assert Array.freeze(right.3) == [?(6, 6), ?(7, 7), ?(9, 9), null, null];

                assert left.0[C.INDEX] + 1 == right.0[C.INDEX];

            },
        );

    },
);

func c0() : BpTree.Leaf<Nat, Nat> = new_leaf(6, 1, 7);
func c2() : BpTree.Leaf<Nat, Nat> = new_leaf(6, 20, 26);
func c1() : BpTree.Leaf<Nat, Nat> = new_leaf(6, 10, 16);
func c3() : BpTree.Leaf<Nat, Nat> = new_leaf(6, 30, 36);
func c4() : BpTree.Leaf<Nat, Nat> = new_leaf(6, 40, 46);
func c5() : BpTree.Leaf<Nat, Nat> = new_leaf(6, 50, 56);
func c6() : BpTree.Leaf<Nat, Nat> = new_leaf(6, 60, 66);

func default_branch() : BpTree.Branch<Nat, Nat> {
    let children : [var BpTree.Node<Nat, Nat>] = [var #leaf(c0()), #leaf(c1()), #leaf(c2()), #leaf(c3()), #leaf(c4()), #leaf(c5())];

    let branch = BpTree.Branch.new<Nat, Nat>(6, null, null, gen_id);
    
    for (child in children.vals()){
        BpTree.Branch.add_child<Nat, Nat>(branch, child);
    };

    let keys = [?10, ?20, ?30, ?40, ?50];

    for (i in Iter.range(0, 4)){
        branch.2[i] := keys[i];
    };

    branch
   
};

suite(
    "split branch: even order",
    func() {
        test(
            "split and insert at end",
            func() {
                let node = default_branch();
                assert node.0[C.COUNT] == 6;
                assert node.0[C.SUBTREE_SIZE] == 36;

                let bptree : BpTree.BpTree<Nat, Nat> = to_bptree(6, node);
                assert BpTree.size(bptree) == 36;

                ignore BpTree.insert(bptree, Cmp.Nat, 60, 60);
                assert BpTree.size(bptree) == 37;

                let left = node;
                let ?parent = left.1[C.PARENT];
                let ? #branch(right) = parent.3[left.0[C.INDEX] + 1];

                assert left.0[C.COUNT] == 4;
                assert right.0[C.COUNT] == 3;

                assert left.0[C.SUBTREE_SIZE] == (4 * 6);
                assert right.0[C.SUBTREE_SIZE] == (2 * 6) + 1;

                assert Array.freeze(left.2) == [?10, ?20, ?30, null, null];
                assert Array.freeze(right.2) == [?50, ?54, null, null, null]; // key 30 get's added to the parent node
                // assert Array.freeze(parent.2) == [?40, null, null, null, null];

                assert validate_indexes<Nat, Nat>(left.3, left.0[C.COUNT]);
                assert validate_indexes<Nat, Nat>(right.3, right.0[C.COUNT]);

                let left_test = BpTree.Branch.new<Nat, Nat>(6, null, null, gen_id);
                BpTree.Branch.add_children(left_test, [#leaf(c0()), #leaf(c1()), #leaf(c2()), #leaf(c3())]);

                assert BpTree.Branch.equal<Nat, Nat>(left, left_test, Cmp.Nat);

                let right_test = BpTree.Branch.new<Nat, Nat>(6, null, null, gen_id);
                BpTree.Branch.add_children(right_test, [#leaf(c4()), #leaf(c5()), #leaf(new_leaf(6, 54, 54 + 3))]);

                assert BpTree.Branch.equal<Nat, Nat>(right, right_test, Cmp.Nat);
               
            },
        );

        test(
            "split and insert at start",
            func() {
                let node = default_branch();

                assert node.0[C.COUNT] == 6;
                assert node.0[C.SUBTREE_SIZE] == 6 * 6;

                let bptree : BpTree.BpTree<Nat, Nat> = to_bptree(6, node);
                assert BpTree.size(bptree) == 6 * 6;

                ignore BpTree.insert(bptree, Cmp.Nat, 0, 0);
                let left = node;
                let ?parent = left.1[C.PARENT];
                let ? #branch(right) = parent.3[left.0[C.INDEX] + 1];

                assert left.0[C.COUNT] == 4;
                assert right.0[C.COUNT] == 3;

                assert left.0[C.SUBTREE_SIZE] == (3 * 6) + 1;
                assert right.0[C.SUBTREE_SIZE] == 3 * 6;

                assert Array.freeze(left.2) == [?4, ?10, ?20, null, null];
                assert Array.freeze(right.2) == [?40, ?50, null, null, null]; // key 30 get's added to the parent node
                // assert Array.freeze(parent.2) == [?30, null, null, null, null];

                assert validate_indexes<Nat, Nat>(left.3, left.0[C.COUNT]);
                assert validate_indexes<Nat, Nat>(right.3, right.0[C.COUNT]);

                let left_test = BpTree.Branch.new<Nat, Nat>(6, null, null, gen_id);
                BpTree.Branch.add_children(left_test, [#leaf(new_leaf(6, 0, 4)), #leaf(new_leaf(6, 4, 7)), #leaf(c1()), #leaf(c2())]);
                assert BpTree.Branch.equal<Nat, Nat>(left, left_test, Cmp.Nat);

                let right_test = BpTree.Branch.new<Nat, Nat>(6, null,  null, gen_id);
                BpTree.Branch.add_children(right_test, [#leaf(c3()), #leaf(c4()), #leaf(c5())]);
                assert BpTree.Branch.equal<Nat, Nat>(right, right_test, Cmp.Nat);

            },
        );

        test(
            "split and insert on left",
            func() {
                let node = default_branch();

                assert node.0[C.COUNT] == 6;
                assert node.0[C.SUBTREE_SIZE] == 6 * 6;

                let bptree : BpTree.BpTree<Nat, Nat> = to_bptree(6, node);
                assert BpTree.size(bptree) == 6 * 6;

                ignore BpTree.insert(bptree, Cmp.Nat, 16, 16);
                let left = node;
                let ?parent = left.1[C.PARENT];
                let ? #branch(right) = parent.3[left.0[C.INDEX] + 1];

                assert left.0[C.COUNT] == 4;
                assert right.0[C.COUNT] == 3;

                assert left.0[C.SUBTREE_SIZE] == (3 * 6) + 1;
                assert right.0[C.SUBTREE_SIZE] == 3 * 6;

                assert Array.freeze(left.2) == [?10, ?14, ?20, null, null];
                assert Array.freeze(right.2) == [?40, ?50, null, null, null]; // key 30 get's added to the parent node
                // assert Array.freeze(parent.2) == [?30, null, null, null, null];

                assert validate_indexes<Nat, Nat>(left.3, left.0[C.COUNT]);
                assert validate_indexes<Nat, Nat>(right.3, right.0[C.COUNT]);

                let left_test = BpTree.Branch.new<Nat, Nat>(6, null, null, gen_id);
                BpTree.Branch.add_children(left_test, [#leaf(c0()), #leaf(new_leaf(6, 10, 14)), #leaf(new_leaf(6, 14, 17)), #leaf(c2())]);
                assert BpTree.Branch.equal<Nat, Nat>(left, left_test, Cmp.Nat);

                let right_test = BpTree.Branch.new<Nat, Nat>(6, null, null, gen_id);
                BpTree.Branch.add_children(right_test, [#leaf(c3()), #leaf(c4()), #leaf(c5())]);
                assert BpTree.Branch.equal<Nat, Nat>(right, right_test, Cmp.Nat);
               
            },
        );

        test(
            "split and insert on right",
            func() {
                let node = default_branch();

                assert node.0[C.COUNT] == 6;
                assert node.0[C.SUBTREE_SIZE] == 6 * 6;

                let bptree : BpTree.BpTree<Nat, Nat> = to_bptree(6, node);
                assert BpTree.size(bptree) == 6 * 6;

                ignore BpTree.insert(bptree, Cmp.Nat, 46, 46);
                let left = node;
                let ?parent = left.1[C.PARENT];
                let ? #branch(right) = parent.3[left.0[C.INDEX] + 1];

                assert left.0[C.COUNT] == 4;
                assert right.0[C.COUNT] == 3;

                assert left.0[C.SUBTREE_SIZE] == (4 * 6);
                assert right.0[C.SUBTREE_SIZE] == (2 * 6) + 1;

                assert Array.freeze(left.2) == [?10, ?20, ?30, null, null];
                assert Array.freeze(right.2) == [?44, ?50, null, null, null]; // key 30 get's added to the parent node
                // assert Array.freeze(parent.2) == [?40, null, null, null, null];

                assert validate_indexes<Nat, Nat>(left.3, left.0[C.COUNT]);
                assert validate_indexes<Nat, Nat>(right.3, right.0[C.COUNT]);

                let left_test = BpTree.Branch.new<Nat, Nat>(6, null, null, gen_id);
                BpTree.Branch.add_children(left_test, [#leaf(c0()), #leaf(c1()), #leaf(c2()), #leaf(c3())]);
                assert BpTree.Branch.equal<Nat, Nat>(left, left_test, Cmp.Nat);

                let right_test = BpTree.Branch.new<Nat, Nat>(6, null, null, gen_id);
                BpTree.Branch.add_children(right_test, [ #leaf(new_leaf(6, 40, 44)), #leaf(new_leaf(6, 44, 47)), #leaf(c5())]);
                assert BpTree.Branch.equal<Nat, Nat>(right, right_test, Cmp.Nat);
               
            },
        );

        test(
            "split and insert in middle",
            func() {
                let children : [var ?BpTree.Node<Nat, Nat>] = [var ? #leaf(c0()), ? #leaf(c1()), ? #leaf(c2()), ? #leaf(c3()), ? #leaf(c4()), ? #leaf(c5())];

                let node = BpTree.Branch.new<Nat, Nat>(6, null, ?children, gen_id);
                assert node.0[C.COUNT] == 6;
                assert node.0[C.SUBTREE_SIZE] == 6 * 6;

                let bptree : BpTree.BpTree<Nat, Nat> = to_bptree(6, node);
                assert BpTree.size(bptree) == 6 * 6;

                ignore BpTree.insert(bptree, Cmp.Nat, 26, 26);
                let left = node;
                let ?parent = left.1[C.PARENT];
                let ? #branch(right) = parent.3[left.0[C.INDEX] + 1];

                assert left.0[C.COUNT] == 4;
                assert right.0[C.COUNT] == 3;

                assert left.0[C.SUBTREE_SIZE] == (3 * 6) + 1;
                assert right.0[C.SUBTREE_SIZE] == 3 * 6;

                assert Array.freeze(left.2) == [?10, ?20, ?24, null, null];
                assert Array.freeze(right.2) == [?40, ?50, null, null, null]; // key 30 get's added to the parent node
                // assert Array.freeze(parent.2) == [?30, null, null, null, null];

                assert validate_indexes<Nat, Nat>(left.3, left.0[C.COUNT]);
                assert validate_indexes<Nat, Nat>(right.3, right.0[C.COUNT]);

                let left_test = BpTree.Branch.new<Nat, Nat>(6, null, null, gen_id);
                BpTree.Branch.add_children(left_test, [#leaf(c0()), #leaf(c1()), #leaf(c2()), #leaf(new_leaf(6, 24, 24 + 3))]);
                assert BpTree.Branch.equal<Nat, Nat>(left, left_test, Cmp.Nat);

                let right_test = BpTree.Branch.new<Nat, Nat>(6, null, null, gen_id);
                BpTree.Branch.add_children(right_test, [#leaf(c3()), #leaf(c4()), #leaf(c5())]);
                assert BpTree.Branch.equal<Nat, Nat>(right, right_test, Cmp.Nat);
               
            },
        );
    },

);

// suite(
//     "split branch: odd order",
//     func (){
//         let c0() = new_leaf(6, 0, 6);
//         let c1() = new_leaf(6, 6, 12);
//         let c2() = new_leaf(6, 12, 18);
//         let c3() = new_leaf(6, 18, 24);
//         let c4() = new_leaf(6, 24, 30);
//         let c5() = new_leaf(6, 30, 36);

//         test (
//             "split and insert at end",
//             func (){
//                 let children : [var ?BpTree.Node<Nat, Nat>] = [var ? #leaf(c0()), ? #leaf(c1()), ? #leaf(c2()), ? #leaf(c3()), ? #leaf(c4())];
//                 let node = BpTree.Branch.new<, gen_idNat, Nat>(5, ?children);
//                 let right = BpTree.Branch.split(node, #leaf(c5()), 5, 30);

//                 let left = node;

//                 assert left.0[C.COUNT] == 3;
//                 assert right.0[C.COUNT] == 3;

//                 assert Array.freeze(left.2) == [?6, ?12, null, null];
//                 assert Array.freeze(right.2) == [?24, ?30, null, ?18];

//                 assert validate_indexes<Nat, Nat>(left.3, left.0[C.COUNT]);
//                 assert validate_indexes<Nat, Nat>(right.3, right.0[C.COUNT]);

//                 let left_test = BpTree.Branch.new<, gen_idNat, Nat>(5, ?[var ? #leaf(c0()), ? #leaf(c1()), ? #leaf(c2()), null, null]);
//                 assert BpTree.Branch.equal<Nat, Nat>(left, left_test, Cmp.Nat);

//                 let right_test = BpTree.Branch.new<, gen_idNat, Nat>(5, ?[var ? #leaf(c3()), ? #leaf(c4()), ? #leaf(c5()), null, null]);
//                 assert BpTree.Branch.equal<Nat, Nat>(right, right_test, Cmp.Nat);
//             }
//         );
//     }
// );

// suite(
//     "split nested branch: even order",
//     func() {
//         let c0() = new_branch(6, 0);   // 0 - 36
//         let c1() = new_branch(6, 100); // 100 - 136
//         let c2() = new_branch(6, 200);
//         let c3() = new_branch(6, 300);
//         let c4() = new_branch(6, 400);
//         let c5() = new_branch(6, 500);
//         let c6() = new_branch(6, 600);

//         test(
//             "split and insert at end",
//             func (){
//                 let children : [var ?BpTree.Node<Nat, Nat>] = [var ? #branch(c0()), ? #branch(c1()), ? #branch(c2()), ? #branch(c3()), ? #branch(c4()), ? #branch(c5())];
//                 let branch = BpTree.Branch.new<, gen_idNat, Nat>(6, ?children);

//                 assert branch.0[C.COUNT] == 6;

//                 assert branch.0[C.SUBTREE_SIZE] == 6 ** 3; // each leaf has 6 element and each branch has 6 elements, with 3 levels we get 6 ** 3

//                 let bptree : BpTree.BpTree<Nat, Nat> = {
//                     order = 6;
//                     var root = #branch(branch);
//                     var size = branch.0[C.SUBTREE_SIZE];
//                 };

//                 ignore BpTree.insert(bptree, Cmp.Nat, 228, 228);

//                 // let right = BpTree.Branch.split(branch, #branch(c6()), 6, 36);
//                 let left = branch;
//                 let ?#branch(right) = do ? {branch.1[C.PARENT]!.3[left.0[C.INDEX] + 1]!};

//                 assert left.0[C.COUNT] == 4;
//                 assert right.0[C.COUNT] == 3;

//                 assert left.0[C.SUBTREE_SIZE] == 4 * 6;
//                 assert right.0[C.SUBTREE_SIZE] == 3 * 6;

//                 assert Array.freeze(left.2) == [?100, ?200, ?224, null, null];
//                 assert Array.freeze(right.2) == [?400, ?500, null, null, ?300];

//                 assert validate_indexes<Nat, Nat>(left.3, left.0[C.COUNT]);
//                 assert validate_indexes<Nat, Nat>(right.3, right.0[C.COUNT]);

//                 let left_test = BpTree.Branch.new<, gen_idNat, Nat>(6, ?[var ? #branch(c0()), ? #branch(c1()), ? #branch(c2()), ? #branch(c3()), null, null]);
//                 assert BpTree.Branch.equal<Nat, Nat>(left, left_test, Cmp.Nat);

//                 let right_test = BpTree.Branch.new<, gen_idNat, Nat>(6, ?[var ? #branch(c4()), ? #branch(c5()), ? #branch(c6()), null, null, null]);
//                 assert BpTree.Branch.equal<Nat, Nat>(right, right_test, Cmp.Nat);

//             }
//         );

//         test(
//             "split and insert at start",
//             func() {
//                 let children : [var ?BpTree.Node<Nat, Nat>] = [var ? #branch(c1()), ? #branch(c2()), ? #branch(c3()), ? #branch(c4()), ? #branch(c5()), ? #branch(c6()),];

//                 let node = BpTree.Branch.new<, gen_idNat, Nat>(6, ?children);
//                 assert node.0[C.COUNT] == 6;
//                 assert node.0[C.SUBTREE_SIZE] == 6 * 6;

//                 assert Array.freeze(node.2) == [?12, ?18, ?24, ?30, ?36];

//                 let right = BpTree.Branch.split(node, #branch(c0()), 0, 0);
//                 let left = node;

//                 assert left.0[C.COUNT] == 4;
//                 assert right.0[C.COUNT] == 3;

//                 assert left.0[C.SUBTREE_SIZE] == 4 * 6;
//                 assert right.0[C.SUBTREE_SIZE] == 3 * 6;

//                 assert Array.freeze(left.2) == [?6, ?12, ?18, null, null];
//                 assert Array.freeze(right.2) == [?30, ?36, null, null, ?24];

//                 assert validate_indexes<Nat, Nat>(left.3, left.0[C.COUNT]);
//                 assert validate_indexes<Nat, Nat>(right.3, right.0[C.COUNT]);

//                 let left_test = BpTree.Branch.new<, gen_idNat, Nat>(6, ?[var ? #branch(c0()), ? #branch(c1()), ? #branch(c2()), ? #branch(c3()), null, null]);
//                 assert BpTree.Branch.equal<Nat, Nat>(left, left_test, Cmp.Nat);

//                 let right_test = BpTree.Branch.new<, gen_idNat, Nat>(6, ?[var ? #branch(c4()), ? #branch(c5()), ? #branch(c6()), null, null, null]);
//                 assert BpTree.Branch.equal<Nat, Nat>(right, right_test, Cmp.Nat);
//             },
//         );

//         test(
//             "split and insert on left",
//             func() {
//                 let children : [var ?BpTree.Node<Nat, Nat>] = [var ? #branch(c0()), ? #branch(c2()), ? #branch(c3()), ? #branch(c4()), ? #branch(c5()), ? #branch(c6()),];

//                 let node = BpTree.Branch.new<, gen_idNat, Nat>(6, ?children);
//                 assert node.0[C.COUNT] == 6;
//                 assert node.0[C.SUBTREE_SIZE] == 6 * 6;

//                 assert Array.freeze(node.2) == [?12, ?18, ?24, ?30, ?36];

//                 let right = BpTree.Branch.split(node, #branch(c1()), 1, 6);
//                 let left = node;

//                 assert left.0[C.COUNT] == 4;
//                 assert right.0[C.COUNT] == 3;

//                 assert left.0[C.SUBTREE_SIZE] == 4 * 6;
//                 assert right.0[C.SUBTREE_SIZE] == 3 * 6;

//                 assert Array.freeze(left.2) == [?6, ?12, ?18, null, null];
//                 assert Array.freeze(right.2) == [?30, ?36, null, null, ?24];

//                 assert validate_indexes<Nat, Nat>(left.3, left.0[C.COUNT]);
//                 assert validate_indexes<Nat, Nat>(right.3, right.0[C.COUNT]);

//                 let left_test = BpTree.Branch.new<, gen_idNat, Nat>(6, ?[var ? #branch(c0()), ? #branch(c1()), ? #branch(c2()), ? #branch(c3()), null, null]);
//                 assert BpTree.Branch.equal<Nat, Nat>(left, left_test, Cmp.Nat);

//                 let right_test = BpTree.Branch.new<, gen_idNat, Nat>(6, ?[var ? #branch(c4()), ? #branch(c5()), ? #branch(c6()), null, null, null]);
//                 assert BpTree.Branch.equal<Nat, Nat>(right, right_test, Cmp.Nat);
//             },
//         );

//         test(
//             "split and insert on right",
//             func() {
//                 let children : [var ?BpTree.Node<Nat, Nat>] = [var ? #branch(c0()), ? #branch(c1()), ? #branch(c2()), ? #branch(c3()), ? #branch(c4()), ? #branch(c6())];
//                 let node = BpTree.Branch.new<, gen_idNat, Nat>(6, ?children);
//                 let right = BpTree.Branch.split(node, #branch(c5()), 5, 30);

//                 let left = node;

//                 assert left.0[C.COUNT] == 4;
//                 assert right.0[C.COUNT] == 3;

//                 assert left.0[C.SUBTREE_SIZE] == 4 * 6;
//                 assert right.0[C.SUBTREE_SIZE] == 3 * 6;

//                 assert Array.freeze(left.2) == [?6, ?12, ?18, null, null];
//                 assert Array.freeze(right.2) == [?30, ?36, null, null, ?24];

//                 assert validate_indexes<Nat, Nat>(left.3, left.0[C.COUNT]);
//                 assert validate_indexes<Nat, Nat>(right.3, right.0[C.COUNT]);

//                 let left_test = BpTree.Branch.new<, gen_idNat, Nat>(6, ?[var ? #branch(c0()), ? #branch(c1()), ? #branch(c2()), ? #branch(c3()), null, null]);
//                 assert BpTree.Branch.equal<Nat, Nat>(left, left_test, Cmp.Nat);

//                 let right_test = BpTree.Branch.new<, gen_idNat, Nat>(6, ?[var ? #branch(c4()), ? #branch(c5()), ? #branch(c6()), null, null, null]);
//                 assert BpTree.Branch.equal<Nat, Nat>(right, right_test, Cmp.Nat);
//             },
//         );

//         test (
//             "split and insert in middle",
//             func() {
//                 let children : [var ?BpTree.Node<Nat, Nat>] = [var ? #branch(c0()), ? #branch(c1()), ?#branch(c2()), ? #branch(c4()), ? #branch(c5()), ? #branch(c6())];
//                 let node : BpTree.Branch<Nat, Nat> = BpTree.Branch.new<, gen_idNat, Nat>(6, ?children);
//                 let right : BpTree.Branch<Nat, Nat> = BpTree.Branch.split(node, #branch(c3()), 3, 18);

//                 let left = node;

//                 assert left.0[C.COUNT] == 4;
//                 assert right.0[C.COUNT] == 3;

//                 assert left.0[C.SUBTREE_SIZE] == 4 * 6;
//                 assert right.0[C.SUBTREE_SIZE] == 3 * 6;

//                 assert Array.freeze(left.2) == [?6, ?12, ?18, null, null];
//                 assert Array.freeze(right.2) == [?30, ?36, null, null, ?24];

//                 assert validate_indexes<Nat, Nat>(left.3, left.0[C.COUNT]);
//                 assert validate_indexes<Nat, Nat>(right.3, right.0[C.COUNT]);

//                 let left_test = BpTree.Branch.new<, gen_idNat, Nat>(6, ?[var ? #branch(c0()), ? #branch(c1()), ? #branch(c2()), ? #branch(c3()), null, null]);
//                 assert BpTree.Branch.equal<Nat, Nat>(left, left_test, Cmp.Nat);

//                 let right_test = BpTree.Branch.new<, gen_idNat, Nat>(6, ?[var ? #branch(c4()), ? #branch(c5()), ? #branch(c6()), null, null, null]);
//                 assert BpTree.Branch.equal<Nat, Nat>(right, right_test, Cmp.Nat);
//             },
//         );
//     }
// );
