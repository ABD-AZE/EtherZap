# Introduction


EtherZap showcases our proof of concept (POC) designed to address a significant challenge in decentralized applications: the burden of gas fees on user interactions. Our aim is to demonstrate a more user-friendly model that enhances engagement.

# User Flow


![image](https://github.com/user-attachments/assets/76c893cc-198a-450d-90d7-70f088abc6ab)

# Sponsor Flow 


![EtherZapSponsor drawio (4)](https://github.com/user-attachments/assets/8faaf4ad-ec83-4c81-8a23-6412c3497705)

# Our Model 
Etherzap introduces a unique model where sponsors can run ads on the platform, providing users with a choice during their interactions. Users can either watch an ad to enable a gasless transaction or proceed by covering the gas fee themselves. By leveraging ERC-4337 (account abstraction), Etherzap covers the gas fees for users who opt to watch ads—users simply sign a message, and we take care of the rest. Ads are hosted on IPFS, while our ad manager smart contracts track ad impressions, ensuring accurate billing and maintaining sponsor trust through transparent and timely charges.

# Our Vision 

Our future vision is to develop an SDK that can be seamlessly integrated into any dApp, allowing them to implement Etherzap's ad-based gasless transaction model. Additionally, we plan to introduce Web2-based signups, enabling users to sign user operations using familiar methods like passkeys or other Web2 login options. This will significantly simplify onboarding, making Web3 more accessible to a broader audience.

# Why Base?

We use Base, an L2 solution, for sending transactions because of its lower gas fees, which allow us to cover gas costs for more users with the same funds. Additionally, Base offers faster transaction speeds, making it an ideal choice for our platform's efficiency and scalability.

# Quickstart
clone the repo 
```
cromewar@ujjwal:~/aa-integration/AccountAbstractionScript$ node index.js 
```
```
npm install 
```
```
cd Dashboard
```
```
npm run dev  
```











## Contract Addresses 

### Base Sepolia 

#### Decentralised Social Media - 0x859Bb215897ED323508155c212fe6B30Cc895da4
#### User Manager - 0xb76374Ca7313c9D770FC3901F9c4d831F877D521
#### ZapAccountFactory - 0xA3239e7354016c79fa873eB211EDA5Cf214Ca13b
#### ZapPaymaster - 0xBC5ee9e1888037abF7B595bbD7031d50f586F657
#### Temporary_Account_1 - 0x500219588BaD072DE8213d1A813a704b478697fa
#### Temporary_Account_2 - 0xE17d3c87B0903E9D05BbB3D07c2626Bb841b17d6
#### Owner - 0xbFFCa66179510D6C0CE3C2737b1942BF3f964519


