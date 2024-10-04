// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title A supply chain quality control smart contract
/// @notice This contract manages product registration, quality checks, and role-based access control for a supply chain
/// @dev Inherits OpenZeppelin's AccessControl for role management
contract SupplyChainManager is AccessControl {
    bytes32 public constant ROLE_MANUFACTURER = keccak256("ROLE_MANUFACTURER");
    bytes32 public constant ROLE_DISTRIBUTOR = keccak256("ROLE_DISTRIBUTOR");
    bytes32 public constant ROLE_RETAILER = keccak256("ROLE_RETAILER");

    uint256 private productCounter;

    struct Product {
        uint256 id;
        string name;
        address manufacturer;
        uint256 manufactureDate;
        string origin;
        bool isCompleted;
        string batchId;
        uint256 expiryDate;
    }

    struct QualityCheck {
        address inspector;
        uint256 timestamp;
        string checkpoint;
        bool passed;
        string remarks;
    }

    mapping(uint256 => Product) private products;
    mapping(uint256 => QualityCheck[]) private productQualityChecks;

    event ProductRegistered(uint256 indexed productId, string name, address indexed manufacturer);
    event QualityCheckAdded(uint256 indexed productId, string checkpoint, bool passed);
    event ProductCompleted(uint256 indexed productId);
    event ProductUpdated(uint256 indexed productId);

    /// @notice Initializes the contract and grants the deployer the admin role
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Registers a new product in the supply chain
    /// @dev Only callable by addresses with the ROLE_MANUFACTURER
    /// @param productName The name of the product
    /// @param originLocation The origin location of the product
    /// @param batchId The batch identifier of the product
    /// @param expiryDate The expiration date of the product
    function registerProduct(
        string memory productName,
        string memory originLocation,
        string memory batchId,
        uint256 expiryDate
    ) external onlyRole(ROLE_MANUFACTURER) {
        productCounter++;
        uint256 newProductId = productCounter;

        products[newProductId] = Product({
            id: newProductId,
            name: productName,
            manufacturer: msg.sender,
            manufactureDate: block.timestamp,
            origin: originLocation,
            isCompleted: false,
            batchId: batchId,
            expiryDate: expiryDate
        });

        emit ProductRegistered(newProductId, productName, msg.sender);
    }

    /// @notice Adds a quality check to a product's history
    /// @dev Callable by addresses with the ROLE_MANUFACTURER, ROLE_DISTRIBUTOR, or ROLE_RETAILER
    /// @param productId The ID of the product
    /// @param checkpoint The name of the checkpoint
    /// @param passed Whether the product passed the quality check
    /// @param remarks Additional remarks on the quality check
    function addQualityCheck(
        uint256 productId,
        string memory checkpoint,
        bool passed,
        string memory remarks
    ) external {
        require(
            hasRole(ROLE_MANUFACTURER, msg.sender) ||
            hasRole(ROLE_DISTRIBUTOR, msg.sender) ||
            hasRole(ROLE_RETAILER, msg.sender),
            "Unauthorized caller"
        );
        require(!products[productId].isCompleted, "Product journey completed");

        productQualityChecks[productId].push(QualityCheck({
            inspector: msg.sender,
            timestamp: block.timestamp,
            checkpoint: checkpoint,
            passed: passed,
            remarks: remarks
        }));

        emit QualityCheckAdded(productId, checkpoint, passed);
    }

    /// @notice Marks the product as completed by a retailer
    /// @dev Only callable by addresses with the ROLE_RETAILER
    /// @param productId The ID of the product to complete
    function completeProductJourney(uint256 productId) external onlyRole(ROLE_RETAILER) {
        require(!products[productId].isCompleted, "Product journey already completed");

        products[productId].isCompleted = true;

        emit ProductCompleted(productId);
    }

    /// @notice Fetches product details
    /// @param productId The ID of the product
    /// @return The Product details
    function getProductDetails(uint256 productId) external view returns (Product memory) {
        return products[productId];
    }

    /// @notice Fetches all quality checks for a product
    /// @param productId The ID of the product
    /// @return An array of QualityCheck structs
    function getQualityChecks(uint256 productId) external view returns (QualityCheck[] memory) {
        return productQualityChecks[productId];
    }

    /// @notice Updates product information, only by the manufacturer
    /// @dev Only callable by the original manufacturer of the product
    /// @param productId The ID of the product
    /// @param newName The new name of the product
    /// @param newOrigin The new origin location of the product
    /// @param newBatchId The new batch identifier
    /// @param newExpiryDate The new expiration date
    function updateProductInfo(
        uint256 productId,
        string memory newName,
        string memory newOrigin,
        string memory newBatchId,
        uint256 newExpiryDate
    ) external onlyRole(ROLE_MANUFACTURER) {
        Product storage product = products[productId];
        require(product.manufacturer == msg.sender, "Only manufacturer can update");
        require(!product.isCompleted, "Cannot update completed product");

        product.name = newName;
        product.origin = newOrigin;
        product.batchId = newBatchId;
        product.expiryDate = newExpiryDate;

        emit ProductUpdated(productId);
    }

    // Role management functions remain unchanged from the original contract for efficiency
}