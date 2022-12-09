from kubernetes import client

def test_virtual_services_deployed():
    expected_vs = [
        "tracing",  # jaeger
        "kiali",
        "kibana",
        "grafana",
        "prometheus",
    ]

    virtual_svcs = client.CustomObjectsApi().list_cluster_custom_object(
        group="networking.istio.io", version="v1beta1", plural="virtualservices"
    )
    domains = [vs["spec"]["hosts"][0] for vs in virtual_svcs["items"]]
    actual_vs = [d.split(".")[0] for d in domains]

    missing_vs = [vs for vs in expected_vs if vs not in actual_vs]

    assert len(missing_vs) == 0, f"Missing virtual services {missing_vs}"

def test_successful_pod_status():
    expected_status = ["Succeeded", "Running"]

    pods = client.CoreV1Api().list_pod_for_all_namespaces().items
    failed_pods = [
        (pod.metadata.name, pod.status.phase)
        for pod in pods
        if pod.status.phase not in expected_status
    ]

    assert len(failed_pods) == 0, f"Unexpected pod phase {failed_pods}"