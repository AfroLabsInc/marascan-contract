// SPDX-License-Identifier: GPL-3.0
/**
  
            #     #     #       ######  #     #     #    #######  #     #   #####  ##      #   
            #     #    # #    #         #    #     # #      #     #     # #      # # #     #        
            #######   #####   #         #####     #####     #     ####### #      # #   #   #      
            #     #  #     #  #         #    #   #     #    #     #     # #      # #    #  #         
            #     # #       #  #######  #     # #       #   #     #     #  ######  #      ##    
  @title A Hackathon Project
  @author John Oba  <@johnexzy> and  Anthony Nwobodo <@francosion042>
  @notice This handles Withrawal and Automatic Market Maker with Circle.
  @notice This cotract is not audited and only written for the purpose of a Hackathon, take caution
  */

pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Interface.sol";

contract MaraScanOperations is AccessControl, Initializable {
    bytes4 public constant _TRANSFER_WITH_AUTHORIZATION_SELECTOR = 0xe3ee160e;
    address public MASTER_WALLET;
    /** =====SUPPORTED ROLES======= **/
    bytes32 public constant ADMIN_ROLE = 0x00;

    // ====USDC Contract ADDRESS=====
    address public USDC;

    // ==== EVENTS ====
    event UserWithdrawal(address indexed beneficiary, uint256 amount);

    event CircleTransfer(uint256 amount);
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
        USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
        MASTER_WALLET = msg.sender;
    }

    /**
     * 
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
    ) external onlyMasterWallet returns (bool) {
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
        emit UserWithdrawal(from, value);
        return true;
    }

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
        returns (bool)
    {
        return ERC20(USDC).authorizationState(authorizer, nonce);
    }

    function transferToCircle(address _circleAddress, uint256 amount)
        external
        onlyMasterWallet
    {
        require(
            ERC20(USDC).balanceOf(address(this)) >= amount,
            "Not enough funds"
        );
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
