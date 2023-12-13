import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Order "mo:base/Order";
import Option "mo:base/Option";
import Int "mo:base/Int";

import T "Types";
import InternalTypes "../internal/Types";
import BpTree "../BpTree";
import BpTreeMethods "../BpTree/Methods";
import ArrayMut "../internal/ArrayMut";

import Leaf "Leaf";
import Branch "Branch";

module MaxBpTree {

    public type MaxBpTree<K, V> = T.MaxBpTree<K, V>;
    public type Node<K, V> = T.Node<K, V>;
    public type Leaf<K, V> = T.Leaf<K, V>;
    public type Branch<K, V> = T.Branch<K, V>;
    type CommonFields<K, V> = T.CommonFields<K, V>;
    type CommonNodeFields<K, V> = T.CommonNodeFields<K, V>;
    type MultiCmpFn<A, B> = InternalTypes.MultiCmpFn<A, B>;
    type CmpFn<A> = InternalTypes.CmpFn<A>;
    type MaxField<V> = T.MaxField<V>;

    type Order = Order.Order;

    public func new<K, V>(_order : ?Nat) : MaxBpTree<K, V> {
        let order = Option.get(_order, 32);

        assert order >= 4 and order <= 512;

        {
            order;
            var root = #leaf(Leaf.new<K, V>(order, 0, null, func() : Nat = 0));
            var size = 0;
            var next_id = 1;
        };
    };

    public func size<K, V>(max_bptree : MaxBpTree<K, V>) : Nat {
        max_bptree.size;
    };

    /// Returns the value associated with the given key.
    /// If the key is not in the tree, it returns null.
    ///
    /// #### Examples
    /// ```motoko
    ///     let arr = [('A', 1), ('B', 2), ('C', 3)];
    ///     let bptree = MaxBpTree.fromArray<Char, Nat>(null, arr, Char.compare);
    ///
    ///     assert MaxBpTree.get(bptree, Char.compare, 'A') == 1;
    ///     assert MaxBpTree.get(bptree, Char.compare, 'D') == null;
    /// ```
    public func get<K, V>(self : MaxBpTree<K, V>, cmp : CmpFn<K>, key : K) : ?V {
        BpTreeMethods.get(self, cmp, key);
    };

    // public func insert<K, V>(self : MaxBpTree<K, V>, cmp : CmpFn<K>, key : K, value : V) : MaxBpTree<K, V> {
    //     func branch_new(
    //         cmp : CmpFn<V>,
    //         gen_id : () -> Nat,
    //         order : Nat,
    //         opt_children : ?[var ?Node<K, V>],
    //     ) : Branch<K, V> {
    //         Branch.new<K, V>(cmp, gen_id, order, opt_children);
    //     };

    //     BpTreeMethods.insert(self, cmp, key, value, Leaf.split, branch_new, Branch.split);
    // };

};
