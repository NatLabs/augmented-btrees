import BpTree "../BpTree";
import BpTreeTypes "../BpTree/Types";

module {
    public type Leaf<K, V> = BpTree.Leaf<K, V> and {
        var max: K;
    };

    public type Branch<K, V> = BpTree.Branch<K, V> and {
        var max: K;
    };

    public type Node<K, V> = {
        #leaf : Leaf<K, V>;
        #branch : Branch<K, V>;
    };

    public type MaxBpTree<K, V> = {
        order : Nat;
        var root : Node<K, V>;
        var size : Nat;
    };

    public type SharedNode<K, V> = BpTreeTypes.SharedNode<K, V>;
    public type SharedNodeFields<K, V> = BpTreeTypes.SharedNodeFields<K, V>;
}
