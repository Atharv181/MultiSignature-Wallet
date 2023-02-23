//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;


contract multiSigWallet {

    address[] public owners;
    uint public numberOfConfirmationReq;

    struct Transaction {
        address to;
        uint value;
        bool executed;
    }

    mapping(uint =>mapping(address=>bool)) public isConfirmed;
    Transaction[] public transactions;

    event TransactionSubmitted(uint transactionId,address sender, address receiver, uint amount);
    event TransactionConfirmed(uint transactionId);
    event TransactionExecuted(uint transactionId);

    constructor(address[] memory _owners , uint _numberOfConfirmationReq){
        require(_owners.length > 1 , "Number of owners should be greater than 1");
        require(_numberOfConfirmationReq>1 && _numberOfConfirmationReq <= _owners.length,"Number of confirmation required ");

        for(uint i=0;i<_owners.length;i++){
            require(_owners[i] != address(0) , "Address is invalid");
            owners.push(_owners[i]);
        }

        numberOfConfirmationReq =_numberOfConfirmationReq;
    }

    function submitTransaction(address _to) public payable{
        require(_to != address(0),"Address is invalid");
        require(msg.value>0 ,"Transfer amount should be greater than 1");

        uint transactionId = transactions.length;
        transactions.push(Transaction({to:_to,value: msg.value,executed:false}));
        emit TransactionSubmitted(transactionId,msg.sender,_to,msg.value);
    }

    function confirmTransaction(uint _transactionId) public{
        require(_transactionId < transactions.length, "Invalid transaction id");
        require(!isConfirmed[_transactionId][msg.sender], "Transaction is already Confirmed by owners");
        isConfirmed[_transactionId][msg.sender] = true;
        emit TransactionConfirmed(_transactionId);

        if(isTransactionConfirmed(_transactionId)){
            executeTransaction(_transactionId);
        }
    }

    function executeTransaction(uint _transactionId)public payable{
        require(_transactionId<transactions.length,"Invalid transaction Id");
        require(!transactions[_transactionId].executed,"Transaction already executed");

        (bool success,) = transactions[_transactionId].to.call{value: transactions[_transactionId].value}("");
        require(success, "Transaction Execution Failed");
        transactions[_transactionId].executed = true;
        emit TransactionExecuted(_transactionId);
    }


    function isTransactionConfirmed(uint transactionId) public view returns(bool){
        require(transactionId <transactions.length, "Invalid transaction id");
        uint confirmationCount;

        for(uint i=0;i<owners.length;i++){
            if(isConfirmed[transactionId][owners[i]]){
                confirmationCount++;
            }
        }

        return numberOfConfirmationReq <= confirmationCount;
    }
}