from scripts.deploy import deploy_lottery
from web3 import Web3

# test: arrange, act, assert


def test_get_entrance_fee():
    # arrange
    lottery = deploy_lottery()
    # assert
    assert lottery.getEntranceFee() > Web3.toWei(0.026, "ether")
    assert lottery.getEntranceFee() < Web3.toWei(0.028, "ether")
