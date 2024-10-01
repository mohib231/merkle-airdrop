.PHONY: all deploy readjson readaddress setaddress readClaimerAddress getBytes getSignature
-include .env

# Define the contract deployment command
DEPLOY_CMD = forge script script/DeployMerkleAirdrop.s.sol --rpc-url $(ANVIL_RPC_URL) --private-key $(CLAIMER_PRIVATE_KEY) --broadcast

# Define the JSON file paths
AIRDROP_CONTRACT_ADDRESS_FILE = broadcast/DeployMerkleAirdrop.s.sol/31337/run-latest.json
CLAIMER_ADDRESS_FILE = script/target/input.json

# Target to deploy the contract
deploy:
	@echo "Deploying the Merkle Airdrop contract..."
	@$(DEPLOY_CMD)
	@echo "Deployment complete."

# Target to read the JSON and extract the contract address
readjson:
	@echo "Reading the Merkle Airdrop contract address..."
	@address=$$(jq -r '.transactions[1].contractAddress' $(AIRDROP_CONTRACT_ADDRESS_FILE)); \
	if [ -z "$$address" ]; then \
		echo "No address found!"; \
		exit 1; \
	else \
		echo "Merkle Airdrop Contract Address: $$address"; \
		echo "$$address" > deployed_address.txt; \
		echo "Address saved to deployed_address.txt"; \
	fi

# Target to read the address from the file
readaddress:
	@echo "Reading the deployed contract address from file..."
	@address=$$(cat deployed_address.txt); \
	if [ -z "$$address" ]; then \
		echo "No address found in deployed_address.txt!"; \
		exit 1; \
	else \
		echo "Deployed Contract Address: $$address"; \
	fi

# Target to read the claimer address and value from the JSON file
readClaimerAddress:
	@echo "Reading specific values from JSON..."
	@claimerAddress=$$(jq -r '.values["0"]["0"]' $(CLAIMER_ADDRESS_FILE)); \
	valueToBeClaimed=$$(jq -r '.values["0"]["1"]' $(CLAIMER_ADDRESS_FILE)); \
	if [ -z "$$claimerAddress" ] || [ -z "$$valueToBeClaimed" ]; then \
		echo "No values found!"; \
		exit 1; \
	else \
		echo "Claimer Address: $$claimerAddress"; \
		echo "Value to be claimed: $$valueToBeClaimed"; \
	fi

# Target to call getMessageHash function and store bytes in a file
getBytes:
	@echo "Getting bytes from contract..."
	@GET_BYTES=$$(cast call $$(cat deployed_address.txt) "getMessageHash(address,uint256)" $$(jq -r '.values["0"]["0"]' $(CLAIMER_ADDRESS_FILE)) $$(jq -r '.values["0"]["1"]' $(CLAIMER_ADDRESS_FILE)) --rpc-url $(ANVIL_RPC_URL)); \
	if [ -z "$$GET_BYTES" ]; then \
		echo "No bytes found!"; \
		exit 1; \
	else \
		echo "$$GET_BYTES" > bytes.txt; \
		echo "Bytes saved to bytes.txt"; \
	fi

# Target to sign the bytes using the private key
getSignature:
	@echo "Signing the bytes..."
	GET_SIGNATURE=$$(cast wallet sign $$(cat bytes.txt) --private-key $(CLAIMER_PRIVATE_KEY)); \
	if [ -z "$$GET_SIGNATURE" ]; then \
		echo "No signature found!"; \
		exit 1; \
	else \
		echo "$$GET_SIGNATURE" > script/signature.txt; \
		echo "Signature saved to script/signature.txt"; \
	fi

INTERACTION = forge script script/Interaction.s.sol --rpc-url $(ANVIL_RPC_URL) --private-key $(GAS_SPENDER_PRIVATE_KEY) --broadcast 
interactionWithSpender:
	@$(INTERACTION) 
	echo "Interaction complete"


# Combined target to deploy, read the address, and execute other tasks
all: deploy readjson readaddress readClaimerAddress getBytes getSignature interactionWithSpender
