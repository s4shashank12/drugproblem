const express = require('express');
const Web3 = require('web3');
const app = express();
app.use(express.json());

const provider = 'ws://localhost:8545';
const web3 = new Web3(provider);
const fs = require('fs');
const path = require('path');

const contractName = 'Drugs';
const contractPath = path.join(__dirname, '..', 'artifacts', 'contracts', `\\${contractName}.sol`, `\\${contractName}.json`);
const contractArtifact = JSON.parse(fs.readFileSync(contractPath, 'utf8'));

const contractABI = contractArtifact.abi;
const contractAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3"; // Use Hardhat network address

const contractInstance = new web3.eth.Contract(contractABI, contractAddress);

const roles = ["Manufacturer", "Distributor", "Retailer", "Transporter"];

async function fromWAddress() {
  const accounts = await web3.eth.getAccounts(); // Use Hardhat accounts
  const fromAddress = accounts[11];
  return fromAddress;
}

app.post('/registerCompany', async (req, res) => {
  try {
    const { companyCRN, companyName, location, role } = req.body;
    const fromAddress = await fromWAddress();
    const gasEstimate = await contractInstance.methods
      .registerCompany(companyCRN, companyName, location, role)
      .estimateGas({ from: fromAddress });
    await contractInstance.methods
      .registerCompany(companyCRN, companyName, location, role)
      .send({ from: fromAddress, gas: gasEstimate });
    const result = await contractInstance.methods.getRegisteredCompany(companyCRN).call();
    res.status(200).json({
      message: 'Company registered', result: {
        companyID: result[0],
        name: result[1],
        location: result[2],
        organisationRole: roles[result[3]],
        hierarchyKey: +result[4]
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error registering company', error });
  }
});

app.post('/addDrug', async (req, res) => {
  try {
    const { drugName, serialNumber, mafDate, expDate, companyCRN } = req.body;
    const fromAddress = await fromWAddress();
    const gasEstimate = await contractInstance.methods
      .addDrug(drugName, serialNumber, mafDate, expDate, companyCRN)
      .estimateGas({ from: fromAddress });
    await contractInstance.methods
      .addDrug(drugName, serialNumber, mafDate, expDate, companyCRN)
      .send({ from: fromAddress, gas: gasEstimate });
    const result = await contractInstance.methods.getRegisteredDrug(drugName, serialNumber).call();
    res.status(200).json({
      message: 'Drug registered', result: {
        productId: result[0],
        name: result[1],
        manufacturer: result[2],
        manufacturingDate: result[3],
        expiryDate: result[4],
        owner: result[5],
        shipment: result[6]
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error registering drug', error });
  }
});

app.post('/createPO', async (req, res) => {
  try {
    const { buyerCRN, sellerCRN, drugName, quantity } = req.body;
    const fromAddress = await fromWAddress();
    const gasEstimate = await contractInstance.methods
      .createPO(buyerCRN, sellerCRN, drugName, quantity)
      .estimateGas({ from: fromAddress });
    await contractInstance.methods
      .createPO(buyerCRN, sellerCRN, drugName, quantity)
      .send({ from: fromAddress, gas: gasEstimate });
    const result = await contractInstance.methods.getRegisteredPO(buyerCRN, drugName).call();
    res.status(200).json({
      message: 'PO Created', result: {
        poId: result[0],
        drugName: result[1],
        buyer: result[3],
        quantity: +result[2],
        seller: result[4]
      }
    });
  } catch (err) {
    console.error(error);
    res.status(500).json({ message: 'Error Creating PO', error });
  }
})

app.post('/createShipment', async (req, res) => {
  try {
    const { buyerCRN, drugName, listOfAssets, transporterCRN } = req.body;
    const fromAddress = await fromWAddress();
    const gasEstimate = await contractInstance.methods
      .createShipment(buyerCRN, drugName, listOfAssets, transporterCRN)
      .estimateGas({ from: fromAddress });
    await contractInstance.methods
      .createShipment(buyerCRN, drugName, listOfAssets, transporterCRN)
      .send({ from: fromAddress, gas: gasEstimate });
    const result = await contractInstance.methods.getRegisteredShipment(buyerCRN, drugName).call();
    res.status(200).json({
      message: 'Shipment Created', result: {
        shipmentID: result[0],
        creator: result[1],
        assets: result[2],
        transporter: result[3],
        status: result[4]
      }
    });
  } catch (err) {
    console.error(error);
    res.status(500).json({ message: 'Error Creating Shipment', error });
  }
})

app.post('/updateShipment', async (req, res) => {
  try {
    const { buyerCRN, drugName, transporterCRN } = req.body;
    const fromAddress = await fromWAddress();
    const gasEstimate = await contractInstance.methods
      .updateShipment(buyerCRN, drugName, transporterCRN)
      .estimateGas({ from: fromAddress });
    await contractInstance.methods
      .updateShipment(buyerCRN, drugName, transporterCRN)
      .send({ from: fromAddress, gas: gasEstimate });
    const result = await contractInstance.methods.getRegisteredShipment(buyerCRN, drugName).call();
    res.status(200).json({
      message: 'Shipment Updated', result: {
        shipmentID: result[0],
        creator: result[1],
        assets: result[2],
        transporter: result[3],
        status: result[4]
      }
    });
  } catch (err) {
    console.error(error);
    res.status(500).json({ message: 'Error Updating Shipment', error });
  }
})

app.post('/retailDrug', async (req, res) => {
  try {
    const { drugName, serialNumber, retailerCRN, customerAadhar } = req.body;
    const fromAddress = await fromWAddress();
    const gasEstimate = await contractInstance.methods
      .retailDrug(drugName, serialNumber, retailerCRN, customerAadhar)
      .estimateGas({ from: fromAddress });
    await contractInstance.methods
      .retailDrug(drugName, serialNumber, retailerCRN, customerAadhar)
      .send({ from: fromAddress, gas: gasEstimate });
    const result = await contractInstance.methods.getRegisteredDrug(drugName, serialNumber).call();
    res.status(200).json({
      message: 'Retail Drug', result: {
        productId: result[0],
        name: result[1],
        manufacturer: result[2],
        manufacturingDate: result[3],
        expiryDate: result[4],
        owner: result[5],
        shipment: result[6]
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error Retail Drug', error });
  }
});

app.post('/viewHistory', async (req, res) => {
  try {
    const { drugName, serialNumber } = req.body;
    const result = await contractInstance.methods.viewHistory(drugName, serialNumber).call();
    res.status(200).json({
      message: 'View History', result
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error View History', error });
  }
});

app.post('/viewDrugCurrentState', async (req, res) => {
  try {
    const { drugName, serialNumber } = req.body;
    const result = await contractInstance.methods.viewDrugCurrentState(drugName, serialNumber).call();
    res.status(200).json({
      message: 'viewDrugCurrentState', result
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error View Drug Current State', error });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));


