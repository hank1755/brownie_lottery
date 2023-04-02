from brownie import Lottery, MockV3Aggregator, config, network
from scripts.utilities import get_account, deploy_mocks, LOCAL_BLOCKCHAIN_ENVIRONMENTS


def deploy_lottery():
    account = get_account()
    # pass price feed address to our contract

    # If working in dev or prd chain use sepolia for eth else deploy mocks
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        price_feed_address = config["networks"][network.show_active()][
            "eth_usd_price_feed"
        ]
    else:
        deploy_mocks()
        price_feed_address = MockV3Aggregator[
            -1
        ].address  # address of latest MockV3Aggregator deployed
        print(f"Mocks Deployed...")

    lottery = Lottery.deploy(
        price_feed_address,
        {"from": account},
        publish_source=config["networks"][network.show_active()].get(
            "verify"
        ),  # .get() is better
    )

    print(f"Contract deployed to {lottery.address}")
    return lottery


def main():
    deploy_lottery()
