import Array "mo:base/Array";
import Option "mo:base/Option";

import BpTreeLeaf "../BpTree/Leaf";
import T "Types";
import BpTree "../BpTree";

import Utils "../internal/Utils";

module {
    public type Leaf<K, V> = T.Leaf<K, V>;

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
}