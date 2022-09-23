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
        USDC = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
        MASTER_WALLET = 0xF10dc6fee78b300A5B3AB9cc9470264265a2d6Af;
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
