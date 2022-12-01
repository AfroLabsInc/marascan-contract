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
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IBadges.sol";
import "./Interface.sol";

contract MaraScan is AccessControl, Initializable {
    // uniswap address
    address internal constant UNISWAP_ROUTER_ADDRESS =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant WMATIC = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
    address public constant USDC = 0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747;

    IUniswapV2Router02 public uniswapRouter;
    ISwapRouter public constant swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    address public MASTER_WALLET;
    /** =====SUPPORTED ROLES======= **/
    bytes32 public constant ADMIN_ROLE = 0x00;

    // ===Badge Contract ADDRESS======
    address public BADGE;

    bytes32 private secret;

    uint256 public minimumAmountToDisburse; //
    // Donation[] public unDisbursedDonations;
    Donation[] public allDisbursedDonations;
    Donation[] public unDisbursedDonations;
    uint24 public poolFee;

    uint256 public unDisbursedAmount;
    uint256 public totalAmountDisbursed;
    uint256 public processingFeePercent;

    // ====Acceptable Tokens========
    mapping(address => bool) public approvedTokens;
    mapping(uint256 => uint256) public claimBadgesForDonors;
    mapping(uint256 => BeneficiaryOutput[]) donationRequestBeneficiaries;

    //===== STRUCTS =====
    struct Donation {
        address donor;
        uint256 donationRequestId;
        uint256 amount;
    }

    // Beneficiary Input Details
    struct BeneficiaryInput {
        address beneficiaryAddresses;
        uint256 acresPerBeneficiary;
    }
    struct BeneficiaryOutput {
        address beneficiaryAddresses;
        uint256 amountPerBeneficiary;
    }

    BeneficiaryOutput[] beneficiary;
    // ==== ON-DISBURSED ====
    event Disbursed(Donation donation);

    // ==== DONATION =====
    event Donated(
        address indexed donor,
        uint256 indexed amount,
        uint256 donationRequestId,
        uint256 currentUndisbursedBalance,
        BeneficiaryOutput[] beneficiaries
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
        minimumAmountToDisburse = 500;
        // swapRouter =
        processingFeePercent = 5;
        poolFee = 3000;
        MASTER_WALLET = 0x896f16dfb69d916AeA7315b7455Cc7b5a79157c7;
    }

    /**
     * @notice Disburses the Recieved USDC token and disburse equally to Beneficiaries
     * @param _amount: amount of Token( USDC) to donate
     * @param _donationDetails: list of benefiaries addresses
     */
    function donationFromHook(
        uint256 _amount,
        uint256 _donationRequestId,
        BeneficiaryInput[] calldata _donationDetails,
        uint256 totalNumberOfAcres,
        bool disburse
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

        //transfer fee to contract

        uint256 amountPerAcre = actualAmount / totalNumberOfAcres;

        // BeneficiaryOutput memory beneficiaries = BeneficiaryOutput(address[], uint256[], uint256[]);
        for (uint256 index = 0; index < _donationDetails.length; index++) {
            uint256 amountPerBeneficiary = amountPerAcre *
                _donationDetails[index].acresPerBeneficiary;
            beneficiary.push(
                BeneficiaryOutput(
                    _donationDetails[index].beneficiaryAddresses,
                    amountPerBeneficiary
                )
            );
        }
        // Donation memory donation =
        donationRequestBeneficiaries[_donationRequestId] = beneficiary;
        unDisbursedDonations.push(
            Donation(msg.sender, _donationRequestId, actualAmount)
        );
        emit Donated(
            msg.sender,
            _amount,
            _donationRequestId,
            unDisbursedAmount,
            beneficiary
        );

        // deletes the array
        delete beneficiary;

        if (disburse) {
            _disburseToken();
        }
    }

    /**
     * @dev Recieves USDC token and disburse equally to Beneficiaries
     * @param _amount: amount of Token( USDC) to donate
     * @param _donationDetails: list of benefiaries addresses
     */
    function donate(
        uint256 _amount,
        uint256 _donationRequestId,
        BeneficiaryInput[] calldata _donationDetails,
        uint256 totalNumberOfAcres,
        bytes32 secretKey,
        bool disburse
    ) external {
        require(secretKey == secret, "Unauthorized caller");

        ERC20 token = ERC20(USDC);
        require(
            token.balanceOf(msg.sender) >= _amount,
            "Amount to donate exceeds balance"
        );
        token.transferFrom(msg.sender, address(this), _amount);

        uint256 processingFee = (_amount / 100) * processingFeePercent;

        uint256 actualAmount = _amount - processingFee;
        unDisbursedAmount += actualAmount;

        //transfer fee to contract

        uint256 amountPerAcre = actualAmount / totalNumberOfAcres;

        // BeneficiaryOutput memory beneficiaries = BeneficiaryOutput(address[], uint256[], uint256[]);
        for (uint256 index = 0; index < _donationDetails.length; index++) {
            uint256 amountPerBeneficiary = amountPerAcre *
                _donationDetails[index].acresPerBeneficiary;
            beneficiary.push(
                BeneficiaryOutput(
                    _donationDetails[index].beneficiaryAddresses,
                    amountPerBeneficiary
                )
            );
        }
        // Donation memory donation =
        donationRequestBeneficiaries[_donationRequestId] = beneficiary;
        unDisbursedDonations.push(
            Donation(msg.sender, _donationRequestId, actualAmount)
        );
        emit Donated(
            msg.sender,
            _amount,
            _donationRequestId,
            unDisbursedAmount,
            beneficiary
        );

        // deletes the array
        delete beneficiary;

        if (disburse) {
            _disburseToken();
        }

        // Disburesement
    }

    /**
     * @dev Recieves ETH, Swap to USDC and disburse? equally to Beneficiaries

     */
    function SwapExactETHForTokens(
        uint256 _donationRequestId,
        BeneficiaryInput[] calldata _donationDetails,
        uint256 totalNumberOfAcres,
        bytes32 secretKey,
        bool disburse
    ) external payable {
        require(secretKey == secret, "Unauthorized caller");
        require(msg.value > 0, "Amount too small");

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: WMATIC,
                tokenOut: USDC,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp + 15,
                amountIn: msg.value,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        uint256 swapResult = swapRouter.exactInputSingle{value: msg.value}(
            params
        );

        uint256 processingFee = (swapResult / 100) * processingFeePercent;

        uint256 actualAmount = swapResult - processingFee;
        unDisbursedAmount += actualAmount;
        uint256 amountPerAcre = actualAmount / totalNumberOfAcres;

        // BeneficiaryOutput memory beneficiaries = BeneficiaryOutput(address[], uint256[], uint256[]);
        for (uint256 index = 0; index < _donationDetails.length; index++) {
            uint256 amountPerBeneficiary = amountPerAcre *
                _donationDetails[index].acresPerBeneficiary;
            beneficiary.push(
                BeneficiaryOutput(
                    _donationDetails[index].beneficiaryAddresses,
                    amountPerBeneficiary
                )
            );
        }
        // Donation memory donation =
        donationRequestBeneficiaries[_donationRequestId] = beneficiary;
        unDisbursedDonations.push(
            Donation(msg.sender, _donationRequestId, actualAmount)
        );
        emit Donated(
            msg.sender,
            swapResult,
            _donationRequestId,
            unDisbursedAmount,
            beneficiary
        );

        // deletes the array
        delete beneficiary;

        if (disburse) {
            _disburseToken();
        }
    }

    /**
     * @dev Recieves An Approved Token, Swap to USDC and disburse equally to Beneficiaries
     * @param tokenIn: The Contract address of the Approved Token
     * @param amountIn: amount of Tokens to swap to USDC
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        address tokenIn,
        BeneficiaryInput[] calldata _donationDetails,
        uint256 _donationRequestId,
        uint256 totalNumberOfAcres,
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

        uint256 amountPerAcre = actualAmount / totalNumberOfAcres;

        // BeneficiaryOutput memory beneficiaries = BeneficiaryOutput(address[], uint256[], uint256[]);
        for (uint256 index = 0; index < _donationDetails.length; index++) {
            uint256 amountPerBeneficiary = amountPerAcre *
                _donationDetails[index].acresPerBeneficiary;
            beneficiary.push(
                BeneficiaryOutput(
                    _donationDetails[index].beneficiaryAddresses,
                    amountPerBeneficiary
                )
            );
        }
        // Donation memory donation =
        donationRequestBeneficiaries[_donationRequestId] = beneficiary;
        unDisbursedDonations.push(
            Donation(msg.sender, _donationRequestId, actualAmount)
        );
        emit Donated(
            msg.sender,
            swapResult[1],
            _donationRequestId,
            unDisbursedAmount,
            beneficiary
        );

        // deletes the array
        delete beneficiary;

        _disburseToken();
    }

    function _disburseToken() internal {
        require(unDisbursedAmount >= 0, "No Donation to disburse");
        // uint256 amountPerBeneficiary = _amount / _beneficiaries.length;
        for (uint256 index = 0; index < unDisbursedDonations.length; index++) {
            Donation memory donation = unDisbursedDonations[index];
            for (
                uint256 i = 0;
                i <
                donationRequestBeneficiaries[donation.donationRequestId].length;
                i++
            ) {
                require(
                    ERC20(USDC).transfer(
                        donationRequestBeneficiaries[
                            donation.donationRequestId
                        ][i].beneficiaryAddresses,
                        donationRequestBeneficiaries[
                            donation.donationRequestId
                        ][i].amountPerBeneficiary
                    ),
                    "Unable to transfer token"
                );
            }
            emit Disbursed(donation);
            delete donationRequestBeneficiaries[donation.donationRequestId];
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
