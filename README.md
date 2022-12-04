
<h1>Project Description</h1>

<h2> Name:  MachoMara </h2>
<h2> Category: Web3 Integration in Web2 </h2>

## Slide Deck : [here](https://docs.google.com/presentation/d/1ZcrDpnI7wHyt1MfqeaDxfkgZHud0lSVnMsjn9DFSRjQ/edit?usp=sharing)
### Problem Statement

The Masai Mara people are very conservative in nature, with most of them relying on agricultural activities like farming or keeping livestock, only few are educated.
Landowners, wildlife, and tourism all rely on one another to survive in the Masai Mara. The effects of COVID-19 have halted travel, jeopardized prior earnings, and raised concerns about the stability of the ecosystem.
To generate cash and protect the land for the conservation of wildlife, the Masai people lease their land to conservancies. Tourism businesses that profit from eco-tourism are granted licenses to use the land. One of the most inventive and successful conservation techniques in Africa may be essentially destroyed if individual conservancy landowners are driven to sell or convert their parcels of land to agriculture due to decreased or uncertain lease payments.

International organizations are contributing money to a global program of support for this vulnerable ecosystem in order to lessen the strain caused by lost revenue. However, donors are concerned that the monies may not reach the intended recipients due to low technological advancement, internet access and absence of a verifiable financial system to bridge the gap between the donors and the beneficiaries.

### Our Solution

![20220921_140007#1](https://user-images.githubusercontent.com/45284758/205490656-67cc9e36-1bf1-4e1b-98c0-0290225e23c4.jpeg)

MachoMara, coined from the Swahili word Macho and Mara which means “Eyes of Mara” is a Decentralised Donation platform that takes advantage the Security and Transparency of the Blockchain technology to provide a secure, fast and verifiable channel for individual and organization donors to donate to the course of preserving our wildlife.
By integrating AML and identity check), we guarantee secure transactions from credible donors and beneficiaries, thereby ensuring that our platform is not a channel for fraudulent activities.
MachoMara, unlike various De-Fi and traditional donation platforms already existing, utilizes USSD and M-Pesa to provide last-mile payment service to the beneficiaries, this successfully bridges the gap hindering the adoption of Blockchain in remote parts of Africa, especially the Masai Mara.

### MachoMara - Blockchain in Wildlife Preservation

One of the challenges facing conservancies and individual land owners is lack of adequate funding, and that is not entirely because there are no donations coming, but also because of the cost of getting the donations across to the intended beneficiaries. 
Using traditional systems, donors will have to rely on various agencies and organizations who act as middlemen. The major role of these middlemen is, but not limited to, serving as channels between the donors and the beneficiaries. This comes with a huge cost, and also creates room for concerns, especially in respect to transparency and accountability.  
With the use of Blockchain, MachoMara has created a transparent, cost efficient link between the donors, regardless of their country, and the beneficiaries. We partner with the conservancies to curate a record of the individual land owners and some other key players in the ecosystem who form the beneficiaries.
## Interesting concepts about MachoMara
- Last Mile Payment using USSD protocols
- Implemented Gasless Withdrawals and Transfers for USSD to improve ux
- Accepts Wide range of tokens and settles all in Stable coin USDC
- Accepts Donations with card (fiat) and settles in USDC.
- Crypto Donations are disbursed in real time using our smart contracts
- Implemented AML and KYC standards for Donors and Beneficiaries 
# Tech Stack & Tools
### Smart Contract
- Language: Solidity 
- Framework: Hardhat
- Network: Polygon Mainnet
- Tools and Libraries: Uniswap V3, Open Zeppelin, Alchemy RPCs
- Interesting Concept: Gasless Transfer/Withdrawal using EIP:3009 transfer with Authoirization 

### Backend and Indexer
- Language: Typescript
- Framework: Adonisjs
- Tools for USSD & SMS: Africas Talking SDK

### USSD & SMS
- Africas Talking
### Frontend dApp
- Vuejs, Typescrypt
### Crypto-Fiat Conversion
- Circle API
- AWS SNS Notifiers

## Other relevant repositories
- [https://github.com/AfroLabsInc/marascan-fe](https://github.com/AfroLabsInc/marascan-fe)
- [https://github.com/AfroLabsInc/MaraScan-Backend](https://github.com/AfroLabsInc/MaraScan-Backend)
#
# Guide on Product use

 ## [Video Demo presentation](https://youtu.be/yQm133X3iyg)
[![Step Image](https://img.youtube.com/vi/yQm133X3iyg/0.jpg)](https://www.youtube.com/watch?v=yQm133X3iyg)
 # MachoMara has two windows for access, the web DApp and the offline USSD Interface for beneficiaries
<div style="text-align: center">
<img  src="https://github.com/AfroLabsInc/marascan-fe/blob/main/public/img/Screenshot%202022-09-25%20at%205.12.45%20PM.png?raw=true" />
</div>

## The web onboarding process for Donors is divided into two parts, Organization and Individual Donor. 
<div style="text-align: center">
<img src="https://github.com/AfroLabsInc/marascan-fe/blob/main/public/img/step1.png?raw=true" />
</div>

when the user clicks on either the Organization or Individual account setup, it takes them to the respective onboarding form for their type. 
the onboarding flow for either organization or individual account has 3 steps

 - account creation, which can be done either with traditional email and password or by just connecting your wallet.
 - profile update
 - KYC submission and approval.
<div style="text-align: center">
<img src="https://github.com/AfroLabsInc/marascan-fe/blob/main/public/img/step2.png?raw=true" />
</div>
The login can be done with email and password or by connecting wallet.
<div style="text-align: center">
<img src="https://github.com/AfroLabsInc/marascan-fe/blob/main/public/img/step3.png?raw=true" />
</div>
    
 ## After the onboarding or login, you'll be taken to the dashboard, on the dashboard you'll see:
 - the donor's donation table and the state of it's disbursement
 - Marascan: a realtime exlorer that shows all donations and their status of disbursement. 
<div style="text-align: center">
<img src="https://github.com/AfroLabsInc/marascan-fe/blob/main/public/img/step4.png?raw=true" />
</div>
On the dashboard, the donor can click on the donate button to begin donation process.
we accept both crypo and fiat (through Card) 
<div style="text-align: center">
<img src="https://github.com/AfroLabsInc/marascan-fe/blob/main/public/img/step5.png?raw=true" />
</div>
if the donor dicides to go with crypto, they will fill a for to create a donation request.
we accept multiple crypto tokens which our contract swaps for USDC to avoid loss due to volatility.

<div style="text-align: center">
<img src="https://github.com/AfroLabsInc/marascan-fe/blob/main/public/img/step6.png?raw=true" />
</div>
otherwise, if the donor chooses to donate with card, they'll have this form to enter their card details if they haven't created any card already.
after entering card details and creating card, they can proceed to donate.
<div style="text-align: center">
<img src="https://github.com/AfroLabsInc/marascan-fe/blob/main/public/img/step7.png?raw=true" />
</div>
This is now to confirm donation details and confirm payment.
<div style="text-align: center">
<img src="https://github.com/AfroLabsInc/marascan-fe/blob/main/public/img/step8.png?raw=true" />
</div> 

<div style="text-align: center">
<img src="https://github.com/AfroLabsInc/marascan-fe/blob/main/public/img/step9.png?raw=true" />
</div>  
    
 ##  Here's the Beneficiary window which is an offline ussd interface for the rural/native people to access the donations :
 - Link to Simulator : https://developers.africastalking.com/simulator
 - USSD code : *384*39111# 
### You can use the following details to access a pre-registered account in other to skip the reagistration steps
 - Beneficiary: +234 903 485 3719
 - Password to account : 1234567890

<div style="text-align: center">
<img src="https://github.com/AfroLabsInc/marascan-fe/blob/main/public/img/step10.png?raw=true" />
</div>  
<div style="text-align: center">
<img src="https://github.com/AfroLabsInc/marascan-fe/blob/main/public/img/step11.png?raw=true" />
</div>  

<div style="text-align: center">
<img src="https://github.com/AfroLabsInc/marascan-fe/blob/main/public/img/step12.png?raw=true" />
</div>  
<div style="text-align: center">
<img src="https://github.com/AfroLabsInc/marascan-fe/blob/main/public/img/step13.png?raw=true" />
</div>  

 <div style="text-align: center">
<img src="https://github.com/AfroLabsInc/marascan-fe/blob/main/public/img/step14.png?raw=true" />
</div>  

