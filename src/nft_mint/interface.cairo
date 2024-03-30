use starknet::ContractAddress;

const MAX_TOKENS_PER_ADDRESS: u256 = 2;
const MINTING_FEE: u256 = 33000000000000000; // 0.033 ether
const MAX_SUPPLY: u256 = 1337;
const OWNER_FREE_MINT_AMOUNT: u256 = 337;
const WHITELIST_FREE_MINT_END: u256 = OWNER_FREE_MINT_AMOUNT + 100; // 437

#[starknet::interface]
pub trait INFTMint<TContractState> {
    fn mint(ref self: TContractState, recipient: ContractAddress, quantity: u256);
    fn set_public_sale_open(ref self: TContractState, public_sale_open: bool);
    // fn set_whitelist_merkle_root(ref self: TContractState, whitelist_merkle_root: felt252);
    fn whitelist_addresses(ref self: TContractState, address_list: Array<ContractAddress>);
    // fn is_public_sale_open(self: @TContractState) -> bool;
    // fn get_whitelist_merkle_root(self: @TContractState) -> felt252;
    // fn get_whitelist_allocation(
    //     self: @TContractState, account: ContractAddress, allocation: felt252, proof: Span<felt252>
    // ) -> felt252;
}