# MaraScan Contract
This contract was written in purpose of a Hackathon. use cautiosly


## Concepts of the MachoMara Contract?
- It is an upgradeable UUPS contract
- Accepts USDC (central cuurency) Token from donor and disbures equally to beneficiaries
- Accepts MATIC from donor, swaps Exact MATIC to USDC and disbures equally to beneficiaries
- Accepts anyother approved tokens and swap Exact Token to USDC and disbures equally to beneficiaries

### Disburesement
```typescript
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
```
Upon disbursement of USDC, an ERC1155 NFT is minted to Donor.

```typescript
    IBadges(BADGE).mintBadge(0, msg.sender, _category);
```
### Thirdparty Contract

- UNISWAPV2ROUTER
- BADGE CONTRACT
