import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Order "mo:base/Order";

import T "Types";
import InternalTypes "../internal/Types";
import InternalBranch "../internal/Branch";
import Leaf "Leaf";
import Utils "../internal/Utils";
import ArrayMut "../internal/ArrayMut";

module Branch {
    type Order = Order.Order;
    public type Branch<K, V> = T.Branch<K, V>;
    type Node<K, V> = T.Node<K, V>;
    type BpTree<K, V> = T.BpTree<K, V>;
    type CmpFn<K> = InternalTypes.CmpFn<K>;
    type CommonNodeFields<K, V> = T.CommonNodeFields<K, V>;

    public func new<K, V>(
        order : Nat,
        opt_keys : ?[var ?K],
        opt_children : ?[var ?Node<K, V>],
        gen_id: () -> Nat,
    ) : Branch<K, V> {
        InternalBranch.new(order, opt_keys, opt_children, gen_id, (), null);
    };

    public func update_median_key<K, V>(_parent: Branch<K, V>, index: Nat, new_key: K){
        var parent = _parent;
        var i = index;

        while (i == 0){
            i:= parent.index;
            let ?__parent = parent.parent else return; // occurs when key is the first key in the tree
            parent := __parent;
        };

        parent.keys[i - 1] := ?new_key;
    };

    public func split<K, V>(node : Branch<K, V>, child : Node<K, V>, child_index : Nat, first_child_key : K, gen_id: () -> Nat) : Branch<K, V> {
        InternalBranch.split(node, child, child_index, first_child_key, gen_id, (), null, null);
    };

    public func redistribute_keys<K, V>(branch_node: Branch<K, V>){
        InternalBranch.redistribute_keys(branch_node, null, null);
    };

    public func merge<K, V>(left: Branch<K, V>, right: Branch<K, V>){
        InternalBranch.merge(left, right, null);
    };

    public func equal<K, V>(a : Branch<K, V>, b : Branch<K, V>, cmp : CmpFn<K>) : Bool {
        for (i in Iter.range(0, a.keys.size() - 2)) {
            let res = switch (a.keys[i], b.keys[i]) {
                case (?v1, ?v2) {
                    cmp(v1, v2) == #equal;
                };
                case (null, null) true;
                case (_) false;
            };

            if (not res) return false;
        };

        for (i in Iter.range(0, a.children.size() - 1)) {
            let res = switch (a.children[i], b.children[i]) {
                case (? #leaf(v1), ? #leaf(v2)) {
                    Leaf.equal(v1, v2, cmp);
                };
                case (? #branch(v1), ? #branch(v2)) {
                    equal(v1, v2, cmp);
                };
                case (null, null) true;
                case (_) false;
            };
        };

        true;
    };

    public func subtrees<K, V>(node : Branch<K, V>) : [Nat] {
        Array.tabulate(
            node.count,
            func(i : Nat) : Nat {
                let ?child = node.children[i] else Debug.trap("subtrees: accessed a null value");
                switch (child) {
                    case (#branch(node)) node.subtree_size;
                    case (#leaf(node)) node.count;
                };
            },
        );
    };

    public func toText<K, V>(self : Branch<K, V>, key_to_text : (K) -> Text, val_to_text : (V) -> Text) : Text {
        var t = "branch { index: " # debug_show self.index # ", count: " # debug_show self.count # ", subtree: " # debug_show self.subtree_size # ", keys: ";
        t #= debug_show Array.map(
            Array.freeze(self.keys),
            func(opt_key : ?K) : Text {
                switch (opt_key) {
                    case (?key) key_to_text(key);
                    case (_) "null";
                };
            },
        );

        t #= ", children: " # debug_show Array.map(
            Array.freeze(self.children),
            func(opt_node : ?Node<K, V>) : Text {
                switch (opt_node) {
                    case (? #leaf(node)) Leaf.toText<K, V>(node, key_to_text, val_to_text);
                    case (? #branch(node)) Branch.toText(node, key_to_text, val_to_text);
                    case (_) "null";
                };
            },
        );

        t #= " }";

        t;
    };
};
