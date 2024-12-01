-include .env

.PHONY: Help 


DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast
NETWORK_ARGS_ACCOUNT_POLYGON := --rpc-url $(ALCHEMY_URL_POLYGON) --account $(LOCAL_WALLET) --broadcast
NETWORK_ARGS_ACCOUNT_AMOY := --rpc-url $(ALCHEMY_URL_AMOY) --account $(LOCAL_WALLET) --broadcast
NETWORK_ARGS_ACCOUNT_AMOY_FORK := --fork-url $(ALCHEMY_URL_AMOY) --account $(LOCAL_WALLET) --broadcast
NETWORK_ARGS_DEPLOYER := --rpc-url $(ALCHEMY_URL_POLYGON) --private-key $(DEPLOYER_PRIVATE_KEY)
CONTRACT ?= default_contract_address

install:
	@cd contracts && forge build && cd ../frontend && yarn

compile:
	@cd contracts && forge build

test:
	@cd contracts && forge test

test-coverage:
	@cd contracts && forge coverage

deploy-anvil:
	@cd contracts && forge script script/DeployCreditScore.s.sol:DeployCreditScore $(NETWORK_ARGS)

deploy-amoy:
	@cd contracts && forge script script/DeployCreditScore.s.sol:DeployCreditScore $(NETWORK_ARGS_ACCOUNT_AMOY)

deploy-amoy-verify:
	@cd contracts && forge script script/DeployCreditScore.s.sol:DeployCreditScore $(NETWORK_ARGS_ACCOUNT_AMOY) --verify

deploy-polygon:
	@cd contracts && forge script script/DeployCreditScore.s.sol:DeployCreditScore $(NETWORK_ARGS_ACCOUNT_POLYGON)

deploy-polygon-verify:
	@cd contracts && forge script script/DeployCreditScore.s.sol:DeployCreditScore $(NETWORK_ARGS_ACCOUNT_POLYGON) --verify

dev: 
	@cd frontend && yarn dev

