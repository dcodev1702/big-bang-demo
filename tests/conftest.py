from kubernetes import client, config
import pytest


@pytest.fixture(autouse=True)
def kube_config():
    config.load_kube_config()
