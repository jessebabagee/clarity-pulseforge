import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure can create and update milestone with proper authorization",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    // First create a project
    let block = chain.mineBlock([
      Tx.contractCall(
        "pulseforge-core",
        "create-project",
        [types.utf8("Test Project")],
        wallet_1.address
      )
    ]);
    
    const projectId = block.receipts[0].result.expectOk();
    
    // Create milestone
    block = chain.mineBlock([
      Tx.contractCall(
        "pulseforge-milestones",
        "create-milestone",
        [
          projectId,
          types.utf8("Test Milestone"),
          types.utf8("Description"),
          types.uint(100)
        ],
        wallet_1.address
      )
    ]);
    
    const milestoneId = block.receipts[0].result.expectOk();
    
    // Update status
    block = chain.mineBlock([
      Tx.contractCall(
        "pulseforge-milestones",
        "update-milestone-status",
        [
          projectId,
          milestoneId,
          types.utf8("completed")
        ],
        wallet_1.address
      )
    ]);
    
    block.receipts[0].result.expectOk().expectBool(true);
  }
});
