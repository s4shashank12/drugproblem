//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

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
    modifier alreadyRegistered(string memory _company) {
        require(
            companies[_company].admin != address(0),
            "Company is already registered"
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

    /**
     * Funtion to add new companies
     */
    function registerCompany(
        string memory _companyCRN,
        string memory _companyName,
        string memory _location,
        OrganisationRole _role
    ) public alreadyRegistered(_companyCRN) {
        companies[_companyCRN].companyID = _companyCRN;
        companies[_companyCRN].name = _companyName;
        companies[_companyCRN].location = _location;
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
            require(
                compare(listOfAssets[i], drugs[listOfAssets[i]].productId),
                "The productId is not registered"
            );
            drugs[listOfAssets[i]].owner = _transporterCRN;
        }
        shipments[_shipmentId].shipmentID = _shipmentId;
        shipments[_shipmentId].assets = listOfAssets;
        shipments[_shipmentId].creator = po.seller;
        shipments[_shipmentId].status = "In-Transit";
        shipments[_shipmentId].transporter = _transporterCRN;
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
        string memory _shipmentId = string(
            abi.encodePacked(_buyerCRN, ":", _drugName)
        );
        require(
            compare(shipments[_shipmentId].transporter, _transporterCRN),
            "Transporter is different"
        );
        for (uint i = 0; i < shipments[_shipmentId].assets.length; i++) {
            drugs[shipments[_shipmentId].assets[i]].shipment.push(_shipmentId);
            drugs[shipments[_shipmentId].assets[i]].owner = _buyerCRN;
        }
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
