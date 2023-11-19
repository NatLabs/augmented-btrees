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

import LeafModule "Leaf";
import BranchModule "Branch";

import ArrayMut "../internal/ArrayMut";
import Utils "../internal/Utils";
import T "Types";

module BpTree {
    type Iter<A> = Iter.Iter<A>;
    type Order = Order.Order;
    type CmpFn<A> = (A, A) -> Order;
    type BufferDeque<A> = BufferDeque.BufferDeque<A>;

    public let Leaf = LeafModule;
    public let Branch = BranchModule;
    
    public type BpTree<K, V> = T.BpTree<K, V>;
    public type Node<K, V> = T.Node<K, V>;
    public type Leaf<K, V> = T.Leaf<K, V>;
    public type Branch<K, V> = T.Branch<K, V>;
    type SharedNodeFields<K, V> = T.SharedNodeFields<K, V>;
    type SharedNode<K, V> = T.SharedNode<K, V>;
    type MultiCmpFn<A, B> = (A, B) -> Order;

    public func new<K, V>() : BpTree<K, V> {
        BpTree.newWithOrder<K, V>(32);
    };

    public func newWithOrder<K, V>(order : Nat) : BpTree<K, V> {
        assert order >= 4 and order <= 512;

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
                    let int_index = ArrayMut.binary_search<K, K>(node.keys, cmp, key, node.count - 1);
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

    public func get_max_leaf_node<K, V>(self : BpTree<K, V>) : Leaf<K, V> {
        var node = ?self.root;

        loop {
            switch (node) {
                case (? #branch(branch)) {
                    node := branch.children[branch.count - 1];
                };
                case (? #leaf(leaf_node)) {
                    return leaf_node;
                };
                case (_) Debug.trap("get_max_leaf_node: accessed a null value");
            };
        };
    };

    public func get<K, V>(self : BpTree<K, V>, cmp : CmpFn<K>, key : K) : ?V {
        let leaf_node = get_leaf_node<K, V>(self, cmp, key);

        let i = ArrayMut.binary_search<(K, V), K>(leaf_node.kvs, adapt_cmp(cmp), key, leaf_node.count);

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

        let int_elem_index = ArrayMut.binary_search<(Nat, Nat), Nat>(leaf_node.kvs, adapt_cmp(cmp), key, leaf_node.count);
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
        let right_leaf_node = Leaf.split(leaf_node, elem_index, entry);

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
                let split_node = Branch.split(parent, right_node, right_index, right_key);

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

    // merges two leaf nodes into the left node
    public func merge_leaf_nodes(left: Leaf<Nat, Nat>, right: Leaf<Nat, Nat>){
        let min_count = left.kvs.size() / 2;

        var i = 0;

        // merge right into left
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
            };
        };
    };

    public func remove(self: BpTree<Nat, Nat>, cmp: CmpFn<Nat>, key: Nat) : ?Nat {
        let leaf_node = get_leaf_node<Nat, Nat>(self, cmp, key);

        let int_elem_index = ArrayMut.binary_search<(Nat, Nat), Nat>(leaf_node.kvs, adapt_cmp(cmp), key, leaf_node.count);
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

        Leaf.redistribute_keys(leaf_node);

        if (leaf_node.count >= min_count) return ?deleted;

        // the parent will always have (self.order / 2) children
        let opt_adj_node = if (leaf_node.index == 0) {
            parent.children[1];
        } else {
            parent.children[leaf_node.index - 1];
        };

        let ?#leaf(adj_node) = opt_adj_node else return ?deleted;

        let left_node = if (adj_node.index < leaf_node.index) adj_node else leaf_node;
        let right_node = if (adj_node.index < leaf_node.index) leaf_node else adj_node;

        Leaf.merge(left_node, right_node);
        // remove merged right node from parent
        ignore ArrayMut.remove(parent.keys, right_node.index - 1 : Nat, parent.count - 1 : Nat);
        ignore Branch.remove(parent, right_node.index : Nat);
        parent.count -= 1;

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
            Branch.redistribute_keys(branch_node);
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

            Branch.merge(left_node, right_node);

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
        let leaf_node = get_max_leaf_node(self) else return null;
        leaf_node.kvs[leaf_node.count - 1];
    };

    public func fromEntries(entries: Iter<(Nat, Nat)>, cmp: CmpFn<Nat> ) : BpTree<Nat, Nat> {
        let bptree = BpTree.new<Nat, Nat>();

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

        let b_index = ArrayMut.binary_search<(K, V), K>(leaf_node.kvs, adapt_cmp(cmp), start, leaf_node.count);

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
