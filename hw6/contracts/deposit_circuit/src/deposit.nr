use dep::std::hash::pedersen_hash;

// 256-leaf Merkle tree => depth = 8
global DEPTH: u32 = 8;

// Recompute Merkle root from a leaf, its index, and the sibling path.
// index_bits[0] is the least-significant bit (bottom of the tree).
fn compute_merkle_root(leaf: Field, index: Field, hash_path: [Field; 8]) -> Field {
    let index_bits = index.to_le_bits(8);
    let mut current = leaf;
    for i in 0..8 {
        let sibling = hash_path[i];
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
    id:       Field,
    r:        Field,
    hashPath: [Field; 8],

    // ── Public inputs ───────────────────────────────────────────────────────
    oldRoot:    pub Field,   // Merkle root before deposit
    newRoot:    pub Field,   // Merkle root after deposit
    commitment: pub Field,   // PedersenHash(id, r)
    index:      pub Field,   // Leaf index where the commitment is inserted
) {
    // 1. Verify commitment == PedersenHash(id, r)
    let computed_commitment = pedersen_hash([id, r]);
    assert(computed_commitment == commitment);

    // 2. Verify that the leaf at `index` was previously the empty-leaf value,
    //    and that the supplied hashPath produces oldRoot.
    //    Empty leaf = Pedersen hash of 0, as defined in the assignment.
    let empty_leaf: Field = 0x2df8b940e5890e4e1377e05373fae69a1d754f6935e6a780b666947431f2cdcd;
    let computed_old_root = compute_merkle_root(empty_leaf, index, hashPath);
    assert(computed_old_root == oldRoot);

    // 3. Verify that inserting `commitment` at `index` (same sibling path,
    //    because siblings are unchanged) produces newRoot.
    let computed_new_root = compute_merkle_root(commitment, index, hashPath);
    assert(computed_new_root == newRoot);
}
