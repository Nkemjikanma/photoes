// SPDX-License-Indentifier: MIT
pragma solidity ^0.8.27;

import {PurchaseHandler} from "./PurchaseHandler.sol";
import {IPhotoFactoryEngine} from "../interfaces/IPhotoFactoryEngine.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

library AiVariantHandler {
    struct aiGenerationState {
        mapping(uint256 => IPhotoFactoryEngine.AiGeneratedVariant) aiVariant;
    }

    event AIGenerationRequested(uint256 indexed tokenId, bytes32 requestId);
    event AIGenerationCompleted(uint256 indexed tokenId, uint256 indexed aiVariantId, string aiURI);
    event AIGenerationFailed(uint256 indexed tokenId, bytes error);
    event AIVariantMinted(uint256 indexed originalTokenId, uint256 indexed aiTokenId);

    /**
     * @notice Sends an HTTP request for ai generated SVG variant
     * @param _tokenId The ID for the photoItem
     * @param _tokenURI the URI of the token
     * @return requestId The ID of the request
     */
    function generateAiVariant(uint256 _tokenId, string memory _tokenURI)
        external
        existingPhoto(_tokenId)
        onlyPhotoOwner(_tokenId)
        copiesOwnedToAiCheck(msg.sender, _tokenId)
        returns (bytes32 requestId)
    {
        // Check if AI generation is already in progress
        if (aiGenerationInProgress[_tokenId]) {
            revert PhotoFactoryEngine__AIGenerationInProgress();
        }

        // Mark AI generation as in progress
        aiGenerationInProgress[_tokenId] = true;

        // send request to chainlink oracle node
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source); // Initialize the request with JS code
        // Set the token URI as an argument
        string[] memory args = new string[](1);
        args[0] = _tokenURI;

        if (args.length > 0) req.setArgs(args); // Set the arguments for the request

        // Send the request and store the request ID
        s_lastRequestId = _sendRequest(req.encodeCBOR(), subscriptionId, gasLimit, donId);

        // Store the request ID to token ID mapping
        requestIdToTokenId[s_lastRequestId] = _tokenId;

        emit AIGenerationRequested(_tokenId, s_lastRequestId);

        return s_lastRequestId;
    }

    function mintAiVariant(uint256 _tokenId, uint256 _aiVariantId, address _sender)
        internal
        // existingPhoto(_tokenId)
        // onlyPhotoOwner(_tokenId)
        nonReentrant
    {
        // ensure AI generation is complete
        AiGeneratedVariant memory aiVariant = aiGeneratedVariant[_aiVariantId]; // get the AI variant

        if (
            aiGenerationInProgress[_tokenId] || aiVariant.minted || aiVariant.generationDate == 0
                || keccak256(abi.encodePacked(aiVariant.aiURI)) == keccak256(abi.encodePacked(""))
        ) {
            revert PhotoFactoryEngine__TokenAIError();
        }

        /*
     * TODO:
     * Receive svg in base 64,
     * confirm it is in base 64 format
     */

        // Generate the token URI for the AI variant
        string memory aiTokenURI = tokenURI(_aiVariantId, aiVariant);

        // Mint the AI variant as an ERC721
        try factory721.mintERC721(aiTokenURI, aiVariant.variantId) {
            // Update mappings and state

            (bool isSingleEdition, bool isMultipleEdition) =
                PurchaseHandler.decidePhotoEdition(s_purchaseState, _tokenId);

            if (isSingleEdition) {
                s_purchaseState.photoItem[_tokenId].aiVariantTokenId = aiVariant.variantId;
            }

            if (isMultipleEdition) {
                s_purchaseState.multiplePhotoItems[_tokenId].aiVariantTokenIds.push(aiVariant.variantId);
            }

            aiVariant.aiURI = aiTokenURI;
            aiVariant.minted = true;
            aiVariant.description = aiVariant.description;
            emit AIVariantMinted(_tokenId, aiVariant.variantId);
        } catch {
            revert PhotoFactoryEngine__MintFailed();
        }

        // update mappings
        tokenIdToAiVariants[_tokenId].push(aiVariant.variantId);
    }

    function tokenURI(uint256 _aiVariantTokenId, AiGeneratedVariant memory aiVariant)
        public
        view
        returns (string memory)
    {
        // AiGeneratedVariant memory aiVariant = aiGeneratedVariant[_aiVariantTokenId];

        string memory imageURI = aiVariant.aiURI;
        string memory name;

        // sample description -  "description": "An NFT that reflects owners mood.", "attribures": [{"trait_type": "moodiness", "value":100}]
        string memory description = aiVariant.description;

        if (s_purchaseState.photoItem[aiVariant.originalImage].minted) {
            name = s_purchaseState.photoItem[aiVariant.originalImage].photoName;
        } else if (s_purchaseState.multiplePhotoItems[aiVariant.originalImage].minted) {
            name = s_purchaseState.multiplePhotoItems[aiVariant.originalImage].photoName;
        } else {
            revert PhotoFactoryEngine__InvalidPhotoTokenId();
        }
        if (keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked(""))) {
            revert PhotoFactoryEngine_InvalidAiVariantTokenId();
        }

        string memory tokenMetadata = string(
            abi.encodePacked(
                _baseURI(),
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name": "', name, '", "description": "', description, '", "image": "', imageURI, '"  }'
                        )
                    )
                )
            )
        );

        return tokenMetadata;
    }
}
