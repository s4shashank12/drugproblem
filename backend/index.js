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

app.post('/registerCompany', async (req, res) => {
    try {
      const { companyCRN, companyName, location, role } = req.body;
  
      const accounts = await web3.eth.getAccounts(); // Use Hardhat accounts
      const fromAddress = accounts[11];
  
      const gasEstimate = await contractInstance.methods
        .registerCompany(companyCRN, companyName, location, role)
        .estimateGas({ from: fromAddress });
  
      const result = await contractInstance.methods
        .registerCompany(companyCRN, companyName, location, role)
        .send({ from: fromAddress, gas: gasEstimate });
  
      res.status(200).json({ message: 'Company registered', result });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error registering company', error });
    }
  });

  app.post('/addDrug', async (req, res) => {
    try {
      const { drugName, serialNumber, mafDate, expDate, companyCRN } = req.body;
  
      const accounts = await web3.eth.getAccounts(); // Use Hardhat accounts
      const fromAddress = accounts[11];
  
      const gasEstimate = await contractInstance.methods
        .addDrug(drugName, serialNumber, mafDate, expDate, companyCRN)
        .estimateGas({ from: fromAddress });
  
      const result = await contractInstance.methods
        .addDrug(drugName, serialNumber, mafDate, expDate, companyCRN)
        .send({ from: fromAddress, gas: gasEstimate });
  
      res.status(200).json({ message: 'Company registered', result });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error registering company', error });
    }
  });
  
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, () => console.log(`Server running on port ${PORT}`));