import T "Types";

module Cursor {

    let { Const = C } = T;

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
            let ?kv = node.3[i] else return null;
            ?kv.0;
        };

        public func val() : ?V {
            let ?kv = node.3[i] else return null;
            ?kv.1;
        };

        public func current() : ?(K, V) {
            if (i >=  node.0[C.COUNT]){
                return null;
            };

            return node.3[i];
        };

        public func advance() {
            if (i + 1 >= node.0[C.COUNT]) {
                switch (node.2[C.NEXT]) {
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
        //                 i := prev.0[C.COUNT] - 1;
        //             };
        //             case (_) {};
        //         };

        //         return;
        //     };

        //     i -= 1;
        // };

        public func peekNext() : ?(K, V){
            if (i + 1 >= node.0[C.COUNT]){
                switch (node.2[C.NEXT]) {
                    case (?next) {
                        return next.3[0];
                    };
                    case (_) {
                        return null;
                    };
                };
            };

            return node.3[i + 1];
        };

        // public func peekPrev() : ?(K, V){
        //     if (i == 0){
        //         switch (node.prev) {
        //             case (?prev) {
        //                 return prev.3[prev.0[C.COUNT] - 1];
        //             };
        //             case (_) {
        //                 return null;
        //             };
        //         };
        //     };
        //     return node.3[i - 1];
        // };
    };
};
