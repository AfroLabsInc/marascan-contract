// SPDX-License-Identifier: GPL-3.0
/**
|     |   /\    /-----\ |  /         |\  /|   /\   |--\    /\   
|_____|  /  \  |        |/           | \/ |  /  \  |_ /   /  \  
|-----| /----\ |        | \          |    | /----\ |  \  /----\ 
|     |/      \ \_____  |   \        |    |/      \|   \/      \ 
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

    /** =====SUPPORTED ROLES======= **/
    /** The Deployer is inherits the admin role */
    bytes32 public constant ADMIN_ROLE = 0x00;

    // ===Badge Contract ADDRESS======
    address public BADGE;

    // ====USDC Contract ADDRESS=====
    address public USDC;

    // ====Acceptable Tokens========
    mapping(address => bool) public approvedTokens;
    // ==== ON-DISBURSED ====
    event Disbursed(
        address indexed donor,
        uint256 amount,
        address[] indexed beneficiaries
    );
    // ==== ON-TOKEN_APPROVAL =====
    event ApproveToken(address indexed contractAddress);

    event ChangedBadgeContract(
        address indexed newContract
    );
    event ChangedUSDCContract(
        address indexed newContract
    );

    function initialize() public initializer {
        _setupRole(ADMIN_ROLE, msg.sender);
        uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
    }

    function donateAndDisburseToken(
        address _tokenAddress,
        uint256 _amount,
        address[] calldata _beneficiaries,
        bytes memory _category
    ) external {
        require(
            _tokenAddress == USDC,
            "This token is not recognised for donation"
        );
        ERC20 token = ERC20(_tokenAddress);
        require(
            token.balanceOf(msg.sender) >= _amount,
            "Amount to donate exceeds balance"
        );

        // send tokens to contract
        // it requires approval
        token.transferFrom(msg.sender, address(this), _amount);

        // Disburesement
        _disburseToken(_tokenAddress, _amount, _beneficiaries, _category);
    }

    function SwapExactETHForTokens(
        uint256 amountOut,
        address[] calldata _beneficiaries,
        bytes memory _category
    ) external payable {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = USDC;
        uniswapRouter.swapExactETHForTokens{value: msg.value}(
            amountOut,
            path,
            address(this),
            block.timestamp + 50
        );

        _disburseToken(
            USDC,
            ERC20(USDC).balanceOf(address(this)),
            _beneficiaries,
            _category
        );
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenIn,
        address[] calldata _beneficiaries,
        bytes memory _category
    ) external payable {
        require(
            approvedTokens[tokenIn],
            "This token is not recognised for donation"
        );
                ERC20 tokenInContract = ERC20(tokenIn);
        require(
            tokenInContract.balanceOf(msg.sender) >= amountIn,
            "Amount to donate exceeds balance"
        );
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = USDC;
        // send tokens to contract
        tokenInContract.transferFrom(msg.sender, address(this), amountIn);

        // approve uniswap router on this token
        tokenInContract.approve(address(uniswapRouter), amountIn);
        uniswapRouter.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            block.timestamp + 50
        );

        _disburseToken(
            USDC,
            ERC20(USDC).balanceOf(address(this)),
            _beneficiaries,
            _category
        );
    }

    function _disburseToken(
        address _tokenAddress,
        uint256 _amount,
        address[] calldata _beneficiaries,
        bytes memory _category
    ) internal {
        uint256 amountPerBeneficiary = _amount / _beneficiaries.length;
        for (uint256 index = 0; index < _beneficiaries.length; index++) {
            require(
                ERC20(_tokenAddress).transfer(
                    _beneficiaries[index],
                    amountPerBeneficiary
                ),
                "Unable to transfer token"
            );
        }
        // Disbursement ends

        // Mint Badge
        IBadges(BADGE).mintBadge(0, msg.sender, _category);
        emit Disbursed(msg.sender, _amount, _beneficiaries);
    }

    function approveTokenForDonation(address _tokenAddress)
        public
        onlyRole(ADMIN_ROLE)
    {
        approvedTokens[_tokenAddress] = true;
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
