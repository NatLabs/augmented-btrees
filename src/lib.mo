import BpTreeModule "BpTree";

module {
    public let BpTree = BpTreeModule;
    public type BpTree<K, V> = BpTreeModule.BpTree<K, V>;

    public let { LeafNode; InternalNode } = BpTreeModule;

    public type LeafNode<K, V> = BpTreeModule.LeafNode<K, V>;
    public type InternalNode<K, V> = BpTreeModule.InternalNode<K, V>;
}