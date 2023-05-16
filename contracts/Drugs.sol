//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "hardhat/console.sol";

contract Drugs {
    enum OrganisationRole {
        Manufacturer,
        Distributor,
        Retailer,
        Transporter
    }

    /**
     * Company structure
     */
    struct Company {
        string companyID;
        string name;
        string location;
        OrganisationRole organisationRole;
        uint8 hierarchyKey;
        address admin;
    }

    /**
     * Drug structure
     */
    struct Drug {
        string productId;
        string name;
        string manufacturer;
        string manufacturingDate;
        string expiryDate;
        string owner;
        string[] shipment;
        string[] history;
    }

    /**
     * Drug structure
     */
    struct PurchaseOrder {
        string poID;
        string drugName;
        uint256 quantity;
        string buyer;
        string seller;
    }

    // Shipment Data Model
    struct Shipment {
        string shipmentID;
        string creator;
        string[] assets;
        string transporter;
        string status;
    }

    mapping(string => Shipment) shipments;
    mapping(string => Company) companies; //mapping of companies in the blockchain
    mapping(string => Drug) drugs; //mapping of drugs in the blockchain
    mapping(string => PurchaseOrder) purchaseOrders; //mapping of purchase orders in the blockchain

    event Log(string message); //LOG event function

    /**
     * Modifier to check if company is already registered
     */
    modifier notAlreadyRegistered(string memory _company) {
        require(
            companies[_company].admin == address(0),
            "Company is already registered"
        );
        _;
    }

    /**
     * Modifier to check if company is already registered
     */
    modifier alreadyRegistered(string memory _company) {
        require(
            companies[_company].admin != address(0),
            "Company is not registered"
        );
        _;
    }

    /**
     * Modifier to check if company is a manufacturer
     */
    modifier onlyManufacturer(string memory _company) {
        require(
            companies[_company].organisationRole ==
                OrganisationRole.Manufacturer,
            "Company is not a Manufacturer"
        );
        _;
    }

    /**
     * Modifier to check if company is a retailer
     */
    modifier onlyRetailer(string memory _company) {
        require(
            companies[_company].organisationRole == OrganisationRole.Retailer,
            "Company is not a Retailer"
        );
        _;
    }

    /**
     * Modifier to check if company is allowed to create PO
     */
    modifier allowedToCreatePO(string memory buyer, string memory seller) {
        require(
            ((companies[seller].organisationRole ==
                OrganisationRole.Manufacturer &&
                companies[buyer].organisationRole ==
                OrganisationRole.Distributor) ||
                (companies[seller].organisationRole ==
                    OrganisationRole.Distributor &&
                    companies[buyer].organisationRole ==
                    OrganisationRole.Retailer)),
            "Company is not allowed to create PO"
        );
        _;
    }

    /**
     * Modifier to check if company is allowed to create Shipment
     */
    modifier allowedToCreateShipment(string memory _buyer) {
        require(
            companies[_buyer].organisationRole ==
                OrganisationRole.Distributor ||
                companies[_buyer].organisationRole == OrganisationRole.Retailer,
            "Company is not allowed to create PO"
        );
        _;
    }

    /**
     * Modifier to check if company is allowed to create Shipment
     */
    modifier allowedToUpdateShipment(string memory _transporter) {
        require(
            companies[_transporter].organisationRole ==
                OrganisationRole.Transporter,
            "Company is not allowed to create PO"
        );
        _;
    }

    function toAsciiString(
        address _address
    ) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_address)));
        bytes memory result = new bytes(42);
        result[0] = "0";
        result[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            uint8 b = uint8(value[i]);
            uint8 hi = b / 16;
            uint8 lo = b - 16 * hi;
            result[2 + 2 * i] = char(hi);
            result[3 + 2 * i] = char(lo);
        }
        return string(result);
    }

    function char(uint8 b) internal pure returns (bytes1 c) {
        if (b < 10) {
            return bytes1(uint8(b) + 0x30);
        } else {
            return bytes1(uint8(b) + 0x57);
        }
    }

    /**
     * Funtion to add new companies
     */
    function registerCompany(
        string memory _companyCRN,
        string memory _companyName,
        string memory _location,
        OrganisationRole _role
    ) public notAlreadyRegistered(_companyCRN) returns (Company memory) {
        companies[_companyCRN].companyID = _companyCRN;
        companies[_companyCRN].name = _companyName;
        companies[_companyCRN].location = _location;
        companies[_companyCRN].admin = msg.sender;
        if (_role == OrganisationRole.Manufacturer) {
            companies[_companyCRN].organisationRole = _role;
            companies[_companyCRN].hierarchyKey = 1;
        } else if (_role == OrganisationRole.Distributor) {
            companies[_companyCRN].organisationRole = _role;
            companies[_companyCRN].hierarchyKey = 2;
        } else if (_role == OrganisationRole.Retailer) {
            companies[_companyCRN].organisationRole = _role;
            companies[_companyCRN].hierarchyKey = 3;
        } else {
            companies[_companyCRN].organisationRole = _role;
            companies[_companyCRN].hierarchyKey = 0;
        }
        return companies[_companyCRN];
    }

    function getRegisteredCompany(
        string memory _companyCRN
    ) public view returns (Company memory) {
        return companies[_companyCRN];
    }

    /**
     * Funtion to add new drug by the manufacturer
     */
    function addDrug(
        string memory _drugName,
        string memory _serialNumber,
        string memory _manufacturingDate,
        string memory _expiryDate,
        string memory _companyCRN
    ) public alreadyRegistered(_companyCRN) onlyManufacturer(_companyCRN) {
        string memory _productID = string(
            abi.encodePacked(_drugName, ":", _serialNumber)
        );
        drugs[_productID].productId = _productID;
        drugs[_productID].name = _drugName;
        drugs[_productID].manufacturer = _companyCRN;
        drugs[_productID].manufacturingDate = _manufacturingDate;
        drugs[_productID].expiryDate = _expiryDate;
        drugs[_productID].owner = _companyCRN;
        drugs[_productID].shipment = new string[](0);
        drugs[_productID].history = new string[](0);
        drugs[_productID].history.push("Drug added by Manufacturer");
    }

    function getRegisteredDrug(
        string memory _drugName,
        string memory _serialNumber
    ) public view returns (Drug memory) {

        string memory _productID = string(
            abi.encodePacked(_drugName, ":", _serialNumber)
        );
        return drugs[_productID];
    }

    /**
     * Funtion to create PO by the buyer
     */
    function createPO(
        string memory _buyerCRN,
        string memory _sellerCRN,
        string memory _drugName,
        uint256 _quantity
    )
        public
        alreadyRegistered(_buyerCRN)
        alreadyRegistered(_sellerCRN)
        allowedToCreatePO(_buyerCRN, _sellerCRN)
    {
        string memory _poID = string(
            abi.encodePacked(_buyerCRN, ":", _drugName)
        );
        purchaseOrders[_poID].poID = _poID;
        purchaseOrders[_poID].drugName = _drugName;
        purchaseOrders[_poID].buyer = _buyerCRN;
        purchaseOrders[_poID].quantity = _quantity;
        purchaseOrders[_poID].seller = companies[_sellerCRN].companyID;
    }

    function getRegisteredPO(
        string memory _buyerCRN,
        string memory _drugName
    ) public view returns (PurchaseOrder memory) {
        string memory _poID = string(
            abi.encodePacked(_buyerCRN, ":", _drugName)
        );
        return purchaseOrders[_poID];
    }

    /**
     * Funtion to create shipment by the seller
     */
    function createShipment(
        string memory _buyerCRN,
        string memory _drugName,
        string[] memory listOfAssets,
        string memory _transporterCRN
    )
        public
        alreadyRegistered(_buyerCRN)
        alreadyRegistered(_transporterCRN)
        allowedToCreateShipment(_buyerCRN)
    {
        string memory _poID = string(
            abi.encodePacked(_buyerCRN, ":", _drugName)
        );
        string memory _shipmentId = string(
            abi.encodePacked(_buyerCRN, ":", _drugName)
        );
        PurchaseOrder memory po = purchaseOrders[_poID];
        require(
            po.quantity == listOfAssets.length,
            "The length of listOfAssets should be exactly equal to the quantity specified in the PO."
        );
        for (uint i = 0; i < listOfAssets.length; i++) {
            string memory _productID = string(
                abi.encodePacked(_drugName, ":", listOfAssets[i])
            );
            require(
                compare(_productID, drugs[_productID].productId),
                "The productId is not registered"
            );

            drugs[_productID].history.push(
                string(
                    abi.encodePacked(
                        "Drug dispatched by seller ",
                        drugs[_productID].owner,
                        " with transporter ",
                        _transporterCRN,
                        " for PO ",
                        _poID
                    )
                )
            );
            drugs[_productID].owner = _transporterCRN;
        }
        shipments[_shipmentId].shipmentID = _shipmentId;
        shipments[_shipmentId].assets = listOfAssets;
        shipments[_shipmentId].creator = po.seller;
        shipments[_shipmentId].status = "In-Transit";
        shipments[_shipmentId].transporter = _transporterCRN;
    }

    function getRegisteredShipment(
        string memory _buyerCRN,
        string memory _drugName
    ) public view returns (Shipment memory) {
        string memory _shipmentId = string(
            abi.encodePacked(_buyerCRN, ":", _drugName)
        );
        return shipments[_shipmentId];
    }

    /**
     * Funtion to update shipment by the transporter
     */
    function updateShipment(
        string memory _buyerCRN,
        string memory _drugName,
        string memory _transporterCRN
    )
        public
        alreadyRegistered(_buyerCRN)
        alreadyRegistered(_transporterCRN)
        allowedToUpdateShipment(_transporterCRN)
    {
        string memory _poID = string(
            abi.encodePacked(_buyerCRN, ":", _drugName)
        );
        string memory _shipmentId = string(
            abi.encodePacked(_buyerCRN, ":", _drugName)
        );
        require(
            compare(shipments[_shipmentId].transporter, _transporterCRN),
            "Transporter is different"
        );
        for (uint i = 0; i < shipments[_shipmentId].assets.length; i++) {
            string memory _productID = string(
                abi.encodePacked(
                    _drugName,
                    ":",
                    shipments[_shipmentId].assets[i]
                )
            );
            drugs[_productID].history.push(
                string(
                    abi.encodePacked(
                        "Drug delivered by transporter ",
                        _transporterCRN,
                        " to buyer ",
                        _buyerCRN,
                        " for PO ",
                        _poID
                    )
                )
            );
            drugs[_productID].shipment.push(_shipmentId);
            drugs[_productID].owner = _buyerCRN;
        }
        shipments[_shipmentId].status = "Delivered";
    }

    function retailDrug(
        string memory _drugName,
        string memory _serialNo,
        string memory _retailerCRN,
        string memory _customerAadhar
    ) public alreadyRegistered(_retailerCRN) onlyRetailer(_retailerCRN) {
        string memory _productID = string(
            abi.encodePacked(_drugName, ":", _serialNo)
        );
        drugs[_productID].owner = _customerAadhar;
        drugs[_productID].history.push(
            string(
                abi.encodePacked(
                    "Drug sold to customer with AADHAR ",
                    _customerAadhar,
                    " by retailer ",
                    _retailerCRN
                )
            )
        );
    }

    function viewHistory(
        string memory _drugName,
        string memory _serialNo
    ) external view returns (string[] memory) {
        string memory _productID = string(
            abi.encodePacked(_drugName, ":", _serialNo)
        );
        return drugs[_productID].history;
    }

    function viewDrugCurrentState(
        string memory _drugName,
        string memory _serialNo
    ) external view returns (string memory) {
        string memory _productID = string(
            abi.encodePacked(_drugName, ":", _serialNo)
        );
        return drugs[_productID].history[drugs[_productID].history.length - 1];
    }

    function compare(
        string memory str1,
        string memory str2
    ) public pure returns (bool) {
        if (bytes(str1).length != bytes(str2).length) {
            return false;
        }
        return
            keccak256(abi.encodePacked(str1)) ==
            keccak256(abi.encodePacked(str2));
    }
}
