use hex;
use serde::Serialize;
use starknet_crypto::{pedersen_hash, poseidon_hash, poseidon_hash_many, FieldElement};
use std::{collections::HashSet, str::FromStr, vec};

//use super::structs::CairoCalldata;

// Define the Attribute structure
#[derive(Debug, Clone)]
struct Attribute {
    trait_type: FieldElement,
    value: FieldElement,
}

// Define the Token structure
#[derive(Debug, Clone)]
pub struct Token {
    token_id: FieldElement,
    name: FieldElement,
    attributes: Vec<Attribute>,
}

#[derive(Debug, Clone)]
pub struct Node {
    left_child: Option<Box<Node>>,
    right_child: Option<Box<Node>>,
    accessible_token_ids: HashSet<FieldElement>,
    value: FieldElement,
}

// Define the Merkle Tree and Node structures
#[derive(Debug, Clone)]
pub struct MerkleTree {
    root: Node,
    tokens: Vec<Token>,
}

#[derive(Debug, Clone)]
struct CairoCalldata {
    proof: Vec<String>,
}

impl MerkleTree {
    pub fn new(tokens: Vec<Token>) -> Self {
        if tokens.len() == 0 {
            panic!("No data for merkle tree");
        }
        let mut leaves: Vec<Node> = tokens
            .clone()
            .into_iter()
            .map(|a| Node::new_leaf(a))
            .collect();

        // if odd length add a copy of last elem
        if leaves.len() % 2 == 1 {
            leaves.push(leaves.last().unwrap().clone());
        }

        let root = build_tree(leaves);

        MerkleTree { root, tokens }
    }

    pub fn token_calldata(&self, token_id: u128) -> Result<CairoCalldata, String> {
        let felt_token_id = FieldElement::from(token_id);

        if !&self.root.accessible_token_ids.contains(&felt_token_id) {
            return Err("Token ID not found in tree".to_string());
        }
        let mut hashes: Vec<FieldElement> = vec![];
        let mut current_node = &self.root;
        // if either child is_some, then both is_some
        loop {
            let left = current_node.left_child.as_ref().unwrap();
            let right = current_node.right_child.as_ref().unwrap();
            if left.accessible_token_ids.contains(&felt_token_id) {
                hashes.push(right.value);
                current_node = left;
            } else {
                hashes.push(left.value);
                current_node = right;
            }
            if current_node.left_child.is_none() {
                break;
            }
        }
        // reverse to leaf first root last
        hashes = hashes.into_iter().rev().collect();

        let hash_strings = hashes.iter().map(felt_to_b16).collect();

        let calldata = CairoCalldata {
            proof: hash_strings,
        };
        Ok(calldata)
    }
}
impl Node {
    fn new(a: Node, b: Node) -> Self {
        let (left_child, right_child) = if a.value < b.value { (a, b) } else { (b, a) };
        let value = hash(&left_child.value, &right_child.value);
        let mut accessible_token_ids = HashSet::new();
        accessible_token_ids.extend(left_child.accessible_token_ids.clone());
        accessible_token_ids.extend(right_child.accessible_token_ids.clone());

        Node {
            left_child: Some(Box::new(left_child)),
            right_child: Some(Box::new(right_child)),
            accessible_token_ids,
            value,
        }
    }
    fn new_leaf(token: Token) -> Self {
        let token_id = token.token_id;
        let name = token.name;

        let mut value2 = poseidon_hash(token_id, name);

        //for attr in token.attributes {
        //   value2 = poseidon_hash(value2, attr.trait_type);
        //   value2 = poseidon_hash(value2, attr.value);}

        let mut values = vec![token.token_id, token.name];
        for attr in token.attributes {
            values.push(attr.trait_type);
            values.push(attr.value);
        }
        let value = poseidon_hash_many(&values);

        Node {
            left_child: None,
            right_child: None,
            accessible_token_ids: vec![token_id].into_iter().collect(),
            value,
        }
    }
}

enum TreeBuilder {
    KeepGoing(Vec<Node>),
    Done(Node),
}

fn build_tree(leaves: Vec<Node>) -> Node {
    match build_tree_recursively(TreeBuilder::KeepGoing(leaves)) {
        TreeBuilder::Done(root) => root,
        _ => unreachable!("Failed building the tree"),
    }
}

fn build_tree_recursively(tree_builder: TreeBuilder) -> TreeBuilder {
    let mut nodes = match tree_builder {
        TreeBuilder::KeepGoing(nodes) => nodes,
        _ => unreachable!("Failed building the tree"),
    };

    let mut next_nodes: Vec<Node> = vec![];

    while !nodes.is_empty() {
        let a = nodes.pop().unwrap();
        let b = nodes.pop().unwrap();
        next_nodes.push(Node::new(a, b));
    }

    if next_nodes.len() == 1 {
        // return root
        let root = next_nodes.pop().unwrap();
        return TreeBuilder::Done(root);
    }

    if next_nodes.len() % 2 == 1 {
        // if odd - pair last element with itself
        next_nodes.push(next_nodes.last().unwrap().clone());
    }

    build_tree_recursively(TreeBuilder::KeepGoing(next_nodes))
}

pub fn felt_to_b16(felt: &FieldElement) -> String {
    format!("{:#x}", felt)
}

pub fn hash(a: &FieldElement, b: &FieldElement) -> FieldElement {
    if a < b {
        pedersen_hash(a, b)
    } else {
        pedersen_hash(b, a)
    }
}

fn string_to_hex(input: &str) -> String {
    format!("0x{}", hex::encode(input))
}

fn convert_to_felt(input: &str) -> FieldElement {
    FieldElement::from_str(&string_to_hex(input)).unwrap()
}

fn main() {
    // Example data

    let trait_type_str = "birthplace";
    let trait_type_hex = string_to_hex(trait_type_str);

    println!("Original String: {}", trait_type_str);
    println!("Hex Representation: {}", trait_type_hex);

    let attributes1 = vec![
        Attribute {
            trait_type: convert_to_felt("birthplace"),
            value: convert_to_felt("West Macedonia"),
        },
        Attribute {
            trait_type: convert_to_felt("ethnicity"),
            value: convert_to_felt("Macedonians"),
        },
        Attribute {
            trait_type: convert_to_felt("occupation"),
            value: convert_to_felt("General"),
        },
        Attribute {
            trait_type: convert_to_felt("special_trait"),
            value: convert_to_felt(""),
        },
    ];

    let attributes2 = vec![
        Attribute {
            trait_type: convert_to_felt("birthplace"),
            value: convert_to_felt("West Macedonia"),
        },
        Attribute {
            trait_type: convert_to_felt("ethnicity"),
            value: convert_to_felt("Macedonians"),
        },
        Attribute {
            trait_type: convert_to_felt("occupation"),
            value: convert_to_felt("General"),
        },
        Attribute {
            trait_type: convert_to_felt("special_trait"),
            value: convert_to_felt(""),
        },
    ];

    let attributes3 = vec![
        Attribute {
            trait_type: convert_to_felt("birthplace"),
            value: convert_to_felt("West Macedonia"),
        },
        Attribute {
            trait_type: convert_to_felt("ethnicity"),
            value: convert_to_felt("Macedonians"),
        },
        Attribute {
            trait_type: convert_to_felt("occupation"),
            value: convert_to_felt("General"),
        },
        Attribute {
            trait_type: convert_to_felt("special_trait"),
            value: convert_to_felt(""),
        },
    ];

    let tokens = vec![
        Token {
            token_id: FieldElement::from(1_u128),
            name: convert_to_felt("Theseusides"),
            attributes: attributes1.clone(),
        },
        Token {
            token_id: FieldElement::from(2_u128),
            name: convert_to_felt("Zenoenor"),
            attributes: attributes2.clone(),
        },
        Token {
            token_id: FieldElement::from(3_u128),
            name: convert_to_felt("Herodotusides"),
            attributes: attributes3.clone(),
        },
    ];

    //println!("Proof: {:?}", tokens);

    let tree = MerkleTree::new(tokens);

    //println!("Proof: {:?}", tree);
    println!("merkel root: {:?}", tree.root.value);

    match tree.token_calldata(1_u128) {
        Ok(calldata) => {
            println!("Proof: {:?}", calldata.proof);
        }
        Err(e) => println!("Error: {}", e),
    }
}
