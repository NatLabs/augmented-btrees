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
    public type BpTreeLeafV2<K, V> = BpTreeLeafType<K, V, BpTreeLeafV2<K, V>>;
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

    public type Branch<K, V> = {
        var parent : ?Branch<K, V>;
        var index : Nat;
        var keys : [var ?K];
        var children : [var ?Node<K, V>];
        var count : Nat;
    };

    public type Leaf<K, V> = {
        var parent : ?Branch<K, V>;
        var index : Nat;
        kvs : [var ?(K, V)];
        var count : Nat;
        var next : ?Leaf<K, V>;
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