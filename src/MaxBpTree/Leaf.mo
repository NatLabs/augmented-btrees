import Array "mo:base/Array";
import Option "mo:base/Option";

import BpTreeLeaf "../BpTree/Leaf";
import T "Types";
import BpTree "../BpTree";

import Utils "../internal/Utils";
import InternalTypes "../internal/Types";
import InternalLeaf "../internal/Leaf";
import InternalMethods "../internal/Methods";

module {
    public type MaxBpTree<K, V> = T.MaxBpTree<K, V>;
    public type Node<K, V> = T.Node<K, V>;
    public type Leaf<K, V> = T.Leaf<K, V>;
    public type Branch<K, V> = T.Branch<K, V>;
    type CommonFields<K, V> = T.CommonFields<K, V>;
    type CommonNodeFields<K, V> = T.CommonNodeFields<K, V>;
    type MultiCmpFn<A, B> = InternalTypes.MultiCmpFn<A, B>;
    type CmpFn<A> = InternalTypes.CmpFn<A>;
    type MaxField<K, V> = T.MaxField<K, V>;

    public func new<K, V>(order : Nat, count : Nat, opt_kvs : ?[var ?(K, V)], gen_id : () -> Nat) : Leaf<K, V> {
        return {
            id = gen_id();
            var parent = null;
            var index = 0;
            kvs = switch (opt_kvs) {
                case (?kvs) kvs;
                case (_) Array.init<?(K, V)>(order, null);
            };
            var count = count;
            var next = null;
            var prev = null;
            fields = {
                var max = null;
            };
        };
    };

    public func split<K, V>(
        leaf: Leaf<K, V>, 
        elem_index: Nat, 
        elem: (K, V), 
        max_bp_tree: MaxBpTree<K, V>, 
        // val_cmp: CmpFn<V>
    ) : Leaf<K, V>{
        func gen_id(): Nat = InternalMethods.gen_id(max_bp_tree);

        func new_leaf(order : Nat, count : Nat, opt_kvs : ?[var ?(K, V)], gen_id: () -> Nat) : Leaf<K, V>{
            InternalLeaf.new<K, V, MaxField<K, V>>(order, count, opt_kvs, gen_id, { var max = null; });
        };

        InternalLeaf.split<K, V, MaxField<K, V>>(leaf, elem_index, elem, gen_id, new_leaf);
    };
};