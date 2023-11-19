import T "Types";
import InternalTypes "../internal/Types";
import BpTree "../BpTree";

module MaxBpTree {

    public type MaxBpTree<K, V> = T.MaxBpTree<K, V>;
    public type Node<K, V> = T.Node<K, V>;
    public type Leaf<K, V> = T.Leaf<K, V>;
    public type Branch<K, V> = T.Branch<K, V>;
    type SharedNodeFields<K, V> = T.SharedNodeFields<K, V>;
    type SharedNode<K, V> = T.SharedNode<K, V>;
    type MultiCmpFn<A, B> = InternalTypes.MultiCmpFn<A, B>;

    // public func new<K, V>() : MaxBpTree<K, V> {
    //     return {
    //         order = 32;
    //         root = Leaf
    //     };
    // };
}