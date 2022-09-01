// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract MaraScan is AccessControl, Initializable {
    
    event Disbursed (
        address indexed donor,
        uint256 amount,
        address[] indexed beneficiaries
    );
    /** =====SUPPORTED ROLES======= **/
    // USDT address
    address public USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

     /** =====SUPPORTED ROLES======= **/
    /** The Deployer is inherits the admin role */
    bytes32 public constant ADMIN_ROLE = 0x00;

    mapping(address => bool) public approvedTokens;
    
    function initialize() public initializer {
        _setupRole(ADMIN_ROLE, msg.sender);
        approvedTokens[USDT] = true;
    }

    function disburse(address _tokenAddress, uint256 _amount, address[] memory _beneficiaries) external {
        require(approvedTokens[_tokenAddress], 'This token is not recognised for donation');
        require(IERC20(_tokenAddress).balanceOf(msg.sender) >= _amount, 'Amount to donate exceeds balance');

        // logic


        emit Disbursed(msg.sender, _amount, _beneficiaries);
    }


    function emergencyWithdraw() external onlyRole(ADMIN_ROLE) {
        AddressUpgradeable.sendValue(
            payable(msg.sender),
            address(this).balance
        );
    }
}
