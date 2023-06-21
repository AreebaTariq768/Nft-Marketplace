// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";




contract sellItMarketPlace is Initializable , ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, ERC721BurnableUpgradeable, OwnableUpgradeable , UUPSUpgradeable{
      /// @custom:oz-upgrades-unsafe-allow constructor
    function initialize(address _marketplaceOwner,uint256 _setServiceFee) public initializer {
        __ERC721_init("sellItMarket", "SIM");
        __Ownable_init();
        __UUPSUpgradeable_init();

        marketplaceOwner=_marketplaceOwner;
         setServiceFeePercentage(_setServiceFee);


}

     using SafeMathUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;
      address marketplaceOwner;
    uint256 public defaultServicefee;
    // ***nft buyer case****//
        mapping(uint=>bool) public nftstate;
    mapping(uint=>address) public nftbuyerAddress;
    mapping(uint256 => uint256) public nftBuyerReturns;
       //* non nft buyer case
      mapping(uint=>bool) public nonNftstate;
      mapping(uint=>address) public nonNftbuyerAddress;
    mapping(uint256 => uint256) public nonNftBuyerReturns;
   
    //NFT Auction properties
    event AuctionEnded(address winner, uint amount);
    //NFT Auction structures
    struct Auction {
       address  highestBidder;
        uint256 highestBid;
         uint auctionEndTime;
          bool OpenForBidding;
        uint256 tokenId;
    }
    // NFT Auctions
    mapping (uint256 => Auction) public auctions;
    //   NOn NFT properties

    event nonNftAuctionEnded(address winner, uint amount);
    // Non nft structures
    struct nonNftAuction {
         address payable beneficiary;
         address highestBidder;       
        uint256 highestBid;
       uint auctionEndTime;
          bool OpenForBidding;
        uint256 tokenId;
    }
    mapping (uint256 => nonNftAuction) public nonNftauctions;


     function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function setServiceFeePercentage(uint256 _newServiceFee) public  {
        // require( marketplaceOwner == msg.sender,"Only Marketplace Owner can call this method");
        defaultServicefee = _newServiceFee;
    }

    function calculateServiceFee(uint256 _salePrice) internal view returns (uint256) {
        require(defaultServicefee != 0,"Set Service fee first.");
        require(defaultServicefee <= 10000, "ERC2981: service fee will exceed salePrice");
        uint256 servicefee = _salePrice.mul(defaultServicefee).div(10000);
        return servicefee;
    }
    function safeMint(address to, string memory uri) public {
        uint256 tokenId = _tokenIdCounter.current();
         require(to==msg.sender,"Address mismatch");
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }
        //******* NON NFT START **********//
         // NON NFT Auction Code start here
     function nonNftstartAuction(uint _biddingendtime , address payable _beneficiary , uint256 nonNftId) public {
          require(nonNftstate[nonNftId]==false,"Already Buy in Process");
         nonNftauctions[nonNftId].beneficiary = _beneficiary;
        nonNftauctions[nonNftId].auctionEndTime = block.timestamp + _biddingendtime;
        nonNftauctions[nonNftId].tokenId = nonNftId;
        nonNftauctions[nonNftId].OpenForBidding=true;
    }
       function bidNonNft( uint256 nonNftId) payable public{
        require(nonNftauctions[nonNftId].OpenForBidding,"Bidding is not open yet");
        require(nonNftauctions[nonNftId].beneficiary!=msg.sender,"Not a Bidder");
        address  currentBidOwner = nonNftauctions[nonNftId].highestBidder;
        uint256  currentBidAmount = nonNftauctions[nonNftId].highestBid;
        if(block.timestamp > nonNftauctions[nonNftId].auctionEndTime){
            revert("The auction has already ended");
        }
        if(msg.value <=  currentBidAmount) {
            revert("There is already higher or equal bid exist");
        }
        if(msg.value > currentBidAmount ) {
            payable(currentBidOwner).transfer(currentBidAmount);
        }
   
        nonNftauctions[nonNftId].highestBidder =  msg.sender;
        nonNftauctions[nonNftId].highestBid =  msg.value;
    }
        function NonNftconfirmbidding(uint256 nonNftId) public{
            require(nonNftauctions[nonNftId].OpenForBidding,"Bidding is not open yet"); 
         require (block.timestamp > nonNftauctions[nonNftId].auctionEndTime ,"The auction has not ended yet");
          require (msg.sender == nonNftauctions[nonNftId].highestBidder || msg.sender==marketplaceOwner,"Only HighestBidder can call this method");
          emit nonNftAuctionEnded( nonNftauctions[nonNftId].highestBidder ,  nonNftauctions[nonNftId].highestBid);
         uint256 serviceFee = calculateServiceFee(auctions[nonNftId].highestBid);
        uint256 afterCutPrice = nonNftauctions[nonNftId].highestBid - serviceFee ;
        payable(marketplaceOwner).transfer(serviceFee);
        payable(nonNftauctions[nonNftId].beneficiary).transfer(afterCutPrice);
         delete nonNftauctions[nonNftId];
        
    }
     function NonNftcancelbidding(uint256 nonNftId) public
    {
        require(nonNftauctions[nonNftId].OpenForBidding,"Bidding is not open yet");
           require (block.timestamp > nonNftauctions[nonNftId].auctionEndTime ,"The auction has not ended yet");
          require (msg.sender == nonNftauctions[nonNftId].highestBidder || msg.sender==marketplaceOwner ,"Only HighestBidder can call this method");
        payable(nonNftauctions[nonNftId].highestBidder).transfer(address(this).balance);
         delete nonNftauctions[nonNftId];
    }
    // *****Buy Non-NFTs in Marketplace *****//
        function buyNonNft(uint256 nonNftId) public payable returns (bool) {
             if(nonNftauctions[nonNftId].OpenForBidding){
             require((nonNftauctions[nonNftId].highestBidder == address(0)) || (block.timestamp < nonNftauctions[nonNftId].auctionEndTime),"Bidding in Process" );
           payable(nonNftauctions[nonNftId].highestBidder).transfer(nonNftauctions[nonNftId].highestBid);
           delete nonNftauctions[nonNftId];
        }
          require(block.timestamp > nonNftauctions[nonNftId].auctionEndTime,"Bidding is ended");  
          require(nonNftstate[nonNftId]==false,"Already in process");
         require (msg.value > 0 ether,"amount send is less than require value");
         nonNftbuyerAddress[nonNftId]=msg.sender;
        nonNftBuyerReturns[nonNftId] = msg.value;
         nonNftstate[nonNftId]=true;
         return true;
    }
    function nonNftDelivery(uint256 nonNftId,address seller) external { 
         require (nonNftstate[nonNftId]==true,"ALREADY CANCLE ORDER"); 
         uint256 amount = nonNftBuyerReturns[nonNftId];
          address nonNftbuyer=nonNftbuyerAddress[nonNftId];
          require (msg.sender == nonNftbuyer|| msg.sender==marketplaceOwner,"Not buyer");
            require (msg.sender != seller ,"Only buyer can call this method"); 
             uint256 serviceFee = calculateServiceFee(amount);
        uint256 afterCutPrice = amount - serviceFee;       
          payable(seller).transfer(afterCutPrice);
        payable(marketplaceOwner).transfer(serviceFee);
          nonNftBuyerReturns[nonNftId]=0;
          nonNftstate[nonNftId]=false;


    }
     function nonNftcancelDelivery(uint256 nonNftId) public
    {
         require (nonNftstate[nonNftId]==true,"ALREADY CONFIRMED ORDER");
         uint256 amount = nonNftBuyerReturns[nonNftId];
          address nonNftbuyer=nonNftbuyerAddress[nonNftId];
          require (msg.sender == nonNftbuyer || msg.sender==marketplaceOwner,"Not buyer");
         payable(nonNftbuyer).transfer(amount);
         nonNftBuyerReturns[nonNftId]=0;
          nonNftstate[nonNftId]=false;
    }


     //******* NON NFT END **********//


     
   //******* NFT START **********//
     // NftAuction Code start here

     function startAuction(uint _biddingendtime , uint256 tokenId) public {
           require(nftstate[tokenId]==false,"Already Buy in Process");
         require(msg.sender==ownerOf(tokenId),"Only owner can call this method");   
        auctions[tokenId].auctionEndTime = block.timestamp + _biddingendtime; 
        auctions[tokenId].tokenId = tokenId;  
        auctions[tokenId].OpenForBidding=true;
    }

// bidding and return pendings//
        function bid( uint256 tokenId) payable public{
        require(auctions[tokenId].OpenForBidding,"Bidding is not open yet");
        require(ownerOf(tokenId)!=msg.sender,"Owner cannot bid");
        address  currentBidOwner = auctions[tokenId].highestBidder;
        uint256  currentBidAmount = auctions[tokenId].highestBid;
        if(block.timestamp > auctions[tokenId].auctionEndTime){
            revert("The auction has already ended");
        }
        if(msg.value <=  currentBidAmount) {
            revert("There is already higher or equal bid exist");
        }
        if(msg.value > currentBidAmount ) {
            payable(currentBidOwner).transfer(currentBidAmount);
        }
          auctions[tokenId].highestBidder =  msg.sender;
        auctions[tokenId].highestBid =  msg.value;
    }

    // *****Payment and token transfer *****//
        function confirmbidding( uint256 tokenId) public{
            address seller=ownerOf(tokenId);
            require(auctions[tokenId].OpenForBidding,"Bidding is not open yet");
          require (block.timestamp > auctions[tokenId].auctionEndTime,"The auction has not ended yet");
          require (msg.sender == auctions[tokenId].highestBidder || msg.sender==marketplaceOwner,"Only HighestBidder can call this method");
          emit AuctionEnded(auctions[tokenId].highestBidder , auctions[tokenId].highestBid);
         uint256 serviceFee = calculateServiceFee(auctions[tokenId].highestBid);
         uint256 afterCutPrice = auctions[tokenId].highestBid - serviceFee ;
         _transfer(seller,auctions[tokenId].highestBidder,tokenId);     
        payable(marketplaceOwner).transfer(serviceFee);
        payable(seller).transfer(afterCutPrice);
         delete auctions[tokenId];
    }
    // ******Cancle Bidding and payment returns *****//
     function cancelbidding( uint256 tokenId) public
    { 
         require(auctions[tokenId].OpenForBidding,"Bidding is not open yet");
         require (block.timestamp > auctions[tokenId].auctionEndTime,"The auction has not ended yet");
          require (msg.sender == auctions[tokenId].highestBidder || msg.sender==marketplaceOwner,"Only HighestBidder can call this method");
        payable(auctions[tokenId].highestBidder).transfer(address(this).balance);
         delete auctions[tokenId];
    }


    // *****Buy NFTs in Marketplace *****//
   function buy(uint256 tokenId) public payable returns (bool) {
        if(auctions[tokenId].OpenForBidding){
            require((auctions[tokenId].highestBidder == address(0)) || (block.timestamp < auctions[tokenId].auctionEndTime),"Bidding in Process" );
           payable(auctions[tokenId].highestBidder).transfer(auctions[tokenId].highestBid);
          // end auction 
           delete auctions[tokenId];
        }
       require(nftstate[tokenId]==false,"Already in process");
        require (msg.value > 0 ether,"amount send is less than require value");    
        require (msg.sender != ownerOf(tokenId) ,"Only buyer can call this method"); 
         nftbuyerAddress[tokenId]=msg.sender;
        nftBuyerReturns[tokenId] = msg.value;
        nftstate[tokenId]=true;
          return true;
    }
    // ****Transfer the owner of token nd payment *******//
   function confirmDelivery(uint256 tokenId) external {
       
       require (nftstate[tokenId]==true,"ALREADY CANCLE ORDER"); 
         address  nftSeller=ownerOf(tokenId);
         address nftbuyer=nftbuyerAddress[tokenId];
         uint256 amount = nftBuyerReturns[tokenId];
          require (msg.sender == nftbuyer || msg.sender==marketplaceOwner,"Not buyer");
         require (msg.sender != ownerOf(tokenId) ,"Only buyer can call this method");
         uint256 serviceFee = calculateServiceFee(amount);
         uint256 afterCutPrice = amount - serviceFee;
         _transfer(nftSeller,nftbuyer,tokenId);
          payable(nftSeller).transfer(afterCutPrice);
        payable(marketplaceOwner).transfer(serviceFee);
          nftBuyerReturns[tokenId]=0;
          nftstate[tokenId]=false;
        
    }
     function cancelDelivery(uint256 tokenId) public
    { 
        require (nftstate[tokenId]==true,"ALREADY CONFIRMED ORDER");
          uint256 amount =  nftBuyerReturns[tokenId];
         address nftbuyer=nftbuyerAddress[tokenId];
         require (msg.sender == nftbuyer || msg.sender==marketplaceOwner,"Not buyer");
         payable(nftbuyer).transfer(amount);
         nftBuyerReturns[tokenId]=0;
         nftstate[tokenId]=false;
         
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}