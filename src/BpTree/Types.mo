import Order "mo:base/Order";
import InternalTypes "../internal/Types";

module {
    type Order = Order.Order;

    public type CmpFn<K> = InternalTypes.CmpFn<K>;

    
    public type BpTree<K, V> = {
        order : Nat;
        var root : Node<K, V>;
        var size : Nat;
        var next_id : Nat;
    };

    public type Node<K, V> = {
        #leaf : Leaf<K, V>;
        #branch : Branch<K, V>;
    };

    /// Branch nodes store keys and pointers to child nodes.
    public type Branch<K, V> = {
        /// Unique id representing the branch as a node.
        id : Nat;

        /// The parent branch node.
        var parent : ?Branch<K, V>;

        /// The index of this branch node in the parent branch node.
        var index : Nat;

        /// The keys in this branch node.
        var keys : [var ?K];

        /// The child nodes in this branch node.
        var children : [var ?Node<K, V>];

        /// The number of child nodes in this branch node.
        var count : Nat;

        /// The total number of nodes in the subtree rooted at this branch node.
        var subtree_size : Nat; 
        // optimal approach replaces the subtree_size with prefix sum array to enable binary search
        //  in branch nodes when executing getRank()
        //  might not replace as we can afford to have a getRank() fn that is not the most optimized
        //  -> runs in O((log n) ^ 2) instead of O(log n)
    };

    /// Leaf nodes are doubly linked lists of key-value pairs.
    public type Leaf<K, V> = {
        /// Unique id representing the leaf as a node.
        id : Nat;

        /// The parent branch node.
        var parent : ?Branch<K, V>;

        /// The index of this leaf node in the parent branch node.
        var index : Nat;

        /// The key-value pairs in this leaf node.
        kvs : [var ?(K, V)];

        /// The number of key-value pairs in this leaf node.
        var count : Nat;

        /// The next leaf node in the linked list.
        var next : ?Leaf<K, V>;

        /// The previous leaf node in the linked list.
        var prev : ?Leaf<K, V>;
    };

    public type CommonFields<K, V> = Leaf<K, V> or Branch<K, V>;

    public type CommonNodeFields<K, V> = {
        #leaf : CommonFields<K, V>;
        #branch : CommonFields<K, V>;
    };


};
