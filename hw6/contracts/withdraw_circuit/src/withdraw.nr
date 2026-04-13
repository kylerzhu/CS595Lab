use dep::std::hash::pedersen_hash;

// Recompute Merkle root from a leaf, its index, and the sibling path.
fn compute_merkle_root(leaf: Field, index: Field, path: [Field; 8]) -> Field {
    let index_bits = index.to_le_bits(8);
    let mut current = leaf;
    for i in 0..8 {
        let sibling = path[i];
        let bit = index_bits[i] as Field;
        // bit == 0 => current is left child, sibling is right child
        // bit == 1 => sibling is left child, current is right child
        let left  = (1 - bit) * current + bit * sibling;
        let right = bit * current + (1 - bit) * sibling;
        current = pedersen_hash([left, right]);
    }
    current
}

fn main(
    // ── Private inputs ──────────────────────────────────────────────────────
    r:     Field,
    index: Field,
    path:  [Field; 8],

    // ── Public inputs ───────────────────────────────────────────────────────
    root: pub Field,   // Current Merkle root stored in the contract
    id:   pub Field,   // Nullifier (revealed to prevent double-spending)
) {
    // 1. Recompute the commitment from the private id and r.
    let commitment = pedersen_hash([id, r]);

    // 2. Prove that `commitment` is the leaf at position `index` and that
    //    the supplied sibling path hashes up to `root`.
    let computed_root = compute_merkle_root(commitment, index, path);
    assert(computed_root == root);
}
