// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract SecureSetUp is Ownable, Pausable, ReentrancyGuard
{   
    address _owner = owner();
    
    fallback() external payable 
    {
        payable(_owner).transfer(msg.value);
    }

    receive() external payable
    {
        payable(_owner).transfer(msg.value);
    }

    function pauseContract() external onlyOwner
    {
        _pause();
    }

    function unpauseContract() external onlyOwner
    {
        _unpause();
    }
}


contract TempIDTransactions is SecureSetUp
{   

    event sendOptsEdited(uint, uint);

    uint256[5] sendOpts = [10000000000000000, 100000000000000000, 1000000000000000000, 10000000000000000000, 100000000000000000000]; 

    function modifySendOpts(uint _index, uint _value) external onlyOwner
    {
        uint _oldVal = sendOpts[_index];
        sendOpts[_index] = _value;
        emit sendOptsEdited(_oldVal, _value);
    }

    function getBalance() external view returns(uint)
    {
        return address(this).balance;
    }

    modifier validAmountTransfer
    {
        require(msg.value == sendOpts[0] || msg.value == sendOpts[1] || msg.value == sendOpts[2] || msg.value == sendOpts[3] || msg.value == sendOpts[4], "Invalid amount sent"); 
        _;
    }



    mapping(bytes32 => bool) private registeredID;
    mapping(bytes32 => bool) private validID;
    mapping(bytes32 => uint) private IDbalance; 

    // hashes generated linke this 

    // function generateID(address _addressID, string memory _password) public pure returns (bytes32)
    // {
    //     return (keccak256(abi.encodePacked(_addressID, _password)));       
    // }

    function registerID(bytes32 _singleUseID) external whenNotPaused
    {
        require(registeredID[_singleUseID] != true, "ID was previously registered");

        validID[_singleUseID] = true; 
        registeredID[_singleUseID] = true; 
        IDbalance[_singleUseID] = 0;
    }  

    function sendToID(bytes32 _singleUseID) external payable nonReentrant() validAmountTransfer whenNotPaused
    {
        require(validID[_singleUseID] == true,"Invalid ID");

        uint _amount = msg.value;

        IDbalance[_singleUseID] = IDbalance[_singleUseID] + _amount;
    }

    function completeWithdraw(string memory _password) external nonReentrant() whenNotPaused
    {
        address _msgSender = msg.sender;
        bytes32 _singleUseID = keccak256(abi.encodePacked(_msgSender, _password)); 

        require(validID[_singleUseID] == true,"Invalid ID"); 
        require(IDbalance[_singleUseID] != 0, "No ID balance");

        payable(_msgSender).transfer(IDbalance[_singleUseID]); 

        IDbalance[_singleUseID] = 0;
        validID[_singleUseID] = false;
    }
}
