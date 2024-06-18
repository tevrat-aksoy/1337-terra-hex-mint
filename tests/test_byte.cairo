use core::hash::HashStateExTrait;
use core::{ArrayTrait, SpanTrait};
use core::debug::PrintTrait;
use terracon_prestige_card::nft_mint::interface::{
    INFTMint, INFTMintDispatcher, INFTMintDispatcherTrait
};
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use openzeppelin::token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};

use starknet::{ContractAddress, deploy_syscall};
use starknet::contract_address_const;
use starknet::contract_address_try_from_felt252;
use starknet::contract_address_to_felt252;
use openzeppelin::token::erc721::interface::{
    ERC721ABI, ERC721ABIDispatcher, ERC721ABIDispatcherTrait
};
use snforge_std::{ContractClassTrait, declare, cheat_caller_address, CheatSpan};
use terracon_prestige_card::types::{TokenMetadata, Attribute};

use core::bytes_31::bytes31_to_felt252;
use core::bytes_31::bytes31_try_from_felt252;


#[test]
fn test_reveal() {
    let token_id1: u256 = 1;
    let name1: felt252 = 'Theseusides';
    let mut attributes1 = ArrayTrait::<Attribute>::new();
    attributes1.append(Attribute { trait_type: 'birthplace', value: 'West Macedonia' });
    attributes1.append(Attribute { trait_type: 'ethnicity', value: 'Macedonians' });
    attributes1.append(Attribute { trait_type: 'occupation', value: 'General' });
    attributes1.append(Attribute { trait_type: 'special_trait', value: 'None' });

    format!("Theseusides").pending_word.print();
    format!("Theseusides").pending_word_len.print();
    //bytes31_to_felt252(* format!("Theseusides").data.at(0)).print();
    format!("{}", name1).pending_word.print();

    let text: bytes31 = bytes31_try_from_felt252(name1).unwrap();

    format!("{}", text).pending_word.print();
}

