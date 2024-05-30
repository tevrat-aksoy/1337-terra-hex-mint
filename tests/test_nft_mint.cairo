use core::hash::HashStateExTrait;
use core::{ArrayTrait, SpanTrait};
use core::debug::PrintTrait;
use terracon_prestige_card::nft_mint::interface::{INFTMint, INFTMintDispatcher, INFTMintDispatcherTrait};
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use starknet::{ContractAddress, deploy_syscall};
use starknet::contract_address_const;
use starknet::contract_address_try_from_felt252;
use starknet::contract_address_to_felt252;
use openzeppelin::token::erc721::interface::{ERC721ABI,ERC721ABIDispatcher,ERC721ABIDispatcherTrait};
use snforge_std::{ContractClassTrait, declare,cheat_caller_address,CheatSpan};
use terracon_prestige_card::types::{TokenMetadata, Attribute};

const MAX_TOKENS_PER_ADDRESS: u256 = 2;
const MINTING_FEE: u256 = 33000000000000000; // 0.033 ether
const MAX_SUPPLY: u256 = 1337;
const OWNER_FREE_MINT_AMOUNT: u256 = 337;
const WHITELIST_FREE_MINT_END: u256 = 437; // 437

const ETH_ADDRESS :felt252=0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7; 

const MERKLE_ROOT :felt252=02520458602344550470566127240359230647107649166976245036606031434610757149662; 

#[test]
fn test_init() {
    let   (_OWNER, _ACCOUNT1,_ACCOUNT2,_ACCOUNT3) =deploy_accounts();
        
    let NFTMint = deploy(_OWNER);
    let NFTMintErc721=ERC721ABIDispatcher{contract_address:NFTMint.contract_address};

    assert(NFTMintErc721.name()== format!("Terracon Hex Prestige Card"),'Error:: name');
    assert(NFTMintErc721.symbol()== format!("HEX"),'Error:: symbol');

    assert(NFTMintErc721.balance_of(_OWNER)== OWNER_FREE_MINT_AMOUNT,'Error:: owner balance');
    assert(NFTMint.total_supply()== OWNER_FREE_MINT_AMOUNT+1,'Error:: total sup');

    assert(NFTMintErc721.owner_of(1)== _OWNER,'Error:: token1 owner');
    assert(NFTMintErc721.owner_of(OWNER_FREE_MINT_AMOUNT)== _OWNER,'Error:: token  owner');

    assert(NFTMint.mint_fee(ETH_ADDRESS.try_into().unwrap())== MINTING_FEE,'Error:: mint_fee');

    assert(NFTMint.token_of_owner_by_index_len(_OWNER)== OWNER_FREE_MINT_AMOUNT,'Error:: owner tokens len');
    
    assert(NFTMint.token_of_owner_by_index(_OWNER,0)== 1,'Error:: tokens index');
    assert(NFTMint.token_of_owner_by_index(_OWNER,OWNER_FREE_MINT_AMOUNT-1)== OWNER_FREE_MINT_AMOUNT,'Error:: tokens index');

}   


#[test]
fn test_reveal() {
    let   (_OWNER, _ACCOUNT1,_ACCOUNT2,_ACCOUNT3) =deploy_accounts();
    
    let _ETHContract= deploy_token(_OWNER,ETH_ADDRESS.try_into().unwrap());
    
    let NFTMint = deploy(_OWNER);

    cheat_caller_address(NFTMint.contract_address, _OWNER ,CheatSpan::TargetCalls(1));
    NFTMint.set_merkle_root(MERKLE_ROOT);

    assert(NFTMint.get_merkle_root()==MERKLE_ROOT,'Error:: saved root');

    let token_id1:u256 =1;
    let name1= 'Theseusides';
    let mut attributes1 = ArrayTrait::<Attribute>::new();
    attributes1.append(Attribute{trait_type:'birthplace', value:'West Macedonia'});
    attributes1.append(Attribute{trait_type:'ethnicity', value:'Macedonians'});
    attributes1.append(Attribute{trait_type:'occupation', value:'General'});
    attributes1.append(Attribute{trait_type:'special_trait', value:''});

    let proof1=array![01268881024977045149399239396011044699604381431234109625210257457886424650771] ;

    let root_= NFTMint.get_root_for(name1, token_id1.low, attributes1.span(),proof1.span());
    root_.print();
    NFTMint.get_merkle_root().print();
    assert(NFTMint.get_root_for(name1, token_id1.low, attributes1.span(),proof1.span())==MERKLE_ROOT,'Error:: token1 data');

    //cheat_caller_address(NFTMint.contract_address, _OWNER ,CheatSpan::TargetCalls(1));
    //NFTMint.reveal(1,token_id1,name1);
}   


//

fn deploy_accounts() -> (ContractAddress, ContractAddress,ContractAddress,ContractAddress) {
    let _OWNER: ContractAddress = contract_address_const::<'factory_owner'>();
    let _ACCOUNT1: ContractAddress = contract_address_const::<'account1'>();
    let _ACCOUNT2: ContractAddress = contract_address_const::<'account2'>();
    let _ACCOUNT3: ContractAddress = contract_address_const::<'account3'>();
    (_OWNER, _ACCOUNT1,_ACCOUNT2,_ACCOUNT3)
}


fn deploy(admin:ContractAddress) -> INFTMintDispatcher {
    let mut calldata = ArrayTrait::new();
    calldata.append(contract_address_to_felt252(admin));
    let contract =declare("NFTMint").unwrap();
    let (contract_address, _) =  contract.deploy(@calldata).unwrap();
    INFTMintDispatcher { contract_address: contract_address }
}

fn deploy_token(recipient: ContractAddress, contractAdd:ContractAddress) -> IERC20Dispatcher {
    let mut calldata = ArrayTrait::new();

    calldata.append(1000000000000000000);
    calldata.append(0);
    calldata.append(recipient.into());

    let contract = declare("ERC20Mock").unwrap();

    let (contract_address, _) =  contract.deploy_at(@calldata,contractAdd).unwrap();

    IERC20Dispatcher { contract_address: contract_address }
}




