import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";
import { test; suite } "mo:test";
import Itertools "mo:itertools/Iter";

import { BpTree; Leaf; Branch } "../src";

func new_leaf(start : Nat, end : Nat) : BpTree.Leaf<Nat, Nat> {
    let size = end - start : Nat;
    let kvs = Array.tabulateVar<?(Nat, Nat)>(
        size,
        func(i : Nat) : ?(Nat, Nat) {
            return ?(start + i, start + i);
        },
    );

    let leaf = BpTree.Leaf.new(6, ?kvs);
};

func new_branch(start: Nat, end: Nat) : BpTree.Branch<Nat, Nat>{
    let size = end - start : Nat;

    let children = Array.tabulateVar<?BpTree.Node<Nat, Nat>>(
        size,
        func(i : Nat) : ?BpTree.Node<Nat, Nat> {
            return ? #leaf(new_leaf(start, start + 1));
        },
    );

    let branch = BpTree.Branch.new(6, ?children);
};

suite(
    "split nested branch: even order",
    func() {
        let c0 = new_branch(0, 6);
        let c1 = new_branch(6, 12);
        let c2 = new_branch(12, 18);
        let c3 = new_branch(18, 24);
        let c4 = new_branch(24, 30);
        let c5 = new_branch(30, 36);
        let c6 = new_branch(36, 42);

        test(
            "split and insert at end",
            func (){
                let children : [var ?BpTree.Node<Nat, Nat>] = [var ? #branch(c0), ? #branch(c1), ? #branch(c2), ? #branch(c3), ? #branch(c4), ? #branch(c5)];
                let branch = BpTree.Branch.new<Nat, Nat>(6, ?children);

                assert branch.count == 6;
                
                let right = BpTree.split_branch<Nat, Nat>(branch, #branch(c6), 6, 36);
                let left = branch;
                
                assert left.count == 4;
                assert right.count == 3;

                assert Array.freeze(left.keys) == [?6, ?12, ?18, null, null];
                assert Array.freeze(right.keys) == [?30, ?36, null, null, ?24];

                Debug.print("left " # debug_show BpTree.indexes(left.children));
                Debug.print("right " # debug_show BpTree.indexes(right.children));
                assert BpTree.validate_indexes<Nat, Nat>(left.children, left.count);
                assert BpTree.validate_indexes<Nat, Nat>(right.children, right.count);

                let left_test = BpTree.Branch.new<Nat, Nat>(6, ?[var ? #branch(c0), ? #branch(c1), ? #branch(c2), ? #branch(c3), null, null]);
                assert BpTree.Branch.equal<Nat, Nat>(left, left_test, Nat.compare);

                let right_test = BpTree.Branch.new<Nat, Nat>(6, ?[var ? #branch(c4), ? #branch(c5), ? #branch(c6), null, null, null]);
                assert BpTree.Branch.equal<Nat, Nat>(right, right_test, Nat.compare);

            }
        );

        test(
            "split and insert at start",
            func() {
                let children : [var ?BpTree.Node<Nat, Nat>] = [var ? #branch(c1), ? #branch(c2), ? #branch(c3), ? #branch(c4), ? #branch(c5), ? #branch(c6),];

                let node = BpTree.Branch.new<Nat, Nat>(6, ?children);
                assert node.count == 6;

                assert Array.freeze(node.keys) == [?12, ?18, ?24, ?30, ?36];

                let right = BpTree.split_branch<Nat, Nat>(node, #branch(c0), 0, 0);
                let left = node;

                assert left.count == 4;
                assert right.count == 3;

                assert Array.freeze(left.keys) == [?6, ?12, ?18, null, null];
                assert Array.freeze(right.keys) == [?30, ?36, null, null, ?24];

                assert BpTree.validate_indexes<Nat, Nat>(left.children, left.count);
                assert BpTree.validate_indexes<Nat, Nat>(right.children, right.count);


                let left_test = BpTree.Branch.new<Nat, Nat>(6, ?[var ? #branch(c0), ? #branch(c1), ? #branch(c2), ? #branch(c3), null, null]);
                assert BpTree.Branch.equal<Nat, Nat>(left, left_test, Nat.compare);

                let right_test = BpTree.Branch.new<Nat, Nat>(6, ?[var ? #branch(c4), ? #branch(c5), ? #branch(c6), null, null, null]);
                assert BpTree.Branch.equal<Nat, Nat>(right, right_test, Nat.compare);
            },
        );

        test(
            "split and insert on left",
            func() {
                let children : [var ?BpTree.Node<Nat, Nat>] = [var ? #branch(c0), ? #branch(c2), ? #branch(c3), ? #branch(c4), ? #branch(c5), ? #branch(c6),];

                let node = BpTree.Branch.new<Nat, Nat>(6, ?children);
                assert node.count == 6;

                assert Array.freeze(node.keys) == [?12, ?18, ?24, ?30, ?36];

                let right = BpTree.split_branch<Nat, Nat>(node, #branch(c1), 1, 6);
                let left = node;

                assert left.count == 4;
                assert right.count == 3;

                Debug.print("left " # debug_show Array.freeze(left.keys));
                Debug.print("right " # debug_show Array.freeze(right.keys));

                assert Array.freeze(left.keys) == [?6, ?12, ?18, null, null];
                assert Array.freeze(right.keys) == [?30, ?36, null, null, ?24];
                
                assert BpTree.validate_indexes<Nat, Nat>(left.children, left.count);
                assert BpTree.validate_indexes<Nat, Nat>(right.children, right.count);

                let left_test = BpTree.Branch.new<Nat, Nat>(6, ?[var ? #branch(c0), ? #branch(c1), ? #branch(c2), ? #branch(c3), null, null]);
                assert BpTree.Branch.equal<Nat, Nat>(left, left_test, Nat.compare);

                let right_test = BpTree.Branch.new<Nat, Nat>(6, ?[var ? #branch(c4), ? #branch(c5), ? #branch(c6), null, null, null]);
                assert BpTree.Branch.equal<Nat, Nat>(right, right_test, Nat.compare);
            },
        );

        test(
            "split and insert on right",
            func() {
                let children : [var ?BpTree.Node<Nat, Nat>] = [var ? #branch(c0), ? #branch(c1), ? #branch(c2), ? #branch(c3), ? #branch(c4), ? #branch(c6)];
                let node = BpTree.Branch.new<Nat, Nat>(6, ?children);
                let right = BpTree.split_branch<Nat, Nat>(node, #branch(c5), 5, 30);

                let left = node;

                assert left.count == 4;
                assert right.count == 3;
                
                assert Array.freeze(left.keys) == [?6, ?12, ?18, null, null];
                assert Array.freeze(right.keys) == [?30, ?36, null, null, ?24];

                assert BpTree.validate_indexes<Nat, Nat>(left.children, left.count);
                assert BpTree.validate_indexes<Nat, Nat>(right.children, right.count);

                let left_test = BpTree.Branch.new<Nat, Nat>(6, ?[var ? #branch(c0), ? #branch(c1), ? #branch(c2), ? #branch(c3), null, null]);
                assert BpTree.Branch.equal<Nat, Nat>(left, left_test, Nat.compare);

                let right_test = BpTree.Branch.new<Nat, Nat>(6, ?[var ? #branch(c4), ? #branch(c5), ? #branch(c6), null, null, null]);
                assert BpTree.Branch.equal<Nat, Nat>(right, right_test, Nat.compare);
            },
        );

        test (
            "split and insert in middle",
            func() {
                let children : [var ?BpTree.Node<Nat, Nat>] = [var ? #branch(c0), ? #branch(c1), ?#branch(c2), ? #branch(c4), ? #branch(c5), ? #branch(c6)];
                let node : BpTree.Branch<Nat, Nat> = BpTree.Branch.new<Nat, Nat>(6, ?children);
                let right : BpTree.Branch<Nat, Nat> = BpTree.split_branch<Nat, Nat>(node, #branch(c3), 3, 18);

                let left = node;

                assert left.count == 4;
                assert right.count == 3;

                assert Array.freeze(left.keys) == [?6, ?12, ?18, null, null];
                assert Array.freeze(right.keys) == [?30, ?36, null, null, ?24];

                assert BpTree.validate_indexes<Nat, Nat>(left.children, left.count);
                assert BpTree.validate_indexes<Nat, Nat>(right.children, right.count);

                let left_test = BpTree.Branch.new<Nat, Nat>(6, ?[var ? #branch(c0), ? #branch(c1), ? #branch(c2), ? #branch(c3), null, null]);
                assert BpTree.Branch.equal<Nat, Nat>(left, left_test, Nat.compare);

                let right_test = BpTree.Branch.new<Nat, Nat>(6, ?[var ? #branch(c4), ? #branch(c5), ? #branch(c6), null, null, null]);
                assert BpTree.Branch.equal<Nat, Nat>(right, right_test, Nat.compare);
            },
        );
    }
);

suite(
    "split branch: even order",
    func() {
        let c0 = new_leaf(0, 6);
        let c1 = new_leaf(6, 12);
        let c2 = new_leaf(12, 18);
        let c3 = new_leaf(18, 24);
        let c4 = new_leaf(24, 30);
        let c5 = new_leaf(30, 36);
        let c6 = new_leaf(36, 42);

        test(
            "split and insert at end",
            func() {
                let children : [var ?BpTree.Node<Nat, Nat>] = [var ? #leaf(c0), ? #leaf(c1), ? #leaf(c2), ? #leaf(c3), ? #leaf(c4), ? #leaf(c5)];

                let node = BpTree.Branch.new<Nat, Nat>(6, ?children);
                assert node.count == 6;

                let right = BpTree.split_branch<Nat, Nat>(node, #leaf(c6), 6, 36);
                let left = node;

                assert left.count == 4;
                assert right.count == 3;

                Debug.print("left " # debug_show Array.freeze(left.keys));
                Debug.print("right " # debug_show Array.freeze(right.keys));
                assert Array.freeze(left.keys) == [?6, ?12, ?18, null, null];
                assert Array.freeze(right.keys) == [?30, ?36, null, null, ?24]; // key 24 get's added to the parent node

                assert BpTree.validate_indexes<Nat, Nat>(left.children, left.count);
                assert BpTree.validate_indexes<Nat, Nat>(right.children, right.count);


                let left_test = BpTree.Branch.new<Nat, Nat>(6, ?[var ? #leaf(c0), ? #leaf(c1), ? #leaf(c2), ? #leaf(c3), null, null]);
                assert BpTree.Branch.equal<Nat, Nat>(left, left_test, Nat.compare);

                let right_test = BpTree.Branch.new<Nat, Nat>(6, ?[var ? #leaf(c4), ? #leaf(c5), ? #leaf(c6), null, null, null]);
                assert BpTree.Branch.equal<Nat, Nat>(right, right_test, Nat.compare);
            },
        );

        test(
            "split and insert at start",
            func() {
                let children : [var ?BpTree.Node<Nat, Nat>] = [var ? #leaf(c1), ? #leaf(c2), ? #leaf(c3), ? #leaf(c4), ? #leaf(c5), ? #leaf(c6)];

                let node = BpTree.Branch.new<Nat, Nat>(6, ?children);
                assert node.count == 6;

                let right = BpTree.split_branch<Nat, Nat>(node, #leaf(c0), 0, 0);
                let left = node;

                assert left.count == 4;
                assert right.count == 3;

                assert Array.freeze(left.keys) == [?6, ?12, ?18, null, null];
                assert Array.freeze(right.keys) == [?30, ?36, null, null, ?24];

                assert BpTree.validate_indexes<Nat, Nat>(left.children, left.count);
                assert BpTree.validate_indexes<Nat, Nat>(right.children, right.count);


                let left_test = BpTree.Branch.new<Nat, Nat>(6, ?[var ? #leaf(c0), ? #leaf(c1), ? #leaf(c2), ? #leaf(c3), null, null]);
                assert BpTree.Branch.equal<Nat, Nat>(left, left_test, Nat.compare);

                let right_test = BpTree.Branch.new<Nat, Nat>(6, ?[var ? #leaf(c4), ? #leaf(c5), ? #leaf(c6), null, null, null]);
                assert BpTree.Branch.equal<Nat, Nat>(right, right_test, Nat.compare);

            },
        );

        test(
            "split and insert on left",
            func() {
                let children : [var ?BpTree.Node<Nat, Nat>] = [var ? #leaf(c0), ? #leaf(c2), ? #leaf(c3), ? #leaf(c4), ? #leaf(c5), ? #leaf(c6)];

                let node = BpTree.Branch.new<Nat, Nat>(6, ?children);
                assert node.count == 6;

                let right = BpTree.split_branch<Nat, Nat>(node, #leaf(c1), 1, 6);
                let left = node;

                assert left.count == 4;
                assert right.count == 3;

                assert Array.freeze(left.keys) == [?6, ?12, ?18, null, null];
                assert Array.freeze(right.keys) == [?30, ?36, null, null, ?24];

                assert BpTree.validate_indexes<Nat, Nat>(left.children, left.count);
                assert BpTree.validate_indexes<Nat, Nat>(right.children, right.count);


                let left_test = BpTree.Branch.new<Nat, Nat>(6, ?[var ? #leaf(c0), ? #leaf(c1), ? #leaf(c2), ? #leaf(c3), null, null]);
                assert BpTree.Branch.equal<Nat, Nat>(left, left_test, Nat.compare);

                let right_test = BpTree.Branch.new<Nat, Nat>(6, ?[var ? #leaf(c4), ? #leaf(c5), ? #leaf(c6), null, null, null]);
                assert BpTree.Branch.equal<Nat, Nat>(right, right_test, Nat.compare);
            },
        );

        test(
            "split and insert on right",
            func() {
                let children : [var ?BpTree.Node<Nat, Nat>] = [var ? #leaf(c0), ? #leaf(c1), ? #leaf(c2), ? #leaf(c3), ? #leaf(c4), ? #leaf(c6)];
                let node = BpTree.Branch.new<Nat, Nat>(6, ?children);
                let right = BpTree.split_branch<Nat, Nat>(node, #leaf(c5), 5, 30);

                let left = node;

                assert left.count == 4;
                assert right.count == 3;

                assert Array.freeze(left.keys) == [?6, ?12, ?18, null, null];
                assert Array.freeze(right.keys) == [?30, ?36, null, null, ?24];

                assert BpTree.validate_indexes<Nat, Nat>(left.children, left.count);
                assert BpTree.validate_indexes<Nat, Nat>(right.children, right.count);


                let left_test = BpTree.Branch.new<Nat, Nat>(6, ?[var ? #leaf(c0), ? #leaf(c1), ? #leaf(c2), ? #leaf(c3), null, null]);
                assert BpTree.Branch.equal<Nat, Nat>(left, left_test, Nat.compare);

                let right_test = BpTree.Branch.new<Nat, Nat>(6, ?[var ? #leaf(c4), ? #leaf(c5), ? #leaf(c6), null, null, null]);
                assert BpTree.Branch.equal<Nat, Nat>(right, right_test, Nat.compare);
            },
        );

        test (
            "split and insert in middle",
            func() {
                let children : [var ?BpTree.Node<Nat, Nat>] = [var ? #leaf(c0), ? #leaf(c1), ?#leaf(c2), ? #leaf(c4), ? #leaf(c5), ? #leaf(c6)];
                let node = BpTree.Branch.new<Nat, Nat>(6, ?children);
                let right = BpTree.split_branch<Nat, Nat>(node, #leaf(c3), 3, 18);

                let left = node;

                assert left.count == 4;
                assert right.count == 3;

                assert Array.freeze(left.keys) == [?6, ?12, ?18, null, null];
                assert Array.freeze(right.keys) == [?30, ?36, null, null, ?24];

                assert BpTree.validate_indexes<Nat, Nat>(left.children, left.count);
                assert BpTree.validate_indexes<Nat, Nat>(right.children, right.count);


                let left_test = BpTree.Branch.new<Nat, Nat>(6, ?[var ? #leaf(c0), ? #leaf(c1), ? #leaf(c2), ? #leaf(c3), null, null]);
                assert BpTree.Branch.equal<Nat, Nat>(left, left_test, Nat.compare);

                let right_test = BpTree.Branch.new<Nat, Nat>(6, ?[var ? #leaf(c4), ? #leaf(c5), ? #leaf(c6), null, null, null]);
                assert BpTree.Branch.equal<Nat, Nat>(right, right_test, Nat.compare);
            },
        );
    },

);

suite(
    "split branch: odd order", 
    func (){
        let c0 = new_leaf(0, 6);
        let c1 = new_leaf(6, 12);
        let c2 = new_leaf(12, 18);
        let c3 = new_leaf(18, 24);
        let c4 = new_leaf(24, 30);
        let c5 = new_leaf(30, 36);

        test (
            "split and insert at end", 
            func (){
                let children : [var ?BpTree.Node<Nat, Nat>] = [var ? #leaf(c0), ? #leaf(c1), ? #leaf(c2), ? #leaf(c3), ? #leaf(c4)];
                let node = BpTree.Branch.new<Nat, Nat>(5, ?children);
                let right = BpTree.split_branch<Nat, Nat>(node, #leaf(c5), 5, 30);

                let left = node;

                assert left.count == 3;
                assert right.count == 3;

                assert Array.freeze(left.keys) == [?6, ?12, null, null];
                assert Array.freeze(right.keys) == [?24, ?30, null, ?18];

                assert BpTree.validate_indexes<Nat, Nat>(left.children, left.count);
                assert BpTree.validate_indexes<Nat, Nat>(right.children, right.count);

                let left_test = BpTree.Branch.new<Nat, Nat>(5, ?[var ? #leaf(c0), ? #leaf(c1), ? #leaf(c2), null, null]);
                assert BpTree.Branch.equal<Nat, Nat>(left, left_test, Nat.compare);

                let right_test = BpTree.Branch.new<Nat, Nat>(5, ?[var ? #leaf(c3), ? #leaf(c4), ? #leaf(c5), null, null]);
                assert BpTree.Branch.equal<Nat, Nat>(right, right_test, Nat.compare);
            }
        );
    }
);

suite(
    "split leaf node: even order",
    func() {
        test(
            "split and insert at end",
            func() {
                let kvs : [var ?(Nat, Nat)] = [var ?(1, 1), ?(3, 3), ?(5, 5), ?(7, 7), ?(9, 9), ?(11, 11)];
                let leaf = BpTree.Leaf.new(6, ?kvs);
                leaf.count := 6;

                let right = BpTree.split_leaf<Nat, Nat>(leaf, 6, (13, 13));

                let left = leaf;

                assert left.count == 4;
                assert right.count == 3;

                assert Array.freeze(left.kvs) == [?(1, 1), ?(3, 3), ?(5, 5), ?(7, 7), null, null];
                assert Array.freeze(right.kvs) == [?(9, 9), ?(11, 11), ?(13, 13), null, null, null];

                assert left.index + 1 == right.index;

            },
        );

        test(
            "split and insert at start",
            func() {
                let kvs : [var ?(Nat, Nat)] = [var ?(1, 1), ?(3, 3), ?(5, 5), ?(7, 7), ?(9, 9), ?(11, 11)];
                let leaf = BpTree.Leaf.new(6, ?kvs);
                leaf.count := 6;

                let right = BpTree.split_leaf<Nat, Nat>(leaf, 0, (0, 0));

                let left = leaf;

                assert left.count == 4;
                assert right.count == 3;

                assert Array.freeze(left.kvs) == [?(0, 0), ?(1, 1), ?(3, 3), ?(5, 5), null, null];
                assert Array.freeze(right.kvs) == [?(7, 7), ?(9, 9), ?(11, 11), null, null, null];

                assert left.index + 1 == right.index;

            },
        );

        test(
            "split and insert on left",
            func() {
                let kvs : [var ?(Nat, Nat)] = [var ?(1, 1), ?(3, 3), ?(5, 5), ?(7, 7), ?(9, 9), ?(11, 11)];
                let leaf = BpTree.Leaf.new(6, ?kvs);
                leaf.count := 6;

                let right = BpTree.split_leaf<Nat, Nat>(leaf, 2, (4, 4));

                let left = leaf;

                assert left.count == 4;
                assert right.count == 3;

                assert Array.freeze(left.kvs) == [?(1, 1), ?(3, 3), ?(4, 4), ?(5, 5), null, null];
                assert Array.freeze(right.kvs) == [?(7, 7), ?(9, 9), ?(11, 11), null, null, null];

                assert left.index + 1 == right.index;

            },
        );

        test(
            "split and insert on right",
            func() {
                let kvs : [var ?(Nat, Nat)] = [var ?(1, 1), ?(3, 3), ?(5, 5), ?(7, 7), ?(9, 9), ?(11, 11)];
                let leaf = BpTree.Leaf.new(6, ?kvs);
                leaf.count := 6;

                let right = BpTree.split_leaf<Nat, Nat>(leaf, 5, (10, 10));

                let left = leaf;

                assert left.count == 4;
                assert right.count == 3;

                assert Array.freeze(left.kvs) == [?(1, 1), ?(3, 3), ?(5, 5), ?(7, 7), null, null];
                assert Array.freeze(right.kvs) == [?(9, 9), ?(10, 10), ?(11, 11), null, null, null];

                assert left.index + 1 == right.index;

            },
        );

        test(
            "split and insert in middle",
            func() {
                let kvs : [var ?(Nat, Nat)] = [var ?(1, 1), ?(3, 3), ?(5, 5), ?(7, 7), ?(9, 9), ?(11, 11)];
                let leaf = BpTree.Leaf.new(6, ?kvs);
                leaf.count := 6;

                let right = BpTree.split_leaf<Nat, Nat>(leaf, 3, (6, 6));

                let left = leaf;

                assert left.count == 4;
                assert right.count == 3;

                Debug.print("left " # debug_show Array.freeze(left.kvs));
                Debug.print("right " # debug_show Array.freeze(right.kvs));

                assert Array.freeze(left.kvs) == [?(1, 1), ?(3, 3), ?(5, 5), ?(6, 6), null, null];
                assert Array.freeze(right.kvs) == [?(7, 7), ?(9, 9), ?(11, 11), null, null, null];

                assert left.index + 1 == right.index;

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
                let leaf = BpTree.Leaf.new(5, ?kvs);
                leaf.count := 5;

                let right = BpTree.split_leaf<Nat, Nat>(leaf, 5, (11, 11));

                let left = leaf;

                assert left.count == 3;
                assert right.count == 3;

                assert Array.freeze(left.kvs) == [?(1, 1), ?(3, 3), ?(5, 5), null, null];
                assert Array.freeze(right.kvs) == [?(7, 7), ?(9, 9), ?(11, 11), null, null];

                assert left.index + 1 == right.index;

            },
        );

        test(
            "split and insert at start",
            func() {
                let kvs : [var ?(Nat, Nat)] = [var ?(1, 1), ?(3, 3), ?(5, 5), ?(7, 7), ?(9, 9)];
                let leaf = BpTree.Leaf.new(5, ?kvs);
                leaf.count := 5;

                let right = BpTree.split_leaf<Nat, Nat>(leaf, 0, (0, 0));

                let left = leaf;

                assert left.count == 3;
                assert right.count == 3;

                assert Array.freeze(left.kvs) == [?(0, 0), ?(1, 1), ?(3, 3), null, null];
                assert Array.freeze(right.kvs) == [?(5, 5), ?(7, 7), ?(9, 9), null, null];

                assert left.index + 1 == right.index;

            },
        );

        test(
            "split and insert on left",
            func() {
                let kvs : [var ?(Nat, Nat)] = [var ?(1, 1), ?(3, 3), ?(5, 5), ?(7, 7), ?(9, 9)];
                let leaf = BpTree.Leaf.new(5, ?kvs);
                leaf.count := 5;

                let right = BpTree.split_leaf<Nat, Nat>(leaf, 1, (2, 2));

                let left = leaf;

                assert left.count == 3;
                assert right.count == 3;

                assert Array.freeze(left.kvs) == [?(1, 1), ?(2, 2), ?(3, 3), null, null];
                assert Array.freeze(right.kvs) == [?(5, 5), ?(7, 7), ?(9, 9), null, null];

                assert left.index + 1 == right.index;

            },
        );

        test(
            "split and insert on right",
            func() {
                let kvs : [var ?(Nat, Nat)] = [var ?(1, 1), ?(3, 3), ?(5, 5), ?(7, 7), ?(9, 9)];
                let leaf = BpTree.Leaf.new(5, ?kvs);
                leaf.count := 5;

                let right = BpTree.split_leaf<Nat, Nat>(leaf, 4, (8, 8));

                let left = leaf;

                assert left.count == 3;
                assert right.count == 3;

                assert Array.freeze(left.kvs) == [?(1, 1), ?(3, 3), ?(5, 5), null, null];
                assert Array.freeze(right.kvs) == [?(7, 7), ?(8, 8), ?(9, 9), null, null];

                assert left.index + 1 == right.index;

            },
        );

        test(
            "split and insert in middle",
            func() {
                let kvs : [var ?(Nat, Nat)] = [var ?(1, 1), ?(3, 3), ?(5, 5), ?(7, 7), ?(9, 9)];
                let leaf = BpTree.Leaf.new(5, ?kvs);
                leaf.count := 5;

                let right = BpTree.split_leaf<Nat, Nat>(leaf, 3, (6, 6));

                let left = leaf;

                assert left.count == 3;
                assert right.count == 3;

                assert Array.freeze(left.kvs) == [?(1, 1), ?(3, 3), ?(5, 5), null, null];
                assert Array.freeze(right.kvs) == [?(6, 6), ?(7, 7), ?(9, 9), null, null];

                assert left.index + 1 == right.index;

            },
        );

    },
);

suite(
    "Function Tests",
    func() {
        test(
            "binary search",
            func() {
                let arr = [var ?1, ?3, ?5, ?7, null];
                var count = 4;

                assert 0 == BpTree.binary_search(arr, Nat.compare, 1, count);
                assert 1 == BpTree.binary_search(arr, Nat.compare, 3, count);
                assert 2 == BpTree.binary_search(arr, Nat.compare, 5, count);
                assert 3 == BpTree.binary_search(arr, Nat.compare, 7, count);

                assert -1 == BpTree.binary_search(arr, Nat.compare, 0, count);
                assert -2 == BpTree.binary_search(arr, Nat.compare, 2, count);
                assert -3 == BpTree.binary_search(arr, Nat.compare, 4, count);
                assert -4 == BpTree.binary_search(arr, Nat.compare, 6, count);
                assert -5 == BpTree.binary_search(arr, Nat.compare, 8, count);

                arr[4] := ?9;
                count := 5;

                assert 4 == BpTree.binary_search(arr, Nat.compare, 9, count);
                assert -5 == BpTree.binary_search(arr, Nat.compare, 8, count);
                assert -6 == BpTree.binary_search(arr, Nat.compare, 10, count);

                arr[4] := null;
                arr[3] := null;
                arr[2] := null;
                arr[1] := null;
                count := 1;

                assert 0 == BpTree.binary_search(arr, Nat.compare, 1, count);
                assert -1 == BpTree.binary_search(arr, Nat.compare, 0, count);
                assert -2 == BpTree.binary_search(arr, Nat.compare, 10, count);

            },
        );
    },
);
