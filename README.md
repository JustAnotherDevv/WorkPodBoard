# WorkPodBoard

## Inspiration
I was fed up with WEB2 freelancing solutions especially because of fees, lack of transparency, and limited protection offered by traditional freelancing platforms. I wanted to try creating one myself using Clarity, It was really important for me that solution has to be **truly decentralized**.

## What it does
WorkPodBoard is freelancer marketplace created using Clarity smart contracts is a decentralized platform that allows freelancers and clients to connect and collaborate on projects securely and transparently. It utilizes the power of blockchain technology to create a secure and immutable record of all transactions, including project proposals, agreements, and payments.

Clients can create jobs using metadata uploaded to decentralized storage(IPFS) and include data hash in job posting using example data format(could be extended if needed, final structure of the IPFS metadata is only limited by UIs for the platform)
```JSON
{
  "Title": "",
  "Description": "",
  "Image": "",
  "category": "",
  "tags": [],
  "creator": "",
  "mail": "",
  "date-created": "",
  "date-expires": ""
}
```
### Currently implemented features:
-Adding job
-Fetching amount of available jobs
-Fetching job details by id
-Changing job status
-Giving user review
-Fetching user reviews

## How we built it
I have contained all of the functions in just 1 contract for simplicity. 

[Github repo](https://github.com/JustAnotherDevv/WorkPodBoard)

## Challenges we ran into
I have only created smart contracts in Solidity before so learning Clarity from scratch was a challenge because of completely different syntax.

## Accomplishments that we're proud of & What we learned
I am proud that I was eventually able to complete the project even though there weren't that many Clarity resources and examples online. Learning how to create something in Clarity from scratch was interesting experience indeed.

## What's next for WorkPodBoard
-Escrow: adding it could allow for the automation of certain tasks and processes, such as the release of payments upon project completion.
-UI: For actual production use WorkPodBoard needs to have dApp that interacts with smart contracts deployed on-chain.
-Document sharing: additional smart contract supporting sharing of private information with workers could allow for better user experience and streamline the freelancing process.
-Dispute resolution: in the real world something could always go wrong during work process so it's important to factor those situations in and add dispute resolution with management dashboard with arbitrators or DAO voting who should receive the funds from the escrow.
