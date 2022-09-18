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

interface IUniswapV2Router02 {
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function WETH() external pure returns (address);
}

interface ERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

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

    uint256 public minimumAmountToDisburse; //
    Donation[] public unDisbursedDonations;
    Donation[] public allDisbursedDonations;
    uint256 public unDisbursedAmount;
    uint256 public totalAmountDisbursed;
    // ====Acceptable Tokens========
    mapping(address => bool) public approvedTokens;
    mapping(uint256 => uint256) public claimBadgesForDonors;
    //===== STRUCTS =====
    struct Donation {
        address donor;
        uint256 donationRequestId;
        uint256 amount;
        uint256[] categories;
        Beneficiary[] beneficiaries;
    }
    struct Beneficiary {
        address beneficiary;
        uint256 amount;
    }
    // ==== ON-DISBURSED ====
    event Disbursed(Donation donation);

    // ==== DONATION =====
    event Donated(
        address indexed donor,
        uint256 indexed amount,
        uint256 donationRequestId,
        uint256 previousUndisbursedBalance,
        uint256 currentUndisbursedBalance,
        uint256[] indexed categories,
        uint256 minimumAmountToDisburse,
        Beneficiary[] benefiaries
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
    }

    /**
     * @notice Disburses th Recieved USDC token and disburse equally to Beneficiaries
     * @param _amount: amount of Token( USDC) to donate
     * @param _beneficiaries: list of benefiaries addresses
     * @param _category: Category of benefiaries
     */
    function donationFromCircle(
        uint256 _amount,
        uint256 _donationRequestId,
        Beneficiary[] calldata _beneficiaries,
        uint256[] calldata _category,
        bool disburse
    ) external onlyMasterWallet {
        ERC20 token = ERC20(USDC);
        require(
            token.balanceOf(address(this)) >= _amount,
            "Amount to disburse exceeds balance"
        );

        uint256 previousUndisbursedBalance = unDisbursedAmount;
        unDisbursedAmount += _amount;

        emit Donated(
            msg.sender,
            _amount,
            _donationRequestId,
            previousUndisbursedBalance,
            unDisbursedAmount,
            _category,
            minimumAmountToDisburse,
            _beneficiaries
        );
        claimBadgesForDonors[_donationRequestId] =
            claimBadgesForDonors[_donationRequestId] +
            1;
        unDisbursedDonations.push(
            Donation(
                msg.sender,
                _donationRequestId,
                _amount,
                _category,
                _beneficiaries
            )
        );
        if (disburse) {
            _disburseToken(unDisbursedDonations);
        }
        // Disburesement
    }

    /**
     * @dev Recieves USDC token and disburse equally to Beneficiaries
     * @param _tokenAddress: The Contract address of USDC
     * @param _amount: amount of Token( USDC) to donate
     * @param _beneficiaries: list of benefiaries addresses
     * @param _category: Category of benefiaries
     */
    function donate(
        address _tokenAddress,
        uint256 _amount,
        uint256 _donationRequestId,
        Beneficiary[] calldata _beneficiaries,
        uint256[] calldata _category,
        bool disburse
    ) external {
        require(
            _tokenAddress == USDC,
            "This token is not recognised for donation"
        );
        ERC20 token = ERC20(USDC);
        require(
            token.balanceOf(msg.sender) >= _amount,
            "Amount to donate exceeds balance"
        );

        // send tokens to contract
        // it requires approval

        token.transferFrom(msg.sender, address(this), _amount);
        uint256 previousUndisbursedBalance = unDisbursedAmount;
        unDisbursedAmount += _amount;

        unDisbursedDonations.push(
            Donation(
                msg.sender,
                _donationRequestId,
                _amount,
                _category,
                _beneficiaries
            )
        );

        // //  mint badge
        // // IBadges(BADGE).mintBadge(0, msg.sender, 1);
        emit Donated(
            msg.sender,
            _amount,
            _donationRequestId,
            previousUndisbursedBalance,
            unDisbursedAmount,
            _category,
            minimumAmountToDisburse,
            _beneficiaries
        );
        if (disburse) {
            _disburseToken(
                unDisbursedDonations
            );
        }
        // Disburesement
    }

    /**
     * @dev Recieves ETH, Swap to USDC and disburse? equally to Beneficiaries
     * @param amountOut: Minimum amount of USDC to receive
     * @param _beneficiaries: list of benefiaries addresses
     * @param _category: Category of benefiaries
     */
    function SwapExactETHForTokens(
        uint256 amountOut,
        Beneficiary[] calldata _beneficiaries,
        uint256 _donationRequestId,
        uint256[] calldata _category,
        bool disburse
    ) external payable {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = USDC;
        uint256[] memory swapResult = uniswapRouter.swapExactETHForTokens{
            value: msg.value
        }(amountOut, path, address(this), block.timestamp + 50);

        uint256 previousUndisbursedBalance = unDisbursedAmount;
        unDisbursedAmount += swapResult[1];
        unDisbursedDonations.push(
            Donation(
                msg.sender,
                _donationRequestId,
                swapResult[1],
                _category,
                _beneficiaries
            )
        );

        emit Donated(
            msg.sender,
            swapResult[1],
            _donationRequestId,
            previousUndisbursedBalance,
            unDisbursedAmount,
            _category,
            minimumAmountToDisburse,
            _beneficiaries
        );
        // // Disburesement
        if (disburse) {
            _disburseToken(unDisbursedDonations);
        }
    }

    /**
     * @dev Recieves An Approved Token, Swap to USDC and disburse equally to Beneficiaries
     * @param tokenIn: The Contract address of the Approved Token
     * @param amountIn: amount of Tokens to swap to USDC
     * @param amountOutMin: Minimum amount of USDC to receive
     * @param _beneficiaries: list of benefiaries addresses
     * @param _category: Category of benefiaries
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenIn,
        Beneficiary[] calldata _beneficiaries,
        uint256[] calldata _category,
        uint256 _donationRequestId,
        bool disburse
    ) external {
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
            amountOutMin,
            path,
            address(this),
            block.timestamp + 50
        );
        uint256 previousUndisbursedBalance = unDisbursedAmount;
        unDisbursedAmount += swapResult[1];
        unDisbursedDonations.push(
            Donation(
                msg.sender,
                _donationRequestId,
                swapResult[1],
                _category,
                _beneficiaries
            )
        );
        // mint badge
        // IBadges(BADGE).mintBadge(0, msg.sender, 1);
        emit Donated(
            msg.sender,
            swapResult[1],
            _donationRequestId,
            previousUndisbursedBalance,
            unDisbursedAmount,
            _category,
            minimumAmountToDisburse,
            _beneficiaries
        );
        // Disburesement
        if (disburse) {
            _disburseToken(
                unDisbursedDonations
            );
        }
    }

    function disburseToken() external onlyMasterWallet() {
        require(unDisbursedAmount >= 0, "No Donation to disburse");
        // uint256 amountPerBeneficiary = _amount / _beneficiaries.length;
        for (uint256 index = 0; index < unDisbursedDonations.length; index++) {
            Donation storage donation = unDisbursedDonations[index];
            for (
                uint256 i = 0;
                index < donation.beneficiaries.length;
                index++
            ) {
                require(
                    ERC20(USDC).transfer(
                        donation.beneficiaries[i].beneficiary,
                        donation.beneficiaries[i].amount
                    ),
                    "Unable to transfer token"
                );
            }
            emit Disbursed(donation);
        }

        

        for (uint256 index = 0; index < unDisbursedDonations.length; index++) {
            allDisbursedDonations.push(unDisbursedDonations[index]);
        }

        // increment the totalAmountDisbursed
        totalAmountDisbursed += unDisbursedAmount;
        unDisbursedAmount = 0;
        delete unDisbursedDonations;
        // Disbursement ends
    }

        function _disburseToken(Donation[] storage donations) internal {
        // uint256 amountPerBeneficiary = _amount / _beneficiaries.length;
        for (uint256 index = 0; index < donations.length; index++) {
            Donation storage donation = donations[index];
            for (
                uint256 i = 0;
                index < donation.beneficiaries.length;
                index++
            ) {
                require(
                    ERC20(USDC).transfer(
                        donation.beneficiaries[i].beneficiary,
                        donation.beneficiaries[i].amount
                    ),
                    "Unable to transfer token"
                );
            }
            emit Disbursed(donation);
        }

        

        for (uint256 index = 0; index < donations.length; index++) {
            allDisbursedDonations.push(donations[index]);
        }

        // increment the totalAmountDisbursed
        totalAmountDisbursed += unDisbursedAmount;
        unDisbursedAmount = 0;
        delete unDisbursedDonations;
        // Disbursement ends
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
