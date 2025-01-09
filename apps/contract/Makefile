-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil zktest nuke

# Nuke command
nuke: clean remove install update build

# Clean the repo
clean:
	forge clean

# Remove modules
remove:
	rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

# Install
install:
	forge install cyfrin/foundry-devops@0.2.2 --no-commit
	forge install foundry-rs/forge-std@v1.8.2 --no-commit
	forge install openzeppelin/openzeppelin-contracts@v5.0.2 --no-commit

# Update Dependencies
update:
	forge update

build:
	forge build

test:
	forge test -vvvv

snapshot:
	forge snapshot

format:
	forge fmt

NETWORK_ARGS := --rpc-url $(BASE_RPC_URL) --private-key $(DEV_PRIVATE_KEY) --broadcast

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(BASE_SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(BASESCAN_API_KEY) -vvvv
endif

deploy:
	@forge script script/DeployPhotoFactory.s.sol:DeployPhotoFactory $(NETWORK_ARGS)

deploy-sepolia:
  @make deploy ARGS="--network sepolia"
