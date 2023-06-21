const { ethers, upgrades } = require("hardhat");

async function main() {

    const sellItMarketPlaces = await ethers.getContractFactory("sellItMarketPlace");
  
   console.log("Deploying sellItMarketPlace v1...");
  
   const sellit = await upgrades.deployProxy(sellItMarketPlaces, ['0x20ED366c95f34f6DE849c23C80c523255Cb530F5','250'], {
     initializer: "initialize",
   });

   await sellit.deployed();
   console.log('MsellItMarketPlace Deploying wait...................')
  
   console.log("sellItMarketPlace deployed to:", sellit.address);
  
  }
  
  main();