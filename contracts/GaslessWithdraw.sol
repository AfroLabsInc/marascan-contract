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

    /**
     * @notice Returns the state of an authorization
     * @dev Nonces are randomly generated 32-byte data unique to the authorizer's
     * address
     * @param authorizer    Authorizer's address
     * @param nonce         Nonce of the authorization
     * @return True if the nonce is used
     */
    function authorizationState(address authorizer, bytes32 nonce)
        external
        view
        returns (bool);

    /**
     * @notice Execute a transfer with a signed authorization
     * @param from          Payer's address (Authorizer)
     * @param to            Payee's address
     * @param value         Amount to be transferred
     * @param validAfter    The time after which this is valid (unix time)
     * @param validBefore   The time before which this is valid (unix time)
     * @param nonce         Unique nonce
     * @param v             v of the signature
     * @param r             r of the signature
     * @param s             s of the signature
     */
    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Receive a transfer with a signed authorization from the payer
     * @dev This has an additional check to ensure that the payee's address matches
     * the caller of this function to prevent front-running attacks. (See security
     * considerations)
     * @param from          Payer's address (Authorizer)
     * @param to            Payee's address
     * @param value         Amount to be transferred
     * @param validAfter    The time after which this is valid (unix time)
     * @param validBefore   The time before which this is valid (unix time)
     * @param nonce         Unique nonce
     * @param v             v of the signature
     * @param r             r of the signature
     * @param s             s of the signature
     */
    function receiveWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

contract USDCWithrawal is AccessControl, Initializable {
    bytes4 public constant _TRANSFER_WITH_AUTHORIZATION_SELECTOR = 0xe3ee160e;
    address public MASTER_WALLET;
    /** =====SUPPORTED ROLES======= **/
    bytes32 public constant ADMIN_ROLE = 0x00;

    // ====USDC Contract ADDRESS=====
    address public USDC;

    // ==== EVENTS ====
    event UserWithdrawal(
        address indexed donor,
        uint256 amount
    );

    event CircleTransfer (
        uint256 amount
    );
    // ==== ON-TOKEN_APPROVAL =====

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
    }

    function _gaslessTransfer(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        ERC20(USDC).transferWithAuthorization(
            from,
            to,
            value,
            validAfter,
            validBefore,
            nonce,
            v,
            r,
            s
        );
    }

    function withdrawFromUser(bytes calldata transferWithAuthorization) external onlyMasterWallet returns (bool){
        (address from, address to, uint256 amount) = abi.decode(
            transferWithAuthorization[0:96],
            (address, address, uint256)
        );
        require(to == address(this), "Recipient is not this contract");

        (bool success, ) = USDC.call(
            abi.encodePacked(
                _TRANSFER_WITH_AUTHORIZATION_SELECTOR,
                transferWithAuthorization
            )
        );
        emit UserWithdrawal(from, amount);
        require(success, "Failed to transfer to the forwarder");

        return success;
    }

    function transferToCircle(address _circleAddress, uint256 amount) external onlyMasterWallet {
        require(ERC20(USDC).balanceOf(address(this)) >= amount, "Not enough funds");
        ERC20(USDC).transfer(_circleAddress, amount);

        emit CircleTransfer(amount);
    }

    function setMasterWallet(address _masterWallet)
        public
        onlyRole(ADMIN_ROLE)
    {
        MASTER_WALLET = _masterWallet;
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
