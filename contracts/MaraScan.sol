// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IBadges.sol";
contract MaraScan is AccessControl, Initializable {
    event Disbursed(
        address indexed donor,
        uint256 amount,
        address[] indexed beneficiaries
    );
    /** =====SUPPORTED TOKENS======= **/
    // USDT address
    address public USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    /** =====SUPPORTED ROLES======= **/
    /** The Deployer is inherits the admin role */
    bytes32 public constant ADMIN_ROLE = 0x00;
      
    // ===Badge Contract ======
    address public BADGE = 0xdAC17F958D2ee523a2206206994597C13D831ec7; 


    mapping(address => bool) public approvedTokens;

    function initialize() public initializer {
        _setupRole(ADMIN_ROLE, msg.sender);
        approvedTokens[USDT] = true;
    }

    function disburse(
        address _tokenAddress,
        uint256 _amount,
        address[] calldata _beneficiaries,
        bytes memory _category
    ) external {
        require(
            approvedTokens[_tokenAddress],
            "This token is not recognised for donation"
        );
        ERC20 token = ERC20(_tokenAddress);
        require(
            token.balanceOf(msg.sender) >= _amount,
            "Amount to donate exceeds balance"
        );
        
        // send tokens to contract
        token.transferFrom(msg.sender, address(this), _amount);

        // Disburesement Logic Begins
        uint256 amountPerBeneficiary = _amount / _beneficiaries.length;
        for (uint256 index = 0; index < _beneficiaries.length; index++) {
            require(
                token.transfer(_beneficiaries[index], amountPerBeneficiary),
                string.concat("Unable to transfer ", token.symbol())
            );
        }
        // Disbursement ends

        // Mint Badge
        IBadges(BADGE).mintBadge(0, msg.sender, _category);
        emit Disbursed(msg.sender, _amount, _beneficiaries);
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

        ERC20(_tokenAddress).transfer(msg.sender, ERC20(_tokenAddress).balanceOf(address(this)));
    }
}
