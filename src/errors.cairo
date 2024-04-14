pub mod Errors {
    const MAX_SUPPLY_REACHED: felt252 = 'Maximum NFT supply reached';
    const INVALID_RECIPIENT: felt252 = 'ERC721: invalid recipient';
    const PUBLIC_SALE_NOT_STARTED: felt252 = 'Public sale has not started';
    const FREE_MINT_NOT_STARTED: felt252 = 'Free mint has not started';

    const WHITELIST_MINT: felt252 = 'Whitelised mint only';
    const WHITELIST_LIMIT: felt252 = 'Whitelist limit ';
    const MAX_NFT_PER_ADDRESS: felt252 = 'Maximum NFT per address reached';
    const CALLER_NOT_OWNER: felt252 = 'Reveal: not token owner';
    const TOKEN_ALREADY_REVALED: felt252 = 'Token already revealed';
    const INVALID_TOKEN_ID: felt252 = 'ERC721: invalid token ID';
    const NOT_AUTHORIZED: felt252 = 'Caller is not authorized';
    const ALREADY_WHITELISTED: felt252 = 'Address already whitelisted';
}

