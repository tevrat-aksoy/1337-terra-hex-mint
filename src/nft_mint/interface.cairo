use starknet::ContractAddress;
use terracon_prestige_card::types::{TokenMetadata, Attribute};

const MAX_TOKENS_PER_ADDRESS: u256 = 2;
const MINTING_FEE: u256 = 33000000000000000; // 0.033 ether
const MAX_SUPPLY: u256 = 1337;
const OWNER_FREE_MINT_AMOUNT: u256 = 337;
const WHITELIST_FREE_MINT_END: u256 = 437; // 437

#[starknet::interface]
pub trait INFTMint<TContractState> {
    fn total_supply(self: @TContractState,) -> u256;
    fn token_of_owner_by_index(self: @TContractState, user: ContractAddress, index: u256) -> u256;
    fn token_of_owner_by_index_len(self: @TContractState, user: ContractAddress) -> u256;
    fn get_token_metadata(self: @TContractState, token_id: u256,) -> TokenMetadata;
    fn get_token_attribute(self: @TContractState, token_id: u256, index: u32) -> Attribute;
    fn get_token_attribute_len(self: @TContractState, token_id: u256) -> u32;
    fn get_token_attributes(self: @TContractState, token_id: u256) -> Array<Attribute>;
    fn is_revealed(self: @TContractState, token_id: u256,) -> bool;
    fn add_authorized_address(ref self: TContractState, address: ContractAddress);
    fn remove_authorized_address(ref self: TContractState, address: ContractAddress);
    fn is_authorized(self: @TContractState, address: ContractAddress) -> bool;
    fn public_sale_open(self: @TContractState,) -> bool;
    fn free_mint_open(self: @TContractState,) -> bool;
    fn is_whitelisted(self: @TContractState, user: ContractAddress) -> bool;
    fn all_whitelist_addresses(self: @TContractState,) -> Array<ContractAddress>;
    fn mint_fee(self: @TContractState, token: ContractAddress) -> u256;

    fn get_root_for(
        self: @TContractState,
        name: felt252,
        tokenId: u128,
        attributes: Span::<Attribute>,
        proof: Span::<felt252>
    ) -> felt252;
    fn get_merkle_root(ref self: TContractState,) -> felt252;

    fn set_payment_tokens(ref self: TContractState, token: ContractAddress, amount: u256);
    fn update_token_attributes(
        ref self: TContractState, token_id: u256, new_attributes: Span::<Attribute>
    );

    fn reveal_token(
        ref self: TContractState,
        token_id: u256,
        name: felt252,
        attributes: Span::<Attribute>,
        proofs: Span::<felt252>
    );

    fn mint(
        ref self: TContractState,
        recipient: ContractAddress,
        quantity: u256,
        fee_token: ContractAddress
    );
    fn set_public_sale_open(ref self: TContractState, public_sale_open: bool);
    fn set_free_mint(ref self: TContractState, mint_open: bool);
    fn set_merkle_root(ref self: TContractState, root: felt252);

    fn add_whitelist_addresses(ref self: TContractState, address_list: Array<ContractAddress>);
    fn remove_whitelist_addresses(ref self: TContractState, address_list: Array<ContractAddress>);
// fn set_whitelist_merkle_root(ref self: TContractState, whitelist_merkle_root: felt252);
// fn get_whitelist_merkle_root(self: @TContractState) -> felt252;
// fn get_whitelist_allocation(
//     self: @TContractState, account: ContractAddress, allocation: felt252, proof: Span<felt252>
// ) -> felt252;
}
