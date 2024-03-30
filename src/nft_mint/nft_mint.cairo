#[starknet::contract]
mod NFTMint {
    use core::zeroable::Zeroable;
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address};
    use openzeppelin::token::erc721::ERC721Component;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use terracon_prestige_card::nft_mint::{INFTMint};
    use terracon_prestige_card::errors::{
        MAX_SUPPLY_REACHED, INVALID_RECIPIENT, PUBLIC_SALE_NOT_STARTED, WHITELIST_MINT, MAX_NFT_PER_ADDRESS
    };
    use terracon_prestige_card::nft_mint::interface::{MAX_TOKENS_PER_ADDRESS, MINTING_FEE, MAX_SUPPLY, OWNER_FREE_MINT_AMOUNT, WHITELIST_FREE_MINT_END};

    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl ERC721MetadataImpl = ERC721Component::ERC721MetadataImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl InternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        public_sale_open: bool,
        whitelist_merkle_root: felt252,
        next_token_id: u256,
        whitelisted_address: LegacyMap::<ContractAddress, bool>,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        PublicSaleOpen: PublicSaleOpen,
        PublicSaleClose: PublicSaleClose,
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event
    }
    
    #[derive(Drop, starknet::Event)]
    struct PublicSaleOpen {
        time: u64
    }

    #[derive(Drop, starknet::Event)]
    struct PublicSaleClose {
        time: u64
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        let name = 'Terracon Hex Prestige Card';
        let symbol = 'HEX';

        self.erc721.initializer(name, symbol);
        /// @dev Set the initial owner of the contract
        self.ownable.initializer(owner);

        /// @dev Mint the initial tokens for the contract owner
        let mut token_id = 1;
        while token_id <= OWNER_FREE_MINT_AMOUNT {
            let token_uri: felt252 = 'https://bit.ly/497SFF6';
            self.erc721._mint(owner, token_id);
            self.erc721._set_token_uri(token_id, token_uri);
            token_id += 1;
        };
        self.next_token_id.write(token_id);
    }

    #[abi(embed_v0)]
    impl NFTMint of INFTMint<ContractState> {
        fn mint(ref self: ContractState, recipient: ContractAddress, quantity: u256) {
            assert(!recipient.is_zero(), INVALID_RECIPIENT);
            let next_token_id = self.next_token_id.read();
            assert(next_token_id + quantity <= MAX_SUPPLY, MAX_SUPPLY_REACHED);
            assert(self.erc721.balance_of(recipient) + quantity <= MAX_TOKENS_PER_ADDRESS, MAX_NFT_PER_ADDRESS);

            let owner: ContractAddress = self.ownable.owner();

            let whitelisted = self._is_whitelisted(recipient);

            let mut token_id = next_token_id;
            let mut minted_quantity = 0;

            while minted_quantity < quantity {
                if token_id <= WHITELIST_FREE_MINT_END {
                    // TODO: Check if the recipient is in the whitelist using the Merkle proof
                    /// @dev Check if the recipient is whitelisted
                    assert(whitelisted, WHITELIST_MINT);
                    let token_uri: felt252 = 'https://bit.ly/497SFF6';
                    self.erc721._mint(recipient, token_id);
                    self.erc721._set_token_uri(token_id, token_uri);
                } else {
                    /// @dev Check if the public sale is open
                    assert(self.public_sale_open.read() == true, PUBLIC_SALE_NOT_STARTED);
                    let eth_dispatcher = IERC20Dispatcher {
                        contract_address: 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7 // ETH Contract Address
                            .try_into()
                            .unwrap()
                    };
                    
                    eth_dispatcher.transfer_from(get_caller_address(), owner, MINTING_FEE);
                    // Check if the correct minting fee is paid
                    // assert(/* Payment check */, INSUFFICIENT_PAYMENT);
                    let token_uri: felt252 = 'https://bit.ly/497SFF6';
                    self.erc721._mint(recipient, token_id);
                    self.erc721._set_token_uri(token_id, token_uri);
                }
                token_id += 1;
                minted_quantity += 1;
            };

            self.next_token_id.write(token_id);
        }

        fn set_public_sale_open(ref self: ContractState, public_sale_open: bool) {
            self.ownable.assert_only_owner();
            self.public_sale_open.write(public_sale_open);

            let current_time = get_block_timestamp();
            if public_sale_open {
                self.emit(Event::PublicSaleOpen(PublicSaleOpen { time: current_time }));
            } else {
                self.emit(Event::PublicSaleClose(PublicSaleClose { time: current_time }));
            };
        }

        fn whitelist_addresses(
            ref self: ContractState,
            address_list: Array<ContractAddress>
        ) {
            self.ownable.assert_only_owner();
            self._whitelist_array(address_list);
        }
    }

    /// @dev Internal Functions implementation for the NFT Mint contract
    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        /// @dev Registers the address and initializes their whitelist status to true (can mint)
        fn _whitelist_array(ref self: ContractState, address_list: Array<ContractAddress>) {
            let mut i = 0;
            while i < address_list.len() {
                self.whitelisted_address.write(*address_list[i], true);
                i += 1;
            };
        }

        /// @dev Check whether an address is whitelisted
        fn _is_whitelisted(self: @ContractState, address: ContractAddress) -> bool {
            self.whitelisted_address.read(address)
        }
    }
}
