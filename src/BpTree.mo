import Option "mo:base/Option";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Order "mo:base/Order";
import Int "mo:base/Int";
import Buffer "mo:base/Buffer";

import Utils "Utils";

module BpTree {
    type Order = Order.Order;
    type CmpFn<A> = (A, A) -> Order;

    public type BpTree<K, V> = {
        order : Nat;
        var root : Node<K, V>;
        var size : Nat;
    };

    type LeafNode<K, V> = {
        var parent : ?InternalNode<K, V>;
        var index: Nat;
        kvs : [var ?(K, V)];
        var count : Nat;
        var next : ?LeafNode<K, V>;
    };

    type InternalNode<K, V> = {
        var parent : ?InternalNode<K, V>;
        var index: Nat;
        keys : [var ?K];
        children : [var ?Node<K, V>];
        var count : Nat;
    };

    module Node {
        public type Node<K, V> = {
            #leaf : LeafNode<K, V>;
            #internal : InternalNode<K, V>;
        };

        public func newLeaf<K, V>(order : Nat, opt_kvs : ?[var ?(K, V)]) : LeafNode<K, V> {
            {
                var parent = null;
                var index = 0;
                kvs = Option.get(opt_kvs, Array.init<?(K, V)>(order, null));
                var count = 0;
                var next = null;
            };
        };

        public func newInternal<K, V>(
            order : Nat,
            opt_keys : ?[var ?K],
            opt_children : ?[var ?Node<K, V>],
        ) : InternalNode<K, V> {
            {
                var parent = null;
                var index = 0;
                keys = Option.get(opt_keys, Array.init<?K>(order - 1, null));
                children = Option.get(opt_children, Array.init<?Node<K, V>>(order, null));
                var count = 0;
            };
        };
    };

    public type Node<K, V> = Node.Node<K, V>;

    public func new<K, V>() : BpTree<K, V> {
        BpTree.newWithOrder<K, V>(32);
    };

    public func newWithOrder<K, V>(order : Nat) : BpTree<K, V> {
        assert order >= 4 and order <= 512;

        {
            order;
            var root = #leaf(Node.newLeaf<K, V>(order, null));
            var size = 0;
        };
    };

    type MultiCmpFn<A, B> = (A, B) -> Order;

    public func binary_search<A, B>(arr : [var ?A], cmp : MultiCmpFn<B, A>, search_key : B, arr_len : Nat) : Int {
        if (arr_len == 0) return -1; // should insert at index Int.abs(i + 1)
        var l = 0;

        // arr_len will always be between 4 and 512
        var r = arr_len - 1 : Nat;

        while (l < r) {
            let mid = (l + r) / 2;

            let ?val = arr[mid] else Debug.trap("1. binary_search: accessed a null value");

            switch (cmp(search_key, val)) {
                case (#less) {
                    r := mid;
                };
                case (#greater) {
                    l := mid + 1;
                };
                case (#equal) {
                    return mid;
                };
            };
        };

        let insertion = l;

        // Check if the insertion point is valid
        // return the insertion point but negative and subtracting 1 indicating that the key was not found
        // such that the insertion index for the key is Int.abs(insertion) - 1
        // [0,  1,  2]
        //  |   |   |
        // -1, -2, -3
        switch (arr[insertion]) {
            case (?val) {
                switch (cmp(search_key, val)){
                    case (#equal) insertion;
                    case (#less) -(insertion + 1);
                    case (#greater) -(insertion + 2);
                };
            };
            case (_) Debug.trap("1. binary_search: accessed a null value");
        };
        
    };

    func adapt_cmp<K, V>(cmp: CmpFn<K>): MultiCmpFn<K, (K, V)> {
        func (a: K, b: (K, V)): Order {
            cmp(a, b.0)
        };
    };

    public func get_leaf_node<K, V>(self:BpTree<K, V>, cmp : CmpFn<K>, key : K ): LeafNode<K, V> {
        var node = ?self.root;

        loop {
            switch (node) {
                case (?#internal(internal_node)) {
                    let int_index = binary_search<K, K>(internal_node.keys, cmp, key, internal_node.count - 1);
                    let index = if (int_index >= 0) Int.abs(int_index) + 1 else Int.abs(int_index + 1);

                    node := internal_node.children[index];
                };
                case (?#leaf(leaf_node)) {
                    return leaf_node;
                };
                case (_) Debug.trap("get_leaf_node: accessed a null value");
            };
        };
    };

    public func get_min_leaf_node<K, V>(self:BpTree<K, V>): LeafNode<K, V> {
        var node = ?self.root;

        loop {
            switch (node) {
                case (?#internal(internal_node)) {
                    node := internal_node.children[0];
                };
                case (?#leaf(leaf_node)) {
                    return leaf_node;
                };
                case (_) Debug.trap("get_min_leaf_node: accessed a null value");
            };
        };
    };

    public func get<K, V>(self: BpTree<K, V>, cmp: CmpFn<K>, key: K): ?V{
        let leaf_node = get_leaf_node<K, V>(self, cmp, key);

        let i = binary_search<(K, V), K>(leaf_node.kvs, adapt_cmp(cmp), key, leaf_node.count);

        if (i >= 0) {
            let ?kv = leaf_node.kvs[Int.abs(i)] else Debug.trap("1. get: accessed a null value");
            return ?kv.1;
        } else {
            return null;
        };
    };

    func cmp_key<K, V>(cmp: CmpFn<K>): CmpFn<(K, V)> {
        func (a: (K, V), b: (K, V)): Order {
            cmp(a.0, b.0)
        };
    };

    func extract<T>(arr: [var ?T], index: Nat): ?T {
        let tmp = arr[index];
        arr[index] := null;
        tmp;
    };

    public func insert<K, V>(self : BpTree<K, V>, cmp : CmpFn<K>, key : K, val : V) : ?V {

        let leaf_node = get_leaf_node<K, V>(self, cmp, key);
        let entry = (key, val);

        let int_leaf_index = binary_search<(K, V), K>(leaf_node.kvs, adapt_cmp(cmp), key, leaf_node.count);
        let leaf_index = if (int_leaf_index >= 0) Int.abs(int_leaf_index) else Int.abs(int_leaf_index + 1);

        let prev_value = if (int_leaf_index >= 0) {
            Debug.print("replacing key-value pair at index  = " # debug_show leaf_index);
            let ?kv = leaf_node.kvs[leaf_index] else Debug.trap("1. insert: accessed a null value while replacing a key-value pair");
            leaf_node.kvs[leaf_index] := ?entry;
            return ?kv.1;
        } else {
            null;
        };

        if (leaf_node.count < self.order ){
            // shift elems to the right and insert the new key-value pair
            var j = leaf_node.count;

            while (j > leaf_index) {
                leaf_node.kvs[j] := leaf_node.kvs[j - 1];
                j -= 1;
            };

            leaf_node.kvs[leaf_index] := ?entry;
            leaf_node.count += 1;

            self.size += 1;
            return prev_value;
        };

        // split leaf node

        let median = (leaf_node.count / 2) + 1;  // include inserted key-value pair

        var avoid_tabulate_var_bug = false;

        var left_cnt = leaf_node.count;
        let is_elem_added_to_right = leaf_index >= median;

        let right_kvs = Array.tabulateVar<?(K, V)>(self.order, func (i: Nat): ?(K, V){
            if (i == 0 and not avoid_tabulate_var_bug) {
                avoid_tabulate_var_bug := true;
                return null;
            };

            let j = i + median;

            if (j >= leaf_node.count + (if (is_elem_added_to_right) 1 else 0)) return null;

            if (j == leaf_index){
                ?entry;
            }else if (j < leaf_index){
                extract(leaf_node.kvs, j);
            }else{
                extract(leaf_node.kvs, j - 1 : Nat);
            };
        });

        var j = median: Nat;

        while (j > leaf_index) {
            leaf_node.kvs[j] := leaf_node.kvs[j - 1];
            j -= 1;
        };

        leaf_node.count :=  leaf_node.count / 2;

        if (j == leaf_index) {
            leaf_node.kvs[j] := ?entry;
            leaf_node.count += 1;
        };

        let right_node = Node.newLeaf<K, V>(self.order, ?right_kvs);
        right_node.count := self.order - median + (if (is_elem_added_to_right) 1 else 0);

        // update next pointers
        right_node.next := leaf_node.next;
        leaf_node.next := ?right_node;

        right_node.parent := leaf_node.parent;
        right_node.index := leaf_node.index + 1;

        let ?right_node_key = right_kvs[0] else Debug.trap("2. insert: accessed a null value");

        switch(leaf_node.parent){
            case (null) {
                let keys = Array.init<?K>(self.order - 1, null);
                keys[0] := ?right_node_key.0;
                let children = Array.init<?Node<K, V>>(self.order, null);
                children[0] := ?#leaf(leaf_node);
                children[1] := ?#leaf(right_node);

                let root_node = Node.newInternal<K, V>(self.order, ?keys, ?children);
                root_node.count := 2;

                leaf_node.parent := ?root_node;
                leaf_node.index := 0;

                right_node.parent := ?root_node;
                right_node.index := 1;

                self.root := #internal(root_node);
            };
            case (?parent) {
                if (parent.count < self.order){
                    // shift elems to the right and insert the new key-value pair
                    var j = parent.count;

                    while (j > right_node.index) {
                        parent.keys[j - 1] := parent.keys[j - 2];
                        parent.children[j] := parent.children[j - 1];
                        j -= 1;
                    };

                    parent.keys[leaf_node.index] := ?right_node_key.0;
                    parent.children[right_node.index] := ?#leaf(right_node);
                    parent.count += 1;

                }else {
                    Debug.print("size of b-plus-tree = " # debug_show self.size);
                    Debug.trap("insert: parent node is full");
                };
            };
        };

        self.size += 1;
        prev_value;
        
    };

    public func toArray<K, V>(self : BpTree<K, V>) : [(K, V)] {
        var node = ?self.root;
        let buffer = Buffer.Buffer<(K, V)>(self.size);

        var leaf_node: ?LeafNode<K, V> = ?get_min_leaf_node(self);

        label _loop loop {
            switch (leaf_node) {
                case (?leaf) {
                    label _for_loop for (opt in leaf.kvs.vals()) {
                        let ?kv = opt else break _for_loop;
                        buffer.add(kv);
                    };

                    leaf_node := leaf.next;
                };
                case (_) break _loop;
            };
        };

        Buffer.toArray(buffer)
    };

    public func toLeafNodes<K, V>(self : BpTree<K, V>) : [[?(K, V)]] {
        var node = ?self.root;
        let buffer = Buffer.Buffer<[?(K, V)]>(self.size);

        var leaf_node: ?LeafNode<K, V> = ?get_min_leaf_node(self);

        label _loop loop {
            switch (leaf_node) {
                case (?leaf) {
                    // let leaf_buffer = Buffer.Buffer<(K, V)>(leaf.count);

                    // label _for_loop for (opt in leaf.kvs.vals()) {
                    //     let ?kv = opt else break _for_loop;
                    //     leaf_buffer.add(kv);
                    // };

                    buffer.add(Array.freeze<?(K, V)>(leaf.kvs));

                    leaf_node := leaf.next;
                };
                case (_) break _loop;
            };
        };

        Buffer.toArray(buffer)
    };
};
