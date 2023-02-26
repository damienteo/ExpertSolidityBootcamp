// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17; // Update minor version to 17 from 0, actually decreases deployment cost by 0.2%, and a bit of gas cost

// Contract already has onlyAdminOrOwner implementation
// Decreases deployment cost by 0.8%
// import "./Ownable.sol";

// Constants are either not used or not re-declared
// Decreases deployment cost by 0.3%
// contract Constants {
// uint256 public tradeFlag = 1;
// uint256 public basicFlag = 0;
// uint256 public dividendFlag = 1;
// }

error NotAdminOrOwner();
error NotWhiteListed();

error InsufficientBalance();
error NameLengthError();

error InvalidAmount();
error InvalidId();
error InvalidAddress();
error InvalidTier();

contract GasContract {
    // Remove un-necessary declarations as 0
    // Mainly decreases deployment cost

    // Comment out unused variables
    // uint256 public tradeMode;
    // bool public isReady = false;
    // PaymentType constant defaultPayment = PaymentType.Unknown;
    uint256 public totalSupply; // cannot be updated
    uint256 public paymentCounter;
    mapping(address => uint256) public balances;
    // Set to constant as it never changes
    // Decreases deployment cost by 0.1%
    uint256 public constant tradePercent = 12;
    address public contractOwner;

    mapping(address => Payment[]) public payments;
    mapping(address => uint256) public whitelist;
    address[5] public administrators;

    enum PaymentType {
        Unknown,
        BasicPayment,
        Refund,
        Dividend,
        GroupPayment
    }

    // Changed to private since there is a getter method below
    // Decreases deployment cost by about 0.2 percent
    History[] private paymentHistory; // when a payment was updated

    struct Payment {
        PaymentType paymentType;
        uint256 paymentID;
        bool adminUpdated;
        string recipientName; // max 8 characters
        address recipient;
        address admin; // administrators address
        uint256 amount;
    }

    struct History {
        uint256 lastUpdate;
        address updatedBy;
        uint256 blockNumber;
    }
    uint256 wasLastOdd = 1;
    mapping(address => uint256) public isOddWhitelistUser;
    struct ImportantStruct {
        uint256 valueA; // max 3 digits
        uint256 bigValue;
        uint256 valueB; // max 3 digits
    }

    mapping(address => ImportantStruct) public whiteListStruct;

    modifier onlyAdminOrOwner() {
        address senderOfTx = msg.sender;
        // Simplified error check
        // Reduces deployment cost by 12.1%
        //  if (checkForAdmin(senderOfTx)) {
        //     require(
        //         checkForAdmin(senderOfTx),
        //         "Gas Contract Only Admin Check-  Caller not admin"
        //     );
        //     _;
        // } else if (senderOfTx == contractOwner) {
        //     _;
        // } else {
        //     revert(
        //         "Error in Gas contract - onlyAdminOrOwner modifier : revert happened because the originator of the transaction was not the admin, and furthermore he wasn't the owner of the contract, so he cannot run this function"
        //     );
        // }
        if (!checkForAdmin(senderOfTx) || senderOfTx != contractOwner) {
            revert NotAdminOrOwner();
        }
        _;
    }

    // Change modifier to within function check since used only once
    // modifier checkIfWhiteListed(address sender) {
    // Simplify Checks
    // Decreases Deployment Cost by 0.7%

    // sender will always be msg.sender?
    // since this is a modifier which calls checkIfWhiteListed(msg.sender)
    // address senderOfTx = msg.sender;
    // require(
    //     senderOfTx == sender,
    //     "Gas Contract CheckIfWhiteListed modifier : revert happened because the originator of the transaction was not the sender"
    // );
    // uint256 usersTier = whitelist[sender];
    // require(
    //     usersTier > 0,
    //     "Gas Contract CheckIfWhiteListed modifier : revert happened because the user is not whitelisted"
    // );
    // require(
    //     usersTier < 4,
    //     "Gas Contract CheckIfWhiteListed modifier : revert happened because the user's tier is incorrect, it cannot be over 4 as the only tier we have are: 1, 2, 3; therfore 4 is an invalid tier for the whitlist of this contract. make sure whitlist tiers were set correctly"
    // );

    //     if (usersTier <= 0 || usersTier >= 4) {
    //         revert NotWhiteListed();
    //     }
    //     _;
    // }

    event AddedToWhitelist(address userAddress, uint256 tier);
    event supplyChanged(address indexed, uint256 indexed);
    event Transfer(address recipient, uint256 amount);
    event PaymentUpdated(
        address admin,
        uint256 ID,
        uint256 amount,
        string recipient
    );
    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;
        totalSupply = _totalSupply;

        // ++ii instead of ii++ saves 50 gas in terms of deployment
        // renaming ii to i does not seem to save gas
        for (uint256 i = 0; i < administrators.length; ++i) {
            if (_admins[i] != address(0)) {
                administrators[i] = _admins[i];
                if (_admins[i] == contractOwner) {
                    // Contract Owner is not necessarily an administrator?
                    balances[_admins[i]] = totalSupply;
                    emit supplyChanged(_admins[i], totalSupply);
                }
            }
        }
    }

    // Remove declaration of admin variable
    // Increases deployment cost by ~1000
    // But decreases updatePayment and addToWhiteList by ~200
    function checkForAdmin(address _user) public view returns (bool) {
        // bool admin = false;
        // pre-increment - ++ii instead of ii++ decreased deployment cost by 450, and 20 gas for addToWhitelist and UpdatePayment
        // Changing administrators.length to 5 (a value decided at the start) does not affect gas costs
        for (uint256 ii = 0; ii < administrators.length; ++ii) {
            if (administrators[ii] == _user) {
                return true;
            }
        }
        return false;
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) external returns (bool) {
        // Not declaring new variable decreases gas cost by 15
        // address senderOfTx = msg.sender;

        // Changing to custom errors decrease deployment cost by 0.3%
        // require(
        //     balances[senderOfTx] >= _amount,
        //     "Gas Contract - Transfer function - Sender has insufficient Balance"
        // );
        // require(
        //     bytes(_name).length < 9,
        //     "Gas Contract - Transfer function -  The recipient name is too long, there is a max length of 8 characters"
        // );

        if (balances[msg.sender] < _amount) revert InsufficientBalance();
        if (bytes(_name).length > 8) revert NameLengthError();

        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        emit Transfer(_recipient, _amount);

        Payment memory payment;
        payment.admin = address(0);
        payment.adminUpdated = false;
        payment.paymentType = PaymentType.BasicPayment;
        payment.recipient = _recipient;
        payment.amount = _amount;
        payment.recipientName = _name;
        payment.paymentID = ++paymentCounter;
        payments[msg.sender].push(payment);

        // tradePercent is always 12
        // status[0] will always be true
        // Reduces deployment cost by 0.1%
        // Reduces gas cost by 3.5k
        // bool[] memory status = new bool[](tradePercent);
        // for (uint256 i = 0; i < tradePercent; i++) {
        //     status[i] = true;
        // }
        // return (status[0] == true);
        return true;
    }

    // returns (bool status_, bool tradeMode_)
    // Seems unnecessary
    // Decreases deployment cost by 0.3%
    // Decreases updatePayment by 3000 gas
    function addHistory(address _updateAddress) private {
        History memory history;
        history.blockNumber = block.number;
        history.lastUpdate = block.timestamp;
        history.updatedBy = _updateAddress;
        paymentHistory.push(history);
        // bool[] memory status = new bool[](tradePercent);
        // for (uint256 i = 0; i < tradePercent; i++) {
        //     status[i] = true;
        // }
        // return ((status[0] == true), _tradeMode);
    }

    function updatePayment(
        address _user,
        uint256 _ID,
        uint256 _amount,
        PaymentType _type
    ) public onlyAdminOrOwner {
        // Changing to custom error reduces deplyment cost by 0.4%
        // require(
        //     _ID > 0,
        //     "Gas Contract - Update Payment function - ID must be greater than 0"
        // );
        // require(
        //     _amount > 0,
        //     "Gas Contract - Update Payment function - Amount must be greater than 0"
        // );
        // require(
        //     _user != address(0),
        //     "Gas Contract - Update Payment function - Administrator must have a valid non zero address"
        // );

        if (_amount == 0) revert InvalidAmount();
        if (_ID == 0) revert InvalidId();
        if (_user == address(0)) revert InvalidAddress();

        // Not declaring senderOfTx reduces gas cost by 4
        // address senderOfTx = msg.sender;

        for (uint256 ii = 0; ii < payments[_user].length; ii++) {
            if (payments[_user][ii].paymentID == _ID) {
                payments[_user][ii].adminUpdated = true;
                payments[_user][ii].admin = _user;
                payments[_user][ii].paymentType = _type;
                payments[_user][ii].amount = _amount;
                // bool tradingMode = getTradingMode();
                addHistory(_user);
                emit PaymentUpdated(
                    msg.sender,
                    _ID,
                    _amount,
                    payments[_user][ii].recipientName
                );
            }
        }
    }

    function addToWhitelist(address _userAddrs, uint256 _tier)
        public
        onlyAdminOrOwner
    {
        // Using custom error here reduces deployment cost by 0.2%
        //       require(
        //     _tier < 255,
        //     "Gas Contract - addToWhitelist function -  tier level should not be greater than 255"
        // );
        if (_tier > 254) revert InvalidTier();
        whitelist[_userAddrs] = _tier;
        if (_tier > 3) {
            // Not sure why there us a need to decrease tier
            // if it will be set to 3 in the end
            // Same for rest of if/else
            // decreases deployment cost by 0.2%
            // gas cost by 1k
            whitelist[_userAddrs] = 3;
            // following two if/else can be combined
            // } else if (_tier == 1) {
            //     whitelist[_userAddrs] = 1;
            // } else if (_tier > 0 && _tier < 3) {
            //     whitelist[_userAddrs] = 2;
            // }
            // decreases gas cost by 16,
            // decreases deployment cost by 18k
        } else if (_tier > 0 && _tier < 3) {
            whitelist[_userAddrs] = _tier;
        }
        // Removing declaration of this variable will decrease deployment cost
        // But increase running cost
        uint256 wasLastAddedOdd = wasLastOdd;
        if (wasLastAddedOdd == 1) {
            wasLastOdd = 0;
            // Using 1 instead of variable decreases gas cost by 1
            // isOddWhitelistUser[_userAddrs] = wasLastAddedOdd;
            isOddWhitelistUser[_userAddrs] = 1;
        } else if (wasLastAddedOdd == 0) {
            wasLastOdd = 1;
            //  isOddWhitelistUser[_userAddrs] = wasLastAddedOdd;
            isOddWhitelistUser[_userAddrs] = 0;
        }
        // Following condition should not be possible
        // Decreases deployment cost by 0.2%
        // } else {
        //     revert("Contract hacked, imposible, call help");
        // }
        emit AddedToWhitelist(_userAddrs, _tier);
        // _tier does not reflect final tier
        // emit AddedToWhitelist(_userAddrs, whitelist[_userAddrs]);
    }

    // Removed use of checkIfWhiteListed(msg.sender) modifier since used only once
    function whiteTransfer(
        address _recipient,
        uint256 _amount,
        ImportantStruct memory _struct
    ) public {
        address senderOfTx = msg.sender;

        uint256 usersTier = whitelist[senderOfTx];

        if (usersTier <= 0 || usersTier >= 4) {
            revert NotWhiteListed();
        }
        if (balances[senderOfTx] < _amount) revert InsufficientBalance();
        if (_amount < 4) revert InvalidAmount();

        // Custom errors decrease deployment cost by 0.3%
        // require(
        //     balances[senderOfTx] >= _amount,
        //     "Gas Contract - whiteTransfers function - Sender has insufficient Balance"
        // );
        // require(
        //     _amount > 3,
        //     "Gas Contract - whiteTransfers function - amount to send have to be bigger than 3"
        // );
        balances[senderOfTx] -= _amount;
        balances[_recipient] += _amount;
        // Following two lines do not make sense
        balances[senderOfTx] += whitelist[senderOfTx];
        balances[_recipient] -= whitelist[senderOfTx];

        // Write to memory instead of storage
        // increases deployment cost by 0.1%
        // but decreases gast cost by ~260
        // whiteListStruct[senderOfTx] = ImportantStruct(0, 0, 0);
        // ImportantStruct storage newImportantStruct = whiteListStruct[
        //     senderOfTx
        // ];
        // newImportantStruct.valueA = _struct.valueA;
        // newImportantStruct.bigValue = _struct.bigValue;
        // newImportantStruct.valueB = _struct.valueB;

        ImportantStruct memory newImportantStruct = whiteListStruct[senderOfTx];
        newImportantStruct.valueA = _struct.valueA;
        newImportantStruct.bigValue = _struct.bigValue;
        newImportantStruct.valueB = _struct.valueB;
        whiteListStruct[senderOfTx] = newImportantStruct;

        emit WhiteListTransfer(_recipient);
    }

    // External functions can be moved to end of contract,
    // Since 'free' when not called as part of a transaction
    // Only reduces 4 gas for whiter=Transfer though

    // Changing to external
    function getPayments(address _user)
        external
        view
        returns (Payment[] memory payments_)
    {
        // Removing check reduces deployment cost by 0.2%
        // Check also not impt since no point for external users to check for address(0)
        // require(
        //     _user != address(0),
        //     "Gas Contract - getPayments function - User must have a valid non zero address"
        // );
        return payments[_user];
    }

    // Removal of balance variable actually decreased deployment cost by ~1000
    // Changing to external did not affect deployment cost
    function balanceOf(address _user) external view returns (uint256) {
        // uint256 balance = balances[_user];
        return balances[_user];
    }

    // Changed to 'external view' from 'public payable'
    // Decreases deployment cost by 0.2%
    function getPaymentHistory()
        external
        view
        returns (History[] memory paymentHistory_)
    {
        return paymentHistory;
    }

    function getTradingMode() public pure returns (bool) {
        // Nothing changes tradeFlag and dividendFlag
        return true;
        // bool mode = false;
        // if (tradeFlag == 1 || dividendFlag == 1) {
        //     mode = true;
        // } else {
        //     mode = false;
        // }
        // return mode;
    }
}
