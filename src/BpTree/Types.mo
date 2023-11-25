import Order "mo:base/Order";
import InternalTypes "../internal/Types";

module {
    type Order = Order.Order;

    public type CmpFn<K> = InternalTypes.CmpFn<K>;

    public type BpTreeType<Node> = {
        var order : Nat;
        var root : Node;
        var size : Nat;
    };

    public type BpTreeNodeType<Leaf, Branch> = {
        #leaf : Leaf;
        #branch : Branch;
    };

    public type BpTreeBranchType<K, V, NodeType> = {
        var parent : ?BpTreeBranchType<K, V, NodeType>;
        var index : Nat;
        var keys : [var ?K];
        var children : [var ?NodeType];
        var count : Nat;
    };

    public type BpTreeLeafType<K, V, BranchType> = {
        var parent : ?BranchType;
        var index : Nat;
        kvs : [var ?(K, V)];
        var count : Nat;
        var next : ?BpTreeLeafType<K, V, BranchType>;
    };

    public type BpTreeNodeV2<K, V> = BpTreeNodeType<BpTreeLeafV2<K, V>, BpTreeNodeV2<K, V>>;
    public type BpTreeBranchV2<K, V> = BpTreeBranchType<K, V, BpTreeNodeV2<K, V>>;
    public type BpTreeLeafV2<K, V> = BpTreeLeafType<K, V, BpTreeBranchV2<K, V>>;
    public type BpTreeV2<K, V> = BpTreeType<BpTreeNodeV2<K, V>>;

    public type BpTree<K, V> = {
        order : Nat;
        var root : Node<K, V>;
        var size : Nat;
    };

    public type Node<K, V> = {
        #leaf : Leaf<K, V>;
        #branch : Branch<K, V>;
    };

    /// Branch nodes store keys and pointers to child nodes.
    public type Branch<K, V> = {
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

    };

    /// Leaf nodes are doubly linked lists of key-value pairs.
    public type Leaf<K, V> = {
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

    public type SharedNodeFields<K, V> = {
        var count : Nat;
        var index : Nat;
        var parent : ?Branch<K, V>;
    };

    public type SharedNode<K, V> = {
        #leaf : SharedNodeFields<K, V>;
        #branch : SharedNodeFields<K, V>;
    };

}