use core::hash::HashStateExTrait;
use core::{ArrayTrait, SpanTrait};
use core::debug::PrintTrait;
use terracon_prestige_card::nft_mint::interface::{
    INFTMint, INFTMintDispatcher, INFTMintDispatcherTrait
};
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use starknet::{ContractAddress, deploy_syscall};
use starknet::contract_address_const;
use starknet::contract_address_try_from_felt252;
use starknet::contract_address_to_felt252;
use openzeppelin::token::erc721::interface::{
    ERC721ABI, ERC721ABIDispatcher, ERC721ABIDispatcherTrait
};
use snforge_std::{ContractClassTrait, declare, cheat_caller_address, CheatSpan};
use terracon_prestige_card::types::{TokenMetadata, Attribute};

const MAX_TOKENS_PER_ADDRESS: u256 = 2;
const MINTING_FEE: u256 = 33000000000000000; // 0.033 ether
const MAX_SUPPLY: u256 = 1337;
const OWNER_FREE_MINT_AMOUNT: u256 = 337;
const WHITELIST_FREE_MINT_END: u256 = 437; // 437

const ETH_ADDRESS: felt252 = 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7;

const MERKLE_ROOT: felt252 = 0x6e1ca6734406be8b8390672e63de35b020172fb415d4f5e6ed604c628c3802b;

#[test]
fn test_init() {
    let (_OWNER, _ACCOUNT1, _ACCOUNT2, _ACCOUNT3) = deploy_accounts();

    let NFTMint = deploy(_OWNER);
    let NFTMintErc721 = ERC721ABIDispatcher { contract_address: NFTMint.contract_address };

    assert(NFTMintErc721.name() == format!("Terracon Hex Prestige Card"), 'Error:: name');
    assert(NFTMintErc721.symbol() == format!("HEX"), 'Error:: symbol');

    assert(NFTMintErc721.balance_of(_OWNER) == OWNER_FREE_MINT_AMOUNT, 'Error:: owner balance');
    assert(NFTMint.total_supply() == OWNER_FREE_MINT_AMOUNT + 1, 'Error:: total sup');

    assert(NFTMintErc721.owner_of(1) == _OWNER, 'Error:: token1 owner');
    assert(NFTMintErc721.owner_of(OWNER_FREE_MINT_AMOUNT) == _OWNER, 'Error:: token  owner');

    assert(NFTMint.mint_fee(ETH_ADDRESS.try_into().unwrap()) == MINTING_FEE, 'Error:: mint_fee');

    assert(
        NFTMint.token_of_owner_by_index_len(_OWNER) == OWNER_FREE_MINT_AMOUNT,
        'Error:: owner tokens len'
    );

    assert(NFTMint.token_of_owner_by_index(_OWNER, 0) == 1, 'Error:: tokens index');
    assert(
        NFTMint
            .token_of_owner_by_index(_OWNER, OWNER_FREE_MINT_AMOUNT - 1) == OWNER_FREE_MINT_AMOUNT,
        'Error:: tokens index'
    );
}


#[test]
fn test_reveal() {
    let (_OWNER, _ACCOUNT1, _ACCOUNT2, _ACCOUNT3) = deploy_accounts();

    let _ETHContract = deploy_token(_OWNER, ETH_ADDRESS.try_into().unwrap());

    let NFTMint = deploy(_OWNER);

    cheat_caller_address(NFTMint.contract_address, _OWNER, CheatSpan::TargetCalls(1));
    NFTMint.set_merkle_root(MERKLE_ROOT);

    assert(NFTMint.get_merkle_root() == MERKLE_ROOT, 'Error:: saved root');

    let token_id1: u256 = 1;
    let name1 = 'Theseusides';
    let mut attributes1 = ArrayTrait::<Attribute>::new();
    attributes1.append(Attribute { trait_type: 'birthplace', value: 'West Macedonia' });
    attributes1.append(Attribute { trait_type: 'ethnicity', value: 'Macedonians' });
    attributes1.append(Attribute { trait_type: 'occupation', value: 'General' });
    attributes1.append(Attribute { trait_type: 'special_trait', value: 'None' });

    let proof1 = array![
        0x4b3133c06a5497f1f54e77a87dec7c8e26720a15fd889d99f97f880898b8208,
        0x7cb9f7e626f51df2323aa4f7b04fad91b148c0c79029faca0898edd9c449ef,
        0x456ce991eab61b455527dc34cc71c39458b0000cf75065344e15747e4a147c8,
        0x2b59f1b6509226b9d8ad9b694693948cddcc73741293d0a302738a707b5acd0,
        0x8c716ef984c8f0d28eaeb3953cbe744fd801666fc72b6ba76ab73783ffe7e7,
        0x1ea5f6c1e9b55ab8c90c0ec054bd26e73cd2315c321cf8ebc6dcfe6825996a3,
        0x3269866fed3f1037dd0842c0377789813059a5f161408cf69540a545b5b98f7,
        0x670931d08fd6143ff56c710e7133b3772beac178ce5e94f4c2fc46752212690,
        0x418ef66924acf7ee380515d2d9403cc6305eb8591b2f13eb089b78535e86719,
        0x7e006e3e813a9c414b5319e8000bb9ff236cc0f3d9df5bf93e3bd3bcf5590c8,
        0x56cfa47a8c941147f8d668abc703883d9bce3d629b5a25641578f06ba633948
    ];

    let root_ = NFTMint.get_root_for(name1, token_id1.low, attributes1.span(), proof1.span());
    root_.print();
    NFTMint.get_merkle_root().print();
    assert(
        NFTMint
            .get_root_for(name1, token_id1.low, attributes1.span(), proof1.span()) == MERKLE_ROOT,
        'Error:: token1 data'
    );
//cheat_caller_address(NFTMint.contract_address, _OWNER ,CheatSpan::TargetCalls(1));
//NFTMint.reveal(1,token_id1,name1);
}


//

fn deploy_accounts() -> (ContractAddress, ContractAddress, ContractAddress, ContractAddress) {
    let _OWNER: ContractAddress = contract_address_const::<'factory_owner'>();
    let _ACCOUNT1: ContractAddress = contract_address_const::<'account1'>();
    let _ACCOUNT2: ContractAddress = contract_address_const::<'account2'>();
    let _ACCOUNT3: ContractAddress = contract_address_const::<'account3'>();
    (_OWNER, _ACCOUNT1, _ACCOUNT2, _ACCOUNT3)
}


fn deploy(admin: ContractAddress) -> INFTMintDispatcher {
    let mut calldata = ArrayTrait::new();
    calldata.append(contract_address_to_felt252(admin));
    let contract = declare("NFTMint").unwrap();
    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    INFTMintDispatcher { contract_address: contract_address }
}

fn deploy_token(recipient: ContractAddress, contractAdd: ContractAddress) -> IERC20Dispatcher {
    let mut calldata = ArrayTrait::new();

    calldata.append(1000000000000000000);
    calldata.append(0);
    calldata.append(recipient.into());

    let contract = declare("ERC20Mock").unwrap();

    let (contract_address, _) = contract.deploy_at(@calldata, contractAdd).unwrap();

    IERC20Dispatcher { contract_address: contract_address }
}

