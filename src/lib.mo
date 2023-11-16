import BpTreeModule "BpTree";

module {
    public let BpTree = BpTreeModule;
    public type BpTree<K, V> = BpTreeModule.BpTree<K, V>;

    public let { Leaf; Branch } = BpTreeModule;

    public type Leaf<K, V> = BpTreeModule.Leaf<K, V>;
    public type Branch<K, V> = BpTreeModule.Branch<K, V>;
}