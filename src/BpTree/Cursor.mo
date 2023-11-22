import T "Types";

module Cursor {
    public type ImperativeCursor<K, V> = {
        var node : T.Leaf<K, V>;
        var i : Nat;
    };

    public class Cursor<K, V>(bptree : T.BpTree<K, V>, cmp : T.CmpFn<K>, leaf : T.Leaf<K, V>, index : Nat) /*: InternalTypes.Cursor<K, V>*/ {
        var i = index;
        var node = leaf;

        public func isEmpty() : Bool {
            bptree.size == 0;
        };

        public func key() : ?K {
            let ?kv = node.kvs[i] else return null;
            ?kv.0;
        };

        public func val() : ?V {
            let ?kv = node.kvs[i] else return null;
            ?kv.1;
        };

        public func current() : ?(K, V) {
            if (i >=  node.count){
                return null;
            };

            return node.kvs[i];
        };

        public func advance() {
            if (i + 1 >= node.count) {
                switch (node.next) {
                    case (?next) {
                        node := next;
                        i := 0;
                    };
                    case (_) {};
                };

                return;
            };

            i += 1;
        };

        // public func retreat() {
        //     if (i == 0) {
        //         switch (node.prev) {
        //             case (?prev) {
        //                 node := prev;
        //                 i := prev.count - 1;
        //             };
        //             case (_) {};
        //         };

        //         return;
        //     };

        //     i -= 1;
        // };

        public func peekNext() : ?(K, V){
            if (i + 1 >= node.count){
                switch (node.next) {
                    case (?next) {
                        return next.kvs[0];
                    };
                    case (_) {
                        return null;
                    };
                };
            };

            return node.kvs[i + 1];
        };

        // public func peekPrev() : ?(K, V){
        //     if (i == 0){
        //         switch (node.prev) {
        //             case (?prev) {
        //                 return prev.kvs[prev.count - 1];
        //             };
        //             case (_) {
        //                 return null;
        //             };
        //         };
        //     };
        //     return node.kvs[i - 1];
        // };
    };
};
