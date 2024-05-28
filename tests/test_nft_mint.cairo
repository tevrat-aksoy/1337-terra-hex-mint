use core::hash::HashStateExTrait;
use core::{ArrayTrait, SpanTrait};
use core::debug::PrintTrait;
use terracon_prestige_card::nft_mint::interface::{INFTMint, INFTMintDispatcher, INFTMintDispatcherTrait};
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{ContractClassTrait, declare, start_prank, CheatTarget};
use starknet::{ContractAddress, deploy_syscall};
use starknet::contract_address_const;
use starknet::contract_address_try_from_felt252;
use starknet::contract_address_to_felt252;
use openzeppelin::token::erc721::interface::{ERC721ABI,ERC721ABIDispatcher,ERC721ABIDispatcherTrait};


#[test]
fn test_init() {
    let   (_OWNER, _ACCOUNT1,_ACCOUNT2,_ACCOUNT3) =deploy_accounts();
    deploy_token(_OWNER);
    'adret'.print();
    let NFTMint = deploy(_OWNER);
    let NFTMintErc721=ERC721ABIDispatcher{contract_address:NFTMint.contract_address};

    assert(NFTMintErc721.name()== format!("Terracon Hex Prestige Card"),'Error:: name');
    assert(NFTMintErc721.symbol()== format!("Terracon Hex Prestige Card"),'Error:: symbol');
}   


//

fn deploy_accounts() -> (ContractAddress, ContractAddress,ContractAddress,ContractAddress) {
    let _OWNER: ContractAddress = contract_address_const::<'factory_owner'>();
    let _ACCOUNT1: ContractAddress = contract_address_const::<'account1'>();
    let _ACCOUNT2: ContractAddress = contract_address_const::<'account1'>();
    let _ACCOUNT3: ContractAddress = contract_address_const::<'account1'>();
    (_OWNER, _ACCOUNT1,_ACCOUNT2,_ACCOUNT3)
}


fn deploy(admin:ContractAddress) -> INFTMintDispatcher {
    let mut calldata = ArrayTrait::new();
    calldata.append(admin.into());
    'asd'.print();
    let contract =declare(format!("NFTMint"));
    let address = contract.deploy(@calldata).expect('unable to deploy distributor');
    'asd2'.print();

    INFTMintDispatcher { contract_address: address }
}

fn deploy_token(recipient: ContractAddress,) -> IERC20Dispatcher {
    let mut calldata = ArrayTrait::new();

    calldata.append(1000000000000000000);
    calldata.append(0);
    calldata.append(recipient.into());
    let contract = declare(format!("ERC20Mock"));

    let address = contract
        .deploy(@calldata)
        .expect('unable to deploy mockstrk');

    IERC20Dispatcher { contract_address: address }
}




