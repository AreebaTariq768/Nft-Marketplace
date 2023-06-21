const { ethers, upgrades } = require("hardhat");

const PROXY = "0x42e05fCa02F4eb18E2287B304eC0fD5550dEECBB";

async function main() {

 const sellItMarketPlaceV2s = await ethers.getContractFactory("sellItMarketPlaceV2");

 console.log("Upgrading Sell it Marketplace to version 2...................");
 
 await upgrades.upgradeProxy(PROXY, sellItMarketPlaceV2s);
 
 console.log("Sellit marketplace version 2 has been upgraded Successfully");
 console.log("HAHAHAHAHAHHAHAAHHAHAHAHAHAHAHAHAHAHAAH");

}

main();