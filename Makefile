-include .env

.PHONY: Help 


DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast
NETWORK_ARGS_ACCOUNT_POLYGON := --rpc-url $(ALCHEMY_URL_POLYGON) --account $(LOCAL_WALLET) --broadcast
NETWORK_ARGS_ACCOUNT_AMOY := --rpc-url $(ALCHEMY_URL_AMOY) --account $(LOCAL_WALLET) --broadcast
NETWORK_ARGS_ACCOUNT_AMOY_FORK := --fork-url $(ALCHEMY_URL_AMOY) --account $(LOCAL_WALLET) --broadcast
NETWORK_ARGS_DEPLOYER := --rpc-url $(ALCHEMY_URL_POLYGON) --private-key $(DEPLOYER_PRIVATE_KEY) --broadcast

FORGE_STD := forge install foundry-rs/forge-std --no-commit 
OPENZEPPELIN= forge install OpenZeppelin/openzeppelin-foundry-upgrades --no-commit && forge install OpenZeppelin/openzeppelin-contracts-upgradeable --no-commit

Help:
	@echo "Please use 'make <target>' where <target> is one of"
	@echo "  install                    to install the project"
	@echo "  compile                    to compile the contracts"
	@echo "  test                       to run the tests"
	@echo "  test-coverage              to run the tests with coverage"
	@echo "  deploy-anvil               to deploy the contract to Anvil"
	@echo "  deploy-amoy-account        to deploy the contract to Amoy using account"
	@echo "  deploy-amoy-account-verify to deploy and verify the contract to Amoy using account"
	@echo "  deploy-polygon-verify      to deploy and verify the contract to Polygon"
	@echo "  deploy-account-polygon     to deploy the contract to Polygon using account"
	@echo "  deploy-polygon-account-verify to deploy and verify the contract to Polygon using account"
	@echo "  dev                        to start the frontend"
	@echo "  anvil                      to start the local blockchain"
	@echo "  doc                        to serve and open the documentation"

install:
	@cd contracts && rm -fr lib && mkdir lib &&  $(FORGE_STD) && $(OPENZEPPELIN) && cd ../frontend && yarn

compile:
	@cd contracts && forge clean && forge build

test:
	@cd contracts && forge test

test-coverage:
	@cd contracts && forge coverage

deploy-anvil:
	@cd contracts && forge clean && forge build && forge script script/DeployCreditScore.s.sol:DeployCreditScore $(NETWORK_ARGS)

deploy-amoy-account:
	@cd contracts && forge script script/DeployCreditScore.s.sol:DeployCreditScore $(NETWORK_ARGS_ACCOUNT_AMOY)

deploy-amoy-account-verify:
	@cd contracts && forge script script/DeployCreditScore.s.sol:DeployCreditScore $(NETWORK_ARGS_ACCOUNT_AMOY) --verify

deploy-polygon-verify:
	@cd contracts && forge script script/DeployCreditScore.s.sol:DeployCreditScore $(NETWORK_ARGS_DEPLOYER) --verify

deploy-account-polygon:
	@cd contracts && forge script script/DeployCreditScore.s.sol:DeployCreditScore $(NETWORK_ARGS_ACCOUNT_POLYGON)

deploy-polygon-account-verify:
	@cd contracts && forge script script/DeployCreditScore.s.sol:DeployCreditScore $(NETWORK_ARGS_ACCOUNT_POLYGON) --verify

dev: 
	@cd frontend && yarn dev

anvil:
	@anvil

doc:
	@cd contracts && forge doc -s --open

