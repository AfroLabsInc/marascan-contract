// SPDX-License-Identifier: GPL-3.0
/**
  
  #     #     #       ######  #     #     #######  #     #  #######       ##    ##     #      #####       #      
  #     #    # #    #         #    #         #     #     #  #             # #  # #    # #     #    #     # #           
  #######   #####   #         #####          #     #######  #######       #  ##  #   #####    #####     #####        
  #     #  #     #  #         #    #         #     #     #  #             #      #  #     #   #    #   #     #          
  #     # #       #  #######  #     #        #     #     #  #######       #      # #       #  #     # #       # 
  
  @title A Hack The Mara Hackathon Project
  @author The name of the author
  @notice This handles collections and disbursements of funds as USDC to beneficiaries
  @notice This cotract is not audited and only written for the purpose of a Hackathon, take caution
  */
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IBadges.sol";
import "./Interface.sol";

contract MaraScan is AccessControl, Initializable {
    // uniswap address
    address internal constant UNISWAP_ROUTER_ADDRESS =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 public uniswapRouter;

    address public MASTER_WALLET;
    /** =====SUPPORTED ROLES======= **/
    bytes32 public constant ADMIN_ROLE = 0x00;

    // ===Badge Contract ADDRESS======
    address public BADGE;

    // ====USDC Contract ADDRESS=====
    address public USDC;

    bytes32 private secret;

    uint256 public minimumAmountToDisburse; //
    Donation[] public unDisbursedDonations;
    Donation[] public allDisbursedDonations;
    uint256 public unDisbursedAmount;
    uint256 public totalAmountDisbursed;
    uint256 public processingFeePercent;
    // ====Acceptable Tokens========
    mapping(address => bool) public approvedTokens;
    mapping(uint256 => uint256) public claimBadgesForDonors;
    //===== STRUCTS =====
    struct Donation {
        address donor;
        uint256 donationRequestId;
        uint256 amount;
        Beneficiary beneficiaries;
    }
    struct Beneficiary {
        address[] beneficiaryAddresses;
        uint256[] amount;
    }

    // ==== ON-DISBURSED ====
    event Disbursed(Donation donation);

    // ==== DONATION =====
    event Donated(
        address indexed donor,
        uint256 indexed amount,
        uint256 donationRequestId,
        uint256 currentUndisbursedBalance,
        Beneficiary benefiaries
    );

    // ==== ON-TOKEN_APPROVAL =====
    event ApproveToken(address indexed contractAddress);

    event ChangedBadgeContract(address indexed newContract);
    event ChangedUSDCContract(address indexed newContract);

    // ======= MODIFIERS ==================
    modifier onlyMasterWallet() {
        require(msg.sender == MASTER_WALLET, "Caller is Not a master wallet");
        _;
    }

    /**
     * @dev Entry to application
     * @notice for deployment outside of this setup
     * triger this function ``initialize``, then
     * set the USDC and BADGE addresses by triggering the
     * ``ChangedUSDCContract`` and ``ChangedBadgeContract``
     **/
    function initialize() public initializer {
        _setupRole(ADMIN_ROLE, msg.sender);
        uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        minimumAmountToDisburse = 500;
        USDC = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
        processingFeePercent = 2;
    }

    /**
     * @notice Disburses th Recieved USDC token and disburse equally to Beneficiaries
     * @param _amount: amount of Token( USDC) to donate
     * @param _donationDetails: list of benefiaries addresses
     */
    function donationFromCircle(
        uint256 _amount,
        uint256 _donationRequestId,
        Beneficiary calldata _donationDetails
    ) external onlyMasterWallet {
        ERC20 token = ERC20(USDC);
        require(
            token.balanceOf(address(this)) >= _amount,
            "Amount to donate exceeds balance"
        );

        // calculate processingFee
        uint256 processingFee = (_amount / 100) * processingFeePercent;

        uint256 actualAmount = _amount - processingFee;
        unDisbursedAmount += actualAmount;

        // transfer processingfee to masterwallet
        token.transfer(MASTER_WALLET, processingFee);

        unDisbursedDonations.push(
            Donation(
                msg.sender,
                _donationRequestId,
                actualAmount,
                Beneficiary(
                    _donationDetails.beneficiaryAddresses,
                    _donationDetails.amount
                )
            )
        );

        emit Donated(
            msg.sender,
            _amount,
            _donationRequestId,
            unDisbursedAmount,
            Beneficiary(
                _donationDetails.beneficiaryAddresses,
                _donationDetails.amount
            )
        );

        // Disburesement
    }

    /**
     * @dev Recieves USDC token and disburse equally to Beneficiaries
     * @param _amount: amount of Token( USDC) to donate
     * @param _donationDetails: list of benefiaries addresses
     */
    function donate(
        uint256 _amount,
        uint256 _donationRequestId,
        Beneficiary calldata _donationDetails,
        bytes32 secretKey
    ) external {
        require(secretKey == secret, "Unauthorized caller");

        ERC20 token = ERC20(USDC);
        require(
            token.balanceOf(msg.sender) >= _amount,
            "Amount to donate exceeds balance"
        );

        uint256 processingFee = (_amount / 100) * processingFeePercent;

        uint256 actualAmount = _amount - processingFee;
        unDisbursedAmount += actualAmount;

        //transfer fee to contract
        token.transferFrom(msg.sender, address(this), actualAmount);
        // token.transferFrom(msg.sender, address(this), _amount);

        unDisbursedAmount += actualAmount;
        unDisbursedDonations.push(
            Donation(
                msg.sender,
                _donationRequestId,
                actualAmount,
                Beneficiary(
                    _donationDetails.beneficiaryAddresses,
                    _donationDetails.amount
                )
            )
        );

        emit Donated(
            msg.sender,
            _amount,
            _donationRequestId,
            unDisbursedAmount,
            Beneficiary(
                _donationDetails.beneficiaryAddresses,
                _donationDetails.amount
            )
        );
        // _disburseToken();
        // Disburesement
    }

    /**
     * @dev Recieves ETH, Swap to USDC and disburse? equally to Beneficiaries
     * @param amountOut: Minimum amount of USDC to receive
     */
    function SwapExactETHForTokens(
        uint256 amountOut,
        uint256 _donationRequestId,
        Beneficiary calldata _donationDetails,
        bytes32 secretKey
    ) external payable {
        require(secretKey == secret, "Unauthorized caller");
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = USDC;
        uint256[] memory swapResult = uniswapRouter.swapExactETHForTokens{
            value: msg.value
        }(amountOut, path, address(this), block.timestamp + 50);

        uint256 processingFee = (swapResult[1] / 100) * processingFeePercent;

        uint256 actualAmount = swapResult[1] - processingFee;
        unDisbursedAmount += actualAmount;

        unDisbursedDonations.push(
            Donation(
                msg.sender,
                _donationRequestId,
                actualAmount,
                Beneficiary(
                    _donationDetails.beneficiaryAddresses,
                    _donationDetails.amount
                )
            )
        );

        emit Donated(
            msg.sender,
            swapResult[1],
            _donationRequestId,
            unDisbursedAmount,
            Beneficiary(
                _donationDetails.beneficiaryAddresses,
                _donationDetails.amount
            )
        );
    }

    /**
     * @dev Recieves An Approved Token, Swap to USDC and disburse equally to Beneficiaries
     * @param tokenIn: The Contract address of the Approved Token
     * @param amountIn: amount of Tokens to swap to USDC
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        address tokenIn,
        Beneficiary calldata _donationDetails,
        uint256 _donationRequestId,
        // bool disburse,
        bytes32 secretKey
    ) external {
        require(secretKey == secret, "Unauthorized caller");
        require(
            approvedTokens[tokenIn],
            "This token is not recognised for donation"
        );
        ERC20 thisContract = ERC20(tokenIn);
        require(
            thisContract.balanceOf(msg.sender) >= amountIn,
            "Amount to donate exceeds balance"
        );
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = USDC;
        // send tokens to contract
        thisContract.transferFrom(msg.sender, address(this), amountIn);

        // approve uniswap router on this token
        thisContract.approve(address(uniswapRouter), amountIn);
        uint256[] memory swapResult = uniswapRouter.swapExactTokensForTokens(
            amountIn,
            10,
            path,
            address(this),
            block.timestamp + 50
        );

        uint256 processingFee = (swapResult[1] / 100) * processingFeePercent;

        uint256 actualAmount = swapResult[1] - processingFee;
        unDisbursedAmount += actualAmount;

        unDisbursedDonations.push(
            Donation(
                msg.sender,
                _donationRequestId,
                actualAmount,
                Beneficiary(
                    _donationDetails.beneficiaryAddresses,
                    _donationDetails.amount
                )
            )
        );
        emit Donated(
            msg.sender,
            swapResult[1],
            _donationRequestId,
            unDisbursedAmount,
            Beneficiary(
                _donationDetails.beneficiaryAddresses,
                _donationDetails.amount
            )
        );
    }

    function _disburseToken() internal {
        require(unDisbursedAmount >= 0, "No Donation to disburse");
        // uint256 amountPerBeneficiary = _amount / _beneficiaries.length;
        for (uint256 index = 0; index < unDisbursedDonations.length; index++) {
            Donation memory donation = unDisbursedDonations[index];
            for (
                uint256 i = 0;
                index < donation.beneficiaries.beneficiaryAddresses.length;
                index++
            ) {
                require(
                    ERC20(USDC).transfer(
                        donation.beneficiaries.beneficiaryAddresses[i],
                        donation.beneficiaries.amount[i]
                    ),
                    "Unable to transfer token"
                );
            }
            emit Disbursed(donation);
        }

        for (uint256 index = 0; index < unDisbursedDonations.length; index++) {
            allDisbursedDonations.push(unDisbursedDonations[index]);
        }

        uint256 balance = ERC20(USDC).balanceOf(address(this));
        // transfer accumulated processingFee
        ERC20(USDC).transfer(MASTER_WALLET, balance);
        // increment the totalAmountDisbursed
        totalAmountDisbursed += unDisbursedAmount;
        unDisbursedAmount = 0;
        delete unDisbursedDonations;
        // Disbursement ends
    }

    function disburseToken() external onlyMasterWallet {
        _disburseToken();
    }

    // Claim Badge
    function claimBadge(uint256 donationRequestId) public {
        require(
            claimBadgesForDonors[donationRequestId] > 0,
            "You don't have any clamis"
        );

        //  mint badge
        IBadges(BADGE).mintBadge(
            0,
            msg.sender,
            claimBadgesForDonors[donationRequestId]
        );

        claimBadgesForDonors[donationRequestId] = 0;
    }

    function setProcessingFee(uint256 _fee) public onlyRole(ADMIN_ROLE) {
        processingFeePercent = _fee;
    }

    function setSecretKey(bytes32 _secret) public onlyRole(ADMIN_ROLE) {
        secret = _secret;
    }

    function approveTokenForDonation(address _tokenAddress)
        public
        onlyRole(ADMIN_ROLE)
    {
        approvedTokens[_tokenAddress] = true;
    }

    function setMasterWallet(address _masterWallet)
        public
        onlyRole(ADMIN_ROLE)
    {
        MASTER_WALLET = _masterWallet;
    }

    function setBadgeTokenContract(address _tokenAddress)
        public
        onlyRole(ADMIN_ROLE)
    {
        BADGE = _tokenAddress;
        emit ChangedBadgeContract(_tokenAddress);
    }

    function setUSDCTokenContract(address _tokenAddress)
        public
        onlyRole(ADMIN_ROLE)
    {
        USDC = _tokenAddress;
        emit ChangedUSDCContract(_tokenAddress);
    }

    // ===============WITHDRAW FUNCTIONS========================
    function emergencyWithdrawETH() external onlyRole(ADMIN_ROLE) {
        AddressUpgradeable.sendValue(
            payable(msg.sender),
            address(this).balance
        );
    }

    function emergencyWithdrawToken(address _tokenAddress)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(
            ERC20(_tokenAddress).balanceOf(address(this)) > 0,
            "Value too small"
        );

        ERC20(_tokenAddress).transfer(
            msg.sender,
            ERC20(_tokenAddress).balanceOf(address(this))
        );
    }
}
