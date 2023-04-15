from brownie import (
    accounts,
    network,
    config,
    MockV3Aggregator,
    VRFCoordinatorV2Mock,
    LinkToken,
    Contract,
    interface,
)

FORKED_LOCAL_ENVIRONMENTS = ["mainnet-fork", "mainnet-fork-dev"]
LOCAL_BLOCKCHAIN_ENVIRONMENTS = ["development", "ganache-local"]


def get_account(index=None, id=None):
    # accounts[0]
    # accounts.add("env")
    # accounts.load("id")
    if index:
        return accounts[index]
    if id:
        return accounts.load(id)
    if (
        network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS
        or network.show_active() in FORKED_LOCAL_ENVIRONMENTS
    ):
        return accounts[0]
    return accounts.add(config["wallets"]["from_key"])


contract_to_mock = {
    "eth_usd_price_feed": MockV3Aggregator,
    "vrf_coordinator": VRFCoordinatorV2Mock,
    "link_token": LinkToken,
}


def get_contract(contract_name):
    """This function will grab the contract addresses from the brownie config
    if defined, otherwise, it will deploy a mock version of that contract, and
    return that mock contract.
        Args:
            contract_name (string)
        Returns:
            brownie.network.contract.ProjectContract: The most recently deployed
            version of this contract.
    """
    contract_type = contract_to_mock[contract_name]
    if network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        if len(contract_type) <= 0:
            deploy_mocks()
        contract = contract_type[-1]
    else:
        contract_address = config["networks"][network.show_active()][contract_name]
        # address
        # ABI
        contract = Contract.from_abi(
            contract_type._name, contract_address, contract_type.abi
        )
    return contract


def deploy_mocks(
    decimals=8,  # number of decimals
    starting_price=200000000000,  # 2000 artificial price of eth
    base_fee=25000000000000000,  # 0.25 LINK base fee: fee paid to oracle to use the contract, different for each blockchain
    gas_price_link=1000000000,  # gas price for sending transactions
):
    account = get_account()
    V3Aggregator_contract = MockV3Aggregator.deploy(
        decimals, starting_price, {"from": account}
    )
    linkToken_contract = LinkToken.deploy({"from": account})
    VRF_contract = VRFCoordinatorV2Mock.deploy(
        base_fee, gas_price_link, {"from": account}
    )
    print("Deployed!")
    print(f"V3Aggregator_contract {V3Aggregator_contract}")
    print(f"linkToken_contract {linkToken_contract}")
    print(f"VRF_contract {VRF_contract}")


def fund_with_link(
    contract_address, account=None, link_token=None, amount=100000000000000000
):  # 0.1 LINK
    account = account if account else get_account()
    link_token = link_token if link_token else get_contract("link_token")

    sub_id_txn = VRFCoordinatorV2Mock.createSubscription({"from": account})
    sub_id_txn.wait(1)
    sub_id = sub_id_txn.events["SubscriptionCreated"]["subId"]
    fund_amount_link = amountfund_vrf_txn = VRFCoordinatorV2Mock.fundSubscription(
        sub_id, fund_amount_link, {"from": account}
    )
    print("Fund contract!")
