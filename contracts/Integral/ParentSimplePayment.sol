// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Solirey.sol";

contract ParentSimplePayment {
    Solirey solirey;

    struct Payment {
        uint payment;
        uint price;
        uint fee;
        uint256 tokenId;
        address seller;
    }
        
    // Maps from a item ID to Payment
    mapping (uint => Payment) public _simplePayment;
    
    event CreatePayment(uint id);
    event PaymentMade(uint id);

    constructor(address solireyAddress) {
        require(msg.sender == solirey.admin());
        solirey = Solirey(solireyAddress);
    }

    function abort(uint id) external {
        Payment memory sp = _simplePayment[id];
        require(msg.sender == sp.seller, "Unauthorized");
        require(sp.price != 0, "Not for sale");
        require(sp.payment == 0, "Already purchased");
        
        solirey.transferFrom(address(this), sp.seller, sp.tokenId);
    }

    // function resell(uint price, uint256 tokenId) external {
    //     require(
    //         price > 0,
    //         "Wrong pricing"
    //     );

    //     solirey.tokenTransfer(msg.sender, address(this), tokenId);

    //     solirey.incrementUid();
    //     uint256 uid = solirey.currentUid();
    //     emit CreatePayment(uid);

    //     _simplePayment[uid].price = price;
    //     _simplePayment[uid].tokenId = tokenId;
    //     _simplePayment[uid].seller = msg.sender;
    // }

    function withdrawFee(uint id) external {
        require(
            solirey.admin() == msg.sender,
            "Not authorized"
        );
        
        solirey.admin().transfer(_simplePayment[id].fee);
    }

    function onERC721Received(address, address, uint256 _tokenId, bytes memory data) external virtual returns (bytes4) {
        (uint _price) = abi.decode(data, (uint));   
        
        require(
            _price > 0,
            "Wrong pricing"
        );

        solirey.tokenTransfer(msg.sender, address(this), _tokenId);

        solirey.incrementUid();
        uint256 uid = solirey.currentUid();
        emit CreatePayment(uid);

        _simplePayment[uid].price = _price;
        _simplePayment[uid].tokenId = _tokenId;
        _simplePayment[uid].seller = msg.sender;
        
        return this.onERC721Received.selector;
    }
}

