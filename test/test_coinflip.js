const coinflip = artifacts.require("./CoinFlip.sol");

contract("CoinFlip", accounts => {
  it("self-destruct should be executed by only owner.", async () => {
    let instance = await coinflip.deployed();

    let err;
    try {
      await instance.kill({from: accounts[9]});
    } catch(e) {
      err = e;
    }

    assert.isOk(err instanceof Error, "Anyone can kill the contract!");
  });

  it("should have initial fund.", async () => {
    let instance = await coinflip.deployed();
    let tx = await instance.sendTransaction(
      {
        from: accounts[9],
        value: web3.extend.utils.toWei("5", "ether")
      }
    );
    let bal = await web3.eth.getBalance(instance.address);
    assert.equal(web3.extend.utils.fromWei(bal, "ether").toString(), "5", "House does not having enough fund");
  });

  it("should have normal bet", async () => {
    let instance = await coinflip.deployed();

    const val = 0.1;
    const mask = 1;

    await instance.placeBet(mask, {
      from: accounts[3],
      value: web3.extend.utils.toWei(val.toString(), "ether")
    });
    let bal = await web3.eth.getBalance(instance.address);
    assert.equal(web3.extend.utils.fromWei(bal, "ether").toString(), "5.1", "placeBet is failed");
  });

  it("should have only one bet at a time", async () => {
    let instance = await coinflip.deployed();

    const val = 0.1;
    const mask = 1;

    try {
      await instance.placeBet(mask, {
        from: accounts[3],
        value: web3.extend.utils.toWei(val.toString(), "ether")
      });
    } catch (e) {
      var err = e;
    }
    assert.isOk(err instanceof Error, "Player can bet more then two");
  });
});
