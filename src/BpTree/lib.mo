import Prim "mo:prim";

import Option "mo:base/Option";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Order "mo:base/Order";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Buffer "mo:base/Buffer";
import BufferDeque "mo:buffer-deque/BufferDeque";

import ArrayMut "../internal/ArrayMut";
import Utils "../internal/Utils";

module BpTree {
    type Iter<A> = Iter.Iter<A>;
    type Order = Order.Order;
    type CmpFn<A> = (A, A) -> Order;
    type BufferDeque<A> = BufferDeque.BufferDeque<A>;

    public type BpTree<K, V> = {
        order : Nat;
        var root : Node<K, V>;
        var size : Nat;
    };

    type SharedNodeFields<K, V> = {
        var count : Nat;
        var index : Nat;
        var parent : ?Branch<K, V>;
    };

    type SharedNode<K, V> = {
        #leaf : SharedNodeFields<K, V>;
        #branch : SharedNodeFields<K, V>;
    };

    public module Leaf {
        public type Leaf<K, V> = {
            var parent : ?Branch<K, V>;
            var index : Nat;
            kvs : [var ?(K, V)];
            var count : Nat;
            var next : ?Leaf<K, V>;
        };

        public func new<K, V>(order : Nat,  count: Nat, opt_kvs : ?[var ?(K, V)]) : Leaf<K, V> {
            {
                var parent = null;
                var index = 0;
                kvs = Option.get(opt_kvs, Array.init<?(K, V)>(order, null));
                var count = count;
                var next = null;
            };
        };

        public func remove<K, V>(leaf: Leaf<K, V>, index : Nat) : ?(K, V) {
            let removed = ArrayMut.remove(leaf.kvs, index, leaf.count);

            // leaf.count -= 1;
            removed;
        };

        public func equal<K, V>(a : Leaf<K, V>, b : Leaf<K, V>, cmp : CmpFn<K>) : Bool {
            for (i in Iter.range(0, a.kvs.size() - 1)) {
                let res = switch (a.kvs[i], b.kvs[i]) {
                    case (?v1, ?v2) {
                        cmp(v1.0, v2.0) == #equal;
                    };
                    case (_) false;
                };

                if (not res) return false;
            };

            true;
        };

        public func toText<K, V>(self : Leaf<K, V>, key_to_text : (K) -> Text, val_to_text : (V) -> Text) : Text {
            var t = "leaf { index: " # debug_show self.index # ", count: " # debug_show self.count # ", kvs: ";

            t #= debug_show Array.map(
                Array.freeze(self.kvs),
                func(opt_kv : ?(K, V)) : Text {
                    switch (opt_kv) {
                        case (?kv) "(" # key_to_text(kv.0) # ", " # val_to_text(kv.1) # ")";
                        case (_) "null";
                    };
                },
            );

            t #= " }";

            t;
        };
    };

    public module Branch {
        public type Branch<K, V> = {
            var parent : ?Branch<K, V>;
            var index : Nat;
            var keys : [var ?K];
            var children : [var ?Node<K, V>];
            var count : Nat;
        };

        public func new<K, V>(
            order : Nat,
            opt_children : ?[var ?Node<K, V>],
        ) : Branch<K, V> {

            let self : Branch<K, V> = {
                var parent = null;
                var index = 0;
                var keys = [var];
                var children = [var];
                var count = 0;
            };

            let children = switch (opt_children) {
                case (?children) { children };
                case (_) {
                    self.keys := Array.init<?K>(order - 1, null);
                    self.children := Array.init<?Node<K, V>>(order, null);
                    return self;
                };
            };

            var count = 0;

            switch (children[0]) {
                case (? #leaf(node) or ? #branch(node) : ?SharedNode<K, V>) {
                    node.parent := ?self;
                    node.index := 0;
                    count += 1;
                };
                case (_) Debug.trap("Branch.new: should replace the opt_children input with a null value ");
            };

            let keys = Array.tabulateVar<?K>(
                order - 1 : Nat,
                func(i : Nat) : ?K {
                    switch (children[i + 1]) {
                        case (? #leaf(node)) {
                            node.parent := ?self;
                            node.index := count;
                            count += 1;

                            switch (node.kvs[0]) {
                                case (?kv) ?kv.0;
                                case (_) null;
                            };
                        };
                        case (? #branch(node)) {
                            node.parent := ?self;
                            node.index := count;
                            count += 1;
                            node.keys[0];
                        };
                        case (_) null;
                    };
                },
            );

            self.keys := keys;
            self.children := children;
            self.count := count;

            self;
        };

        public func newWithKeys<K, V>(keys : [var ?K], children : [var ?Node<K, V>]) : Branch<K, V> {
            let self : Branch<K, V> = {
                var parent = null;
                var index = 0;
                var keys = keys;
                var children = children;
                var count = 0;
            };

            for (child in children.vals()) {
                switch (child) {
                    case (? #leaf(node)) {
                        node.parent := ?self;
                        node.index := self.count;
                        self.count += 1;
                    };
                    case (? #branch(node)) {
                        node.parent := ?self;
                        node.index := self.count;
                        self.count += 1;
                    };
                    case (_) {};
                };
            };

            self;
        };

        public func remove<K, V>(self : Branch<K, V>, index : Nat) : ?Node<K, V> {
            let removed = self.children[index];

            var i = index;
            while (i < (self.count - 1 : Nat)) {
                self.children[i] := self.children[i + 1];

                switch (self.children[i]) {
                    case (? #leaf(node) or ? #branch(node) : ?SharedNode<K, V>) {
                        node.index := i;
                    };
                    case (_) Debug.trap("Branch.remove: accessed a null value");
                };
                i+=1;
            };

            self.children[self.count - 1] := null;

            removed;
        };

        public func insert<K, V>(branch: Branch<K, V>, i: Nat, child: Node<K, V>){

            var j = i;

            while (j < branch.count) {
                branch.children[j + 1] := branch.children[j];

                switch(branch.children[j + 1]) {
                    case (? #branch(node) or ? #leaf(node) : ?SharedNode<K, V>) {
                        node.parent := ?branch;
                        node.index := j + 1;
                    };
                    case (_) {};
                };
                j += 1;
            };

            branch.children[i] := ?child;

            switch (child) {
                case (#branch(node) or #leaf(node) : SharedNode<K, V>) {
                    node.parent := ?branch;
                    node.index := i;
                };
            };

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

        public func toText<K, V>(self : Branch<K, V>, key_to_text : (K) -> Text, val_to_text : (V) -> Text) : Text {
            var t = "branch { index: " # debug_show self.index # ", count: " # debug_show self.count # ", keys: ";
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

    module Node {
        public type Node<K, V> = {
            #leaf : Leaf<K, V>;
            #branch : Branch<K, V>;
        };

        public func newLeaf<K, V>(order : Nat, opt_kvs : ?[var ?(K, V)]) : Leaf<K, V> {
            {
                var parent = null;
                var index = 0;
                kvs = Option.get(opt_kvs, Array.init<?(K, V)>(order, null));
                var count = 0;
                var next = null;
            };
        };

        public func newBranch<K, V>(
            order : Nat,
            opt_keys : ?[var ?K],
            opt_children : ?[var ?Node<K, V>],
        ) : Branch<K, V> {
            {
                var parent = null;
                var index = 0;
                var keys = Option.get(opt_keys, Array.init<?K>(order - 1, null));
                var children = Option.get(opt_children, Array.init<?Node<K, V>>(order, null));
                var count = 0;
            };
        };
    };

    public type Node<K, V> = Node.Node<K, V>;
    public type Leaf<K, V> = Leaf.Leaf<K, V>;
    public type Branch<K, V> = Branch.Branch<K, V>;

    public func new<K, V>() : BpTree<K, V> {
        BpTree.newWithOrder<K, V>(32);
    };

    public func newWithOrder<K, V>(order : Nat) : BpTree<K, V> {
        // assert order >= 4 and order <= 512;

        {
            order;
            var root = #leaf(Leaf.new<K, V>(order, 0, null));
            var size = 0;
        };
    };

    public func size<K, V>(self : BpTree<K, V>) : Nat {
        self.size;
    };

    public func depth<K, V>(bptree : BpTree<K, V>) : Nat {
        var node = ?bptree.root;
        var depth = 0;

        label while_loop loop {
            switch (node) {
                case (? #branch(n)) {
                    node := n.children[0];
                    depth += 1;
                };
                case (? #leaf(_)) {
                    return depth + 1;
                };
                case (_) Debug.trap("depth: accessed a null value");
            };
        };

        depth;
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
                switch (cmp(search_key, val)) {
                    case (#equal) insertion;
                    case (#less) -(insertion + 1);
                    case (#greater) -(insertion + 2);
                };
            };
            case (_) {
                Debug.print("insertion = " # debug_show insertion);
                Debug.print("arr_len = " # debug_show arr_len);
                Debug.print(
                    "arr = " # debug_show Array.map(
                        Array.freeze(arr),
                        func(opt_val : ?A) : Text {
                            switch (opt_val) {
                                case (?val) "1";
                                case (_) "0";
                            };
                        },
                    )
                );
                Debug.trap("2. binary_search: accessed a null value");
            };
        };

    };

    public func binary_search_n<T>(arr : [var ?T], cmp : CmpFn<T>, search_key : T, arr_len : Nat) : Int {
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
                switch (cmp(search_key, val)) {
                    case (#equal) insertion;
                    case (#less) -(insertion + 1);
                    case (#greater) -(insertion + 2);
                };
            };
            case (_) Debug.trap("1. binary_search: accessed a null value");
        };

    };

    func adapt_cmp<K, V>(cmp : CmpFn<K>) : MultiCmpFn<K, (K, V)> {
        func(a : K, b : (K, V)) : Order {
            cmp(a, b.0);
        };
    };

    public func get_leaf_node<K, V>(self : BpTree<K, V>, cmp : CmpFn<K>, key : K) : Leaf<K, V> {
        var curr = ?self.root;

        loop {
            switch (curr) {
                case (? #branch(node)) {
                    let int_index = binary_search<K, K>(node.keys, cmp, key, node.count - 1);
                    let node_index = if (int_index >= 0) Int.abs(int_index) + 1 else Int.abs(int_index + 1);
                    curr := node.children[node_index];
                };
                case (? #leaf(leaf_node)) {
                    return leaf_node;
                };
                case (_) Debug.trap("get_leaf_node: accessed a null value");
            };
        };
    };

    public func get_min_leaf_node<K, V>(self : BpTree<K, V>) : Leaf<K, V> {
        var node = ?self.root;

        loop {
            switch (node) {
                case (? #branch(branch)) {
                    node := branch.children[0];
                };
                case (? #leaf(leaf_node)) {
                    return leaf_node;
                };
                case (_) Debug.trap("get_min_leaf_node: accessed a null value");
            };
        };
    };

    public func get<K, V>(self : BpTree<K, V>, cmp : CmpFn<K>, key : K) : ?V {
        let leaf_node = get_leaf_node<K, V>(self, cmp, key);

        let i = binary_search<(K, V), K>(leaf_node.kvs, adapt_cmp(cmp), key, leaf_node.count);

        if (i >= 0) {
            let ?kv = leaf_node.kvs[Int.abs(i)] else Debug.trap("1. get: accessed a null value");
            return ?kv.1;
        };

        null;
    };

    func cmp_key<K, V>(cmp : CmpFn<K>) : CmpFn<(K, V)> {
        func(a : (K, V), b : (K, V)) : Order {
            cmp(a.0, b.0);
        };
    };

    func extract<T>(arr : [var ?T], index : Nat) : ?T {
        let tmp = arr[index];
        arr[index] := null;
        tmp;
    };

    public func toText<K, V>(self : BpTree<K, V>, key_to_text : (K) -> Text, val_to_text : (V) -> Text) : Text {
        var t = "BpTree { order: " # debug_show self.order # ", size: " # debug_show self.size # ", root: ";

        t #= switch (self.root) {
            case (#leaf(node)) "leaf { " # Leaf.toText<K, V>(node, key_to_text, val_to_text) # " }";
            case (#branch(node)) "branch {" # Branch.toText<K, V>(node, key_to_text, val_to_text) # "}";
        };

        t #= "}";

        t;
    };


    public func split_leaf<K, V>(leaf : Leaf<K, V>, elem_index : Nat, elem : (K, V)) : Leaf<K, V> {

        let arr_len = leaf.count;
        let median = (arr_len / 2) + 1;

        let is_elem_added_to_right = elem_index >= median;

        // if elem is added to the left
        // this variable allows us to retrieve the last element on the left
        // that gets shifted by the inserted elemeent
        var offset = if (is_elem_added_to_right) 0 else 1;

        var already_inserted = false;
        let right_kvs = Array.tabulateVar<?(K, V)>(
            leaf.kvs.size(),
            func(i : Nat) : ?(K, V) {

                let j = i + median - offset : Nat;

                if (j >= median and j == elem_index and not already_inserted) {
                    offset += 1;
                    already_inserted := true;
                    ?elem;
                } else if (j >= arr_len) {
                    null;
                } else {
                    extract(leaf.kvs, j);
                };
            },
        );

        var j = median - 1 : Nat;

        while (j > elem_index) {
            leaf.kvs[j] := leaf.kvs[j - 1];
            j -= 1;
        };

        if (j == elem_index) {
            leaf.kvs[j] := ?elem;
        };

        leaf.count := median;
        let right_cnt = arr_len + 1 - median : Nat;
        let right_node = Leaf.new<K, V>(leaf.kvs.size(), right_cnt, ?right_kvs);

        right_node.index := leaf.index + 1;
        right_node.parent := leaf.parent;

        // update next pointers
        right_node.next := leaf.next;
        leaf.next := ?right_node;

        right_node;
    };

    public func split_branch<K, V>(node : Branch<K, V>, child : Node<K, V>, child_index : Nat, first_child_key : K) : Branch<K, V> {
        let arr_len = node.count;
        let median = (arr_len / 2) + 1;

        let is_elem_added_to_right = child_index >= median;

        var median_key = ?first_child_key;

        var offset = if (is_elem_added_to_right) 0 else 1;
        var already_inserted = false;

        let right = Branch.new<K, V>(node.children.size(), null);

        let right_keys = Array.init<?K>(node.keys.size(), null);

        let right_children = Array.tabulateVar<?Node<K, V>>(
            node.children.size(),
            func(i : Nat) : ?Node<K, V> {

                let j = i + median - offset : Nat;

                let child_node = if (j >= median and j == child_index and not already_inserted) {
                    offset += 1;
                    already_inserted := true;
                    if (i > 0) right_keys[i - 1] := ?first_child_key;
                    ?child;
                } else if (j >= arr_len) {
                    null;
                } else {
                    if (i == 0) {
                        median_key := node.keys[j - 1];
                    } else {
                        right_keys[i - 1] := node.keys[j - 1];
                    };
                    node.keys[j - 1] := null;

                    extract(node.children, j);
                };

                switch (child_node) {
                    case (? #branch(node) or ? #leaf(node) : ?SharedNode<K, V>) {
                        node.index := i;
                    };
                    case (_) {};
                };

                child_node;
            },
        );

        var j = median - 1 : Nat;

        while (j > child_index) {
            if (j >= 2) {
                node.keys[j - 1] := node.keys[j - 2];
            };

            node.children[j] := node.children[j - 1];

            switch (node.children[j]) {
                case (? #branch(node) or ? #leaf(node) : ?SharedNode<K, V>) {
                    node.index := j;
                };
                case (_) {};
            };

            j -= 1;
        };

        if (j == child_index) {
            if (j > 0) {
                node.keys[j - 1] := ?first_child_key;
            } else {
                let key : ?K = switch (node.children[j]) {
                    case (? #branch(node)) {
                        node.keys[0];
                    };
                    case (? #leaf(node)) {
                        switch (node.kvs[0]) {
                            case (?kv) ?kv.0;
                            case (_) Debug.trap("split_branch: accessed a null value");
                        };
                    };
                    case (_) Debug.trap("split_branch: accessed a null value");
                };

                node.keys[0] := key;
            };

            node.children[j] := ?child;
        };

        node.count := median;
        let right_cnt = node.children.size() + 1 - median : Nat;

        let right_node = switch (node.children[0]) {
            case (? #leaf(_)) Branch.new(node.children.size(), ?right_children);
            case (? #branch(_)) {
                Branch.newWithKeys<K, V>(right_keys, right_children);
                // Branch.new( node.children.size(), ?right_children);
            };
            case (_) Debug.trap("right_node: accessed a null value");
        };

        right_node.index := node.index + 1;

        right_node.count := right_cnt;
        right_node.parent := node.parent;

        // assert validate_indexes(node.children, node.count);
        // assert validate_array_equal_count(node.keys, node.count - 1 : Nat);
        // assert validate_array_equal_count(node.children, node.count);

        // assert validate_indexes(right_node.children, right_node.count);
        // assert validate_array_equal_count(right_node.keys, right_node.count - 1 : Nat);
        // assert validate_array_equal_count(right_node.children, right_node.count);

        // store the first key of the right node at the end of the keys in left node
        // no need to delete as the value will get overwritten because it exceeds the count position
        right_node.keys[right_node.keys.size() - 1] := median_key;

        right_node;
    };

    public func validate_array_equal_count<T>(arr : [var ?T], count : Nat) : Bool {
        var i = 0;

        for (opt_elem in arr.vals()) {
            let ?elem = opt_elem else return i == count;
            i += 1;
        };

        i == count;
    };

    public func validate_indexes<K, V>(arr : [var ?Node<K, V>], count : Nat) : Bool {

        var i = 0;

        while (i < count) {
            switch (arr[i] : ?SharedNode<K, V>) {
                case (? #branch(node) or ? #leaf(node)) {
                    if (node.index != i) return false;
                };
                case (_) Debug.trap("validate_indexes: accessed a null value");
            };
            i += 1;
        };

        true;
    };

    public func is_sorted<T>(arr: [var ?T], cmp: CmpFn<T>): Bool {
        var i = 0;

        while (i < ((arr.size() - 1) : Nat)) {
            let ?a = arr[i] else return true;
            let ?b = arr[i + 1] else return true;

            if (cmp(a, b) == #greater) return false;
            i += 1;
        };

        true;

    };

    public func indexes<K, V>(children : [var ?Node<K, V>]) : [Int] {
        Array.map<?Node<K, V>, Int>(
            Array.freeze(children),
            func(opt_node : ?Node<K, V>) : Int {
                switch (opt_node) {
                    case ((? #branch(node) or ? #leaf(node)) : ?SharedNode<K, V>) node.index;
                    case (_) -1;
                };
            },
        );
    };

    public func insert(self : BpTree<Nat, Nat>, cmp : CmpFn<Nat>, key : Nat, val : Nat) : ?Nat {

        let leaf_node = get_leaf_node<Nat, Nat>(self, cmp, key);

        let entry = (key, val);

        let int_elem_index = binary_search<(Nat, Nat), Nat>(leaf_node.kvs, adapt_cmp(cmp), key, leaf_node.count);
        let elem_index = if (int_elem_index >= 0) Int.abs(int_elem_index) else Int.abs(int_elem_index + 1);

        let prev_value = if (int_elem_index >= 0) {
            let ?kv = leaf_node.kvs[elem_index] else Debug.trap("1. insert: accessed a null value while replacing a key-value pair");
            leaf_node.kvs[elem_index] := ?entry;
            return ?kv.1;
        } else {
            null;
        };

        if (leaf_node.count < self.order) {
            // shift elems to the right and insert the new key-value pair
            var j = leaf_node.count;

            while (j > elem_index) {
                leaf_node.kvs[j] := leaf_node.kvs[j - 1];
                j -= 1;
            };

            leaf_node.kvs[elem_index] := ?entry;
            leaf_node.count += 1;

            self.size += 1;
            return prev_value;
        };

        // split leaf node
        let right_leaf_node = split_leaf(leaf_node, elem_index, entry);

        var opt_parent : ?Branch<Nat, Nat> = leaf_node.parent;
        var left_node : Node<Nat, Nat> = #leaf(leaf_node);
        var left_index = leaf_node.index;

        var right_index = right_leaf_node.index;
        let ?right_leaf_first_entry = right_leaf_node.kvs[0] else Debug.trap("2. insert: accessed a null value");
        var right_key = right_leaf_first_entry.0;
        var right_node : Node<Nat, Nat> = #leaf(right_leaf_node);

        // insert split leaf nodes into parent nodes if there is space
        // or iteratively split parent (internal) nodes to make space
        label index_split_loop while (Option.isSome(opt_parent)) {
            let ?parent = opt_parent else Debug.trap("3. insert: accessed a null parent value");

            if (parent.count < self.order) {
                var j = parent.count;

                while (j >= right_index) {
                    if (j == right_index) {
                        parent.keys[j - 1] := ?right_key;
                        parent.children[j] := ?right_node;
                    } else {
                        parent.keys[j - 1] := parent.keys[j - 2];
                        parent.children[j] := parent.children[j - 1];
                    };

                    switch (parent.children[j]) {
                        case ((? #branch(node) or ? #leaf(node)) : ?SharedNode<Nat, Nat>) {

                            node.index := j;
                        };
                        case (_) {};
                    };

                    j -= 1;
                };

                parent.count += 1;

                self.size += 1;
                return prev_value;

            } else {
                
                let median = (parent.count / 2) + 1; // include inserted key-value pair
                let split_node = split_branch(parent, right_node, right_index, right_key);

                let ?first_key = extract(split_node.keys, split_node.keys.size() - 1 : Nat) else Debug.trap("4. insert: accessed a null value in first key of branch");
                right_key := first_key;
               
                left_node := #branch(parent);
                right_node := #branch(split_node);

                right_index := split_node.index;
                opt_parent := split_node.parent;
            };
        };

        
        let children = Array.init<?Node<Nat, Nat>>(self.order, null);
        children[0] := ?left_node;
        children[1] := ?right_node;

        let root_node = Branch.new<Nat, Nat>(self.order, ?children);
        root_node.keys[0] := ?right_key;
        assert root_node.count == 2;

        self.root := #branch(root_node);
       
        self.size += 1;
        prev_value;

    };

    public func redistribute_leaf_keys(leaf_node : Leaf<Nat, Nat>){

        let ?parent = leaf_node.parent else return; 

        var adj_node = leaf_node;
        if (parent.count > 1){
            if (leaf_node.index != 0){
                let ?#leaf(left_adj_node) = parent.children[leaf_node.index - 1] else Debug.trap("1. redistribute_leaf_keys: accessed a null value");
                adj_node := left_adj_node;
            };

            if (leaf_node.index != (parent.count - 1 : Nat)){
                let ?#leaf(right_adj_node) = parent.children[leaf_node.index + 1] else Debug.trap("2. redistribute_leaf_keys: accessed a null value");
                if (right_adj_node.count > adj_node.count){
                    adj_node := right_adj_node;
                };
            };
        };

        if (adj_node.index == leaf_node.index) return; // no adjacent node to distribute data to

        let sum_count = leaf_node.count + adj_node.count;
        let min_count_for_both_nodes = leaf_node.kvs.size();

        if (sum_count < min_count_for_both_nodes) return; // not enough entries to distribute

        let data_to_move = (sum_count / 2 ) - leaf_node.count : Nat;

        // distribute data between adjacent nodes
        if (adj_node.index < leaf_node.index){ 
            // adj_node is before leaf_node
            var i = adj_node.count - 1 : Nat;

            for (_ in Iter.range(0, data_to_move - 1)){
                let val = ArrayMut.remove(adj_node.kvs, i, adj_node.count);
                ArrayMut.insert(leaf_node.kvs, 0, val, leaf_node.count);

                i -= 1;
            };
        }else { 
            // adj_node is after leaf_node
            var j = leaf_node.count;
            
            for (_ in Iter.range(0, data_to_move - 1)){
                let val = ArrayMut.remove(adj_node.kvs, 0, adj_node.count);
                ArrayMut.insert(leaf_node.kvs, j, val, leaf_node.count);

                j += 1;
            };
        };

        adj_node.count -= data_to_move;
        leaf_node.count += data_to_move;

        // assert validate_array_equal_count(leaf_node.kvs, leaf_node.count);
        // assert validate_array_equal_count(adj_node.kvs, adj_node.count);

        // update parent keys
        if (adj_node.index < leaf_node.index){
            // no need to worry about leaf_node.index - 1 being out of bounds because
            // the adj_node is before the leaf_node, meaning the leaf_node is not the first child
            let ?leaf_2nd_entry = leaf_node.kvs[0] else Debug.trap("3. redistribute_leaf_keys: accessed a null value");
            let leaf_node_key = leaf_2nd_entry.0;
            
            let key_index = leaf_node.index - 1 : Nat;
            parent.keys[key_index] := ?leaf_node_key;
        }else {
            // and vice versa
            let ?adj_2nd_entry = adj_node.kvs[0] else Debug.trap("4. redistribute_leaf_keys: accessed a null value");
            let adj_node_key = adj_2nd_entry.0;

            let key_index = adj_node.index - 1 : Nat;
            parent.keys[key_index] := ?adj_node_key;
        };

        // assert validate_array_equal_count(parent.keys, parent.count - 1 : Nat);
        // assert validate_array_equal_count(parent.children, parent.count);
        // assert validate_indexes(parent.children, parent.count);
    };

    public func redistribute_branch_keys(branch_node: Branch<Nat, Nat>){
        var adj_node = branch_node;
        
        // retrieve adjacent node
        switch(branch_node.parent){
            case (null) {};
            case (?parent){
                if (parent.count > 1){
                    if (branch_node.index != 0){
                        let ?#branch(left_adj_node) = parent.children[branch_node.index - 1] else Debug.trap("1. redistribute_branch_keys: accessed a null value");
                        adj_node := left_adj_node;
                    };

                    if (branch_node.index + 1 != parent.count){
                        let ?#branch(right_adj_node) = parent.children[branch_node.index + 1] else Debug.trap("2. redistribute_branch_keys: accessed a null value");
                        if (right_adj_node.count > adj_node.count){
                            adj_node := right_adj_node;
                        };
                    };
                }
            }
        };

        if (adj_node.index == branch_node.index) return; // no adjacent node to distribute data to

        let sum_count = branch_node.count + adj_node.count;
        let min_count_for_both_nodes = branch_node.children.size();

        if (sum_count < min_count_for_both_nodes) return; // not enough entries to distribute

        let data_to_move = (sum_count / 2) - branch_node.count : Nat;

        // every node from this point on has a parent because an adjacent node was found
        let ?parent = branch_node.parent else Debug.trap("3. redistribute_branch_keys: accessed a null value");
        
        // distribute data between adjacent nodes
        if (adj_node.index < branch_node.index){ 
            // adj_node is before branch_node
            var i = adj_node.count - 1 : Nat;
            var median_key = parent.keys[adj_node.index];

            for (_ in Iter.range(0, data_to_move - 1)){
                ArrayMut.insert(branch_node.keys, 0, median_key, branch_node.count - 1: Nat);
                median_key := ArrayMut.remove(adj_node.keys, i - 1 : Nat, adj_node.count - 1 : Nat);

                let val = Utils.unwrap(Branch.remove(adj_node, i), "4. redistribute_branch_keys: accessed a null value");
                Branch.insert<Nat, Nat>(branch_node, 0, val);

                i -= 1;
            };

            parent.keys[adj_node.index] := median_key;

        }else { 
            // adj_node is after branch_node

            var j = branch_node.count : Nat;
            var median_key = parent.keys[branch_node.index];
            
            for (_ in Iter.range(0, data_to_move - 1)){
                
                ArrayMut.insert(branch_node.keys, j - 1 : Nat, median_key, branch_node.count - 1: Nat);
                median_key := ArrayMut.remove(adj_node.keys, 0, adj_node.count - 1 : Nat);

                let val = Utils.unwrap(Branch.remove(adj_node, 0), "5. redistribute_branch_keys: accessed a null value");
                Branch.insert(branch_node, j, val);

                j += 1;
            };

            parent.keys[branch_node.index] := median_key;

        };

        adj_node.count -= data_to_move;
        branch_node.count += data_to_move;

        // assert validate_array_equal_count(branch_node.children, branch_node.count);
        // assert validate_indexes(branch_node.children, branch_node.count);

        // assert validate_array_equal_count(adj_node.children, adj_node.count);
        // assert validate_indexes(adj_node.children, adj_node.count);

        // assert validate_array_equal_count(parent.children, parent.count);
        // assert validate_indexes(parent.children, parent.count);

    };

    // merges two leaf nodes into the left node
    public func merge_leaf_nodes(left: Leaf<Nat, Nat>, right: Leaf<Nat, Nat>){
        let min_count = left.kvs.size() / 2;

        // merge right into left
        var i = 0;
        var j = 0;

        
        for (_ in Iter.range(0, right.count - 1)){
            let val = right.kvs[i];
            ArrayMut.insert(left.kvs, left.count + i, val, left.count);

            i += 1;
        };

        left.count += right.count;

        // update next pointers
        left.next := right.next;

        // update parent keys
        switch(left.parent){
            case (null) {};
            case (?parent){
                ignore ArrayMut.remove(parent.keys, right.index - 1 : Nat, parent.count - 1 : Nat);
                ignore Branch.remove(parent, right.index : Nat);

                parent.count -= 1;
                // assert validate_array_equal_count(parent.children, parent.count);
                // assert validate_indexes(parent.children, parent.count);
            };
        };


    };

    public func merge_branch_nodes(left: Branch<Nat, Nat>, right: Branch<Nat, Nat>){
        assert left.index + 1 == right.index;

        let min_count = left.children.size() / 2;

        // merge right into left
        var i = left.count : Nat;

        // if there are two adjacent nodes then there must be a parent
        let ?parent = left.parent else Debug.trap("1. merge_branch_nodes: accessed a null value");

        var median_key = parent.keys[right.index - 1];

        for (_ in Iter.range(0, right.count - 1)){
            ArrayMut.insert(left.keys, i - 1 : Nat, median_key, left.count - 1 : Nat);
            median_key := ArrayMut.remove(right.keys, 0, right.count - 1 : Nat);

            let ?child = ArrayMut.remove(right.children, 0, right.count) else Debug.trap("2. merge_branch_nodes: accessed a null value");
            Branch.insert(left, i, child);
            i += 1;
        };

        left.count += right.count;

        // assert validate_array_equal_count(left.children, left.count);
        // assert validate_indexes(left.children, left.count);

        // update parent keys
        ignore ArrayMut.remove(parent.keys, right.index - 1 : Nat, parent.count - 1 : Nat);
        ignore Branch.remove(parent, right.index);
        parent.count -= 1;

        // assert validate_array_equal_count(parent.children, parent.count);
        // assert validate_indexes(parent.children, parent.count);
    };
    
    public func remove(self: BpTree<Nat, Nat>, cmp: CmpFn<Nat>, key: Nat) : ?Nat {
        let leaf_node = get_leaf_node<Nat, Nat>(self, cmp, key);

        let int_elem_index = binary_search<(Nat, Nat), Nat>(leaf_node.kvs, adapt_cmp(cmp), key, leaf_node.count);
        let elem_index = if (int_elem_index >= 0) Int.abs(int_elem_index) else return null;
        // remove parent key as well
        let ?entry : ?(Nat, Nat) = ArrayMut.remove(leaf_node.kvs, elem_index, leaf_node.count) 
            else Debug.trap("1. remove: accessed a null value");

        let deleted = entry.1;
        self.size -= 1;
        leaf_node.count -= 1;

        let min_count = self.order / 2;

        let ?_parent = leaf_node.parent else return ?deleted; // if parent is null then leaf_node is the root
        var parent = _parent;

        func update_deleted_median_key(_parent: Branch<Nat, Nat>, index: Nat, deleted_key: Nat, next_key: Nat){
            var parent = _parent;
            var i = index;

            while (i == 0){
                i:= parent.index;
                let ?__parent = parent.parent else return; // occurs when key is the first key in the tree
                parent := __parent;
            };

            assert parent.keys[i - 1] == ?deleted_key;
            parent.keys[i - 1] := ?next_key;
        };

        if (elem_index == 0){
            let next = leaf_node.kvs[elem_index]; // same as entry index because we removed the entry from the array
            let ?next_key = do?{next!.0} else Debug.trap("update_deleted_median_key: accessed a null value");
            update_deleted_median_key(parent, leaf_node.index, key, next_key);
        };

        if (leaf_node.count >= min_count) return ?deleted;

        redistribute_leaf_keys(leaf_node);

        if (leaf_node.count >= min_count) return ?deleted;

        // the parent will always have (self.order / 2) children
        let opt_adj_node = if (leaf_node.index == 0) {
            parent.children[1];
        } else {
            parent.children[leaf_node.index - 1];
        };

        let ?#leaf(adj_node) = opt_adj_node else return ?deleted;

        if (adj_node.index < leaf_node.index){
            merge_leaf_nodes(adj_node, leaf_node);
        } else {
            merge_leaf_nodes(leaf_node, adj_node);
        };

        // assert validate_array_equal_count(parent.children, parent.count);

        var branch_node = parent;
        let ?__parent = branch_node.parent else { 
            
            // update root node as this node does not have a parent
            // which means it is the root node
            if (branch_node.count == 1){
                let ?child = branch_node.children[0] else Debug.trap("3. remove: accessed a null value");
                switch(child){
                    case (#branch(node) or #leaf(node): SharedNode<Nat, Nat>) {
                        node.parent := null;
                    };
                };
                self.root := child;

                // Debug.print("new root keys" # debug_show toNodeKeys(self));
                // Debug.print("new root leafs" # debug_show toLeafNodes(self));
            };
            
            return ?deleted
        };

        parent := __parent;

        // Debug.print("branch_node count (" # debug_show branch_node.count # ") < min_count (" # debug_show min_count # ") ");

        while (branch_node.count < min_count) {
            redistribute_branch_keys(branch_node);
            if (branch_node.count >= min_count) return ?deleted;

            let ?#branch(adj_branch_node) = if (branch_node.index == 0) {
                parent.children[1];
            } else {
                parent.children[branch_node.index - 1];
            } else {
                // if the adjacent node is null then the branch node is the only child of the parent
                // this only happens if the branch node is the root node

                // update root node if necessary
                assert parent.count == 1;
                let ?child = parent.children[0] else Debug.trap("3. remove: accessed a null value");
                self.root := child;

                return ?deleted
            };

            let left_node = if (adj_branch_node.index < branch_node.index) adj_branch_node else branch_node;
            let right_node = if (adj_branch_node.index < branch_node.index) branch_node else adj_branch_node;

            merge_branch_nodes(left_node, right_node);

            branch_node := parent;
            let ?_parent = branch_node.parent else {
                // update root node if necessary
                if (branch_node.count == 1){
                    let ?child = branch_node.children[0] else Debug.trap("3. remove: accessed a null value");
                    switch(child){
                        case (#branch(node) or #leaf(node): SharedNode<Nat, Nat>) {
                            node.parent := null;
                        };
                    };
                    self.root := child;
                };

                return ?deleted;
            };

            parent := _parent;
        };

        ?deleted;
    };

    public func min<K, V>(self : BpTree<K, V>) : ?(K, V) {
        let leaf_node = get_min_leaf_node(self) else return null;
        leaf_node.kvs[0];
    };

    public func max<K, V>(self : BpTree<K, V>) : ?(K, V) {
        let leaf_node = get_min_leaf_node(self) else return null;
        leaf_node.kvs[leaf_node.count - 1];
    };

    public func fromEntries(entries: Iter<(Nat, Nat)>, cmp: CmpFn<Nat> ) : BpTree<Nat, Nat> {
        let bptree = BpTree.newWithOrder<Nat, Nat>(4);

        for (entry in entries) {
            let (k, v) = entry;
            ignore insert(bptree, cmp, entry.0, entry.1);
        };

        bptree;
    };

    public func fromArray(arr : [(Nat, Nat)], cmp: CmpFn<Nat>) : BpTree<Nat, Nat> {
        let bptree = BpTree.new<Nat, Nat>();

        for (kv in arr.vals()) {
            let (k, v) = kv;
            ignore insert(bptree, cmp, k, v);
        };

        bptree;
    };

    public func toArray<K, V>(self : BpTree<K, V>) : [(K, V)] {
        var node = ?self.root;
        let buffer = Buffer.Buffer<(K, V)>(self.size);

        var leaf_node : ?Leaf<K, V> = ?get_min_leaf_node(self);

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

        Buffer.toArray(buffer);
    };

    public func entries<K, V>(self : BpTree<K, V>) : Iter<(K, V)> {
        var node = ?get_min_leaf_node(self);
        var i = 0;

        object {
            public func next() : ?(K, V) {
                switch (node) {
                    case (?leaf) {
                        if (i >= leaf.count) {
                            node := leaf.next;
                            i := 0;
                            return next();
                        };

                        let entry = leaf.kvs[i];
                        i += 1;
                        entry;
                    };
                    case (_) null;
                };
            };
        };
    };

    public func keys<K, V>(self : BpTree<K, V>) : Iter<K> {
        Iter.map(
            entries(self),
            func(kv : (K, V)) : K {
                kv.0;
            },
        );
    };

    public func vals<K, V>(self : BpTree<K, V>) : Iter<V> {
        Iter.map(
            entries(self),
            func(kv : (K, V)) : V {
                kv.1;
            },
        );
    };


    /// Returns an iterator over the entries of the tree in the range [start, end]
    /// The iterator is inclusive of start and end
    public func range<K, V>(self: BpTree<K, V>, cmp: CmpFn<K>, start: K, end: K) : Iter<(K, V)> {
        var leaf_node = get_leaf_node<K, V>(self, cmp, start);

        let b_index = binary_search<(K, V), K>(leaf_node.kvs, adapt_cmp(cmp), start, leaf_node.count);

        // if b_index is negative then the element was not found
        // moreover if b_index is negative then abs(i) - 1 is the index of the first element greater than start
        var i = if (b_index >= 0) Int.abs(b_index) else Int.abs(b_index) - 1 : Nat; 

        var node = ?leaf_node;

        object {
            public func next() : ?(K, V) {
                switch (node) {
                    case (null) null;
                    case (?leaf) {
                        if (i >= leaf.count) {
                            node := leaf.next;
                            i := 0;
                            return next();
                        };

                        switch(leaf.kvs[i]){
                            case (?kv) {
                                if (cmp(kv.0, end) == #greater) {
                                    node := null;
                                    return null;
                                };

                                i += 1;
                                ?kv;
                            };
                            case (_) Debug.trap("range: accessed a null value");
                        };
                    };
                };
            };
        };
    };

    public func toLeafNodes<K, V>(self : BpTree<K, V>) : [[?(K, V)]] {
        var node = ?self.root;
        let buffer = Buffer.Buffer<[?(K, V)]>(self.size);

        var leaf_node : ?Leaf<K, V> = ?get_min_leaf_node(self);

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

        Buffer.toArray(buffer);
    };

    public func toNodeKeys<K, V>(self : BpTree<K, V>) : [[(Nat, [?K])]] {
        var nodes = BufferDeque.fromArray<?Node<K, V>>([?self.root]);
        let buffer = Buffer.Buffer<[(Nat, [?K])]>(self.size / 2);

        while (nodes.size() > 0) {
            let row = Buffer.Buffer<(Nat, [?K])>(nodes.size());

            for (_ in Iter.range(1, nodes.size())) {
                let ?node = nodes.popFront() else Debug.trap("toNodeKeys: accessed a null value");

                switch (node) {
                    case (? #branch(node)) {
                        let node_buffer = Buffer.Buffer<?K>(node.keys.size());
                        for (key in node.keys.vals()) {
                            node_buffer.add(key);
                        };

                        for (child in node.children.vals()) {
                            nodes.addBack(child);
                        };

                        row.add((node.index, Buffer.toArray(node_buffer)));
                    };
                    case (_) {};
                };
            };

            buffer.add(Buffer.toArray(row));
        };

        Buffer.toArray(buffer);
    };

};
