use dep::std::hash::pedersen_hash;

// Recompute Merkle root from a leaf, its index, and the sibling path.
fn compute_merkle_root(leaf: Field, index: Field, hashPath: [Field; 8]) -> Field {
    let index_bits = index.to_le_bits::<8>();
    let mut current = leaf;

    for i in 0..8 {
        let sibling = hashPath[i];
        let bit = index_bits[i] as Field;

        let left = (1 - bit) * current + bit * sibling;
        let right = bit * current + (1 - bit) * sibling;

        current = pedersen_hash([left, right]);
    }

    current
}

fn main(
    // Private inputs
    id: Field,
    r: Field,
    hashPath: [Field; 8],

    // Public inputs
    oldRoot: pub Field,
    newRoot: pub Field,
    commitment: pub Field,
    index: pub Field,
) {
    let computed_commitment = pedersen_hash([id, r]);
    assert(computed_commitment == commitment);

    let empty_leaf: Field = 0x2df8b940e5890e4e1377e05373fae69a1d754f6935e6a780b666947431f2cdcd;
    let computed_old_root = compute_merkle_root(empty_leaf, index, hashPath);
    assert(computed_old_root == oldRoot);

    let computed_new_root = compute_merkle_root(commitment, index, hashPath);
    assert(computed_new_root == newRoot);
}
