import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types,
} from "https://deno.land/x/clarinet@v1.2.0/index.ts";
import { assertEquals } from "https://deno.land/std@0.90.0/testing/asserts.ts";

/*
  Errors

(err u100)) - Jobs does not exist or has different id
(err u101)) - Invalid variable value was given 
(err u102)) - The given string is not a valid IPFS hash because it's too short
(err u103)) - Selected job has no proposals yet
(err u104)) - Proposal list for selected job is full(20 proposals)
(err u105)) - User who's not permitted to call function tried to use it
(err u106)) - Review does not exist or has different id
*/

const mainContract = "work-board";

Clarinet.test({
  name: "Ensure that <...>",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let block = chain.mineBlock([
      /*
       * Add transactions with:
       * Tx.contractCall(...)
       */
    ]);
    assertEquals(block.receipts.length, 0);
    assertEquals(block.height, 2);

    block = chain.mineBlock([
      /*
       * Add transactions with:
       * Tx.contractCall(...)
       */
    ]);
    assertEquals(block.receipts.length, 0);
    assertEquals(block.height, 3);
  },
});

Clarinet.test({
  name: "Checking if errors are thrown if user tries to access data before any job posts are added",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let deployer = accounts.get("deployer")!;

    let block = chain.mineBlock([
      // 0 - Getting amount of jobs
      Tx.contractCall(mainContract, "get-amount-of-jobs", [], deployer.address),
      // 1 - Getting amount of reviews
      Tx.contractCall(
        mainContract,
        "get-amount-of-reviews",
        [],
        deployer.address
      ),
      // 2 - Getting job by id
      Tx.contractCall(
        mainContract,
        "get-job-by-id",
        [types.uint(0)],
        deployer.address
      ),
      // 3 - Getting proposals for a job by id
      Tx.contractCall(
        mainContract,
        "get-proposals-by-id",
        [types.uint(0)],
        deployer.address
      ),
      // 4 - Getting reviews by id
      Tx.contractCall(
        mainContract,
        "get-review-by-id",
        [types.uint(0)],
        deployer.address
      ),
    ]);

    // Get transaction receipt
    let receipts = block.receipts;

    // Assert that the returned results have expected values
    // 0 - Getting amount of jobs should return 0
    receipts[0].result.expectOk().expectUint(0);
    // 1 - Getting amount of reviews should return 0
    receipts[1].result.expectOk().expectUint(0);
    // 2 - Getting job by id should fail
    receipts[2].result.expectErr().expectUint(100);
    // 3 - Getting proposals for a job by id should fail
    receipts[3].result.expectErr().expectUint(100);
    // 4 - Getting reviews by id should fail
    receipts[4].result.expectErr().expectUint(106);
  },
});

Clarinet.test({
  name: "Adding job posts, testing if errors are thrown for incorrect values",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let deployer = accounts.get("deployer")!;

    let block = chain.mineBlock([
      // 0 - Adding job with empty string
      Tx.contractCall(
        mainContract,
        "add-job",
        [types.uint(10), types.ascii("")],
        deployer.address
      ),
      // 1 - Adding job with payment set to 0
      Tx.contractCall(
        mainContract,
        "add-job",
        [
          types.uint(0),
          types.ascii("QmTJm7rW9nDWb6wBDzokTpeCtXVQb6mYqBeDaEvznAuWLP"),
        ],
        deployer.address
      ),
    ]);

    // Get transaction receipt
    let receipts = block.receipts;

    // Assert that the returned results have expected values
    // 0 - Getting amount of jobs should return 0 should fail
    receipts[0].result.expectErr().expectUint(102);
    // 1 - Adding job with payment set to 0 should fail
    receipts[1].result.expectErr().expectUint(101);
  },
});

Clarinet.test({
  name: "Adding job posts and proposals with correct & incorrect information",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    // Get some accounts
    let deployer = accounts.get("deployer")!;
    let wallet1 = accounts.get("wallet_1")!;
    let wallet2 = accounts.get("wallet_2")!;

    let block = chain.mineBlock([
      // 0 - Adding job with correct example data
      Tx.contractCall(
        mainContract,
        "add-job",
        [
          types.uint(10),
          types.ascii("QmTJm7rW9nDWb6wBDzokTpeCtXVQb6mYqBeDaEvznAuWLP"),
        ],
        deployer.address
      ),
      // 1 - Getting amount of jobs
      Tx.contractCall(mainContract, "get-amount-of-jobs", [], deployer.address),
      // 2 - Getting job by id
      Tx.contractCall(
        mainContract,
        "get-job-by-id",
        [types.uint(0)],
        deployer.address
      ),
      // 3 - Getting proposals for a job by id
      Tx.contractCall(
        mainContract,
        "get-proposals-by-id",
        [types.uint(0)],
        deployer.address
      ),
      // 4 - Adding proposal as a job post creator
      Tx.contractCall(
        mainContract,
        "add-proposal",
        [
          types.uint(0),
          types.ascii("QmTJm7rW9nDWb6wBDzokTpeCtXVQb6mYqBeDaEvznAuWLP"),
        ],
        deployer.address
      ),
      // 5 - Adding proposal as different user
      Tx.contractCall(
        mainContract,
        "add-proposal",
        [
          types.uint(0),
          types.ascii("QmTJm7rW9nDWb6wBDzokTpeCtXVQb6mYqBeDaEvznAuWLP"),
        ],
        wallet1.address
      ),
      // 6 - Getting proposals for a job by id
      Tx.contractCall(
        mainContract,
        "get-proposals-by-id",
        [types.uint(0)],
        deployer.address
      ),
      // 7 - Completing job as different user
      Tx.contractCall(
        mainContract,
        "complete-job",
        [
          types.uint(0),
          types.uint(0),
          types.uint(7),
          types.ascii("QmTJm7rW9nDWb6wBDzokTpeCtXVQb6mYqBeDaEvznAuWLP"),
        ],
        wallet1.address
      ),
      // 8 - Completing job as creator
      Tx.contractCall(
        mainContract,
        "complete-job",
        [
          types.uint(0),
          types.uint(0),
          types.uint(7),
          types.ascii("QmTJm7rW9nDWb6wBDzokTpeCtXVQb6mYqBeDaEvznAuWLP"),
        ],
        deployer.address
      ),
      // 9 - Getting amount of reviews
      Tx.contractCall(
        mainContract,
        "get-amount-of-reviews",
        [],
        deployer.address
      ),
      // 10 - Getting review by id
      Tx.contractCall(
        mainContract,
        "get-review-by-id",
        [types.uint(0)],
        deployer.address
      ),
    ]);

    // Get transaction receipt
    let receipts = block.receipts;
    console.log(receipts);

    // Assert that the returned results have expected values
    // 0 - Getting amount of jobs should return 0 should fail
    receipts[0].result.expectOk();
    // 1 - Adding job with payment set to 0 should fail
    receipts[1].result.expectOk().expectUint(1);
    // 2 - Getting amount of jobs should return 0 should fail
    receipts[2].result.expectOk().expectTuple();
    // 3 - Adding job with payment set to 0 should fail
    receipts[3].result.expectErr().expectUint(103);
    // 4 - Adding job with payment set to 0 should fail
    receipts[4].result.expectErr().expectUint(105);
    // 5 - Adding job with payment set to 0 should fail
    receipts[5].result.expectOk();
    // 6 - Getting amount of jobs should return 0 should fail
    receipts[6].result.expectOk().expectList();
    // 7 - Completing job as creator should fail
    receipts[7].result.expectErr().expectUint(105);
    // 8 - Completing job as creator should return true
    receipts[8].result.expectOk();
    // 9 -Getting amount of reviews should return number of reviews(in this case 1)
    receipts[9].result.expectOk().expectUint(1);
    // 10 - Getting review by id should return tuple
    receipts[10].result.expectOk().expectTuple();
  },
});
