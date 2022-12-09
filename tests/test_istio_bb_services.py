import requests
from kubernetes import client
from time import sleep
from timeit import default_timer as timer
import pytest
import socket
import logging

logger = logging.getLogger(__name__)


@pytest.fixture
def override_dns():
    prv_getaddrinfo = socket.getaddrinfo
    dns_cache = {}

    def new_getaddrinfo(*args):
        if args[0] in dns_cache:
            logger.info("Forcing FQDN: %s to IP: %s", args[0], dns_cache[args[0]])
            return prv_getaddrinfo(dns_cache[args[0]], *args[1:])
        else:
            return prv_getaddrinfo(*args)

    socket.getaddrinfo = new_getaddrinfo
    return dns_cache

def load_url(url, timeout):
    return requests.get(url, timeout = timeout, verify=False)

def test_services_are_reachable(override_dns):
    kube_client = client.CoreV1Api()
    svc = kube_client.read_namespaced_service(
        name="public-ingressgateway", namespace="istio-system"
    )
    ip = svc.status.load_balancer.ingress[0].ip
    virtual_svcs = client.CustomObjectsApi().list_cluster_custom_object(
        group="networking.istio.io", version="v1beta1", plural="virtualservices"
    )
    dialtone_svcs = ['tracing', 'kiali', 'kibana', 'alertmanager', 'grafana', 'prometheus']
    domains = [vs["spec"]["hosts"][0] for vs in virtual_svcs["items"]]

    istio_domains = [host for host in domains if not host.startswith(tuple(dialtone_svcs))]
    failed_vs = []
    start = timer()
    elapsed_secs = 0
    elapsed_secs_target = 180
    
    while elapsed_secs < elapsed_secs_target:
        for domain in istio_domains:
            override_dns[domain] = ip
            resp = requests.get(f"https://{domain}", verify=False)

            if resp.status_code != 200:
                if domain.__contains__("minio") and resp.status_code == 403:
                    continue
                failed_vs.append((domain, resp.status_code))

        sleep(0.5)
        elapsed_secs = timer() - start
    assert (
        len(failed_vs) == 0
    ), f"Unexpected status code from virtual services {failed_vs}"