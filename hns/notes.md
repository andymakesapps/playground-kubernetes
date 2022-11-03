# Set Up Notes

Before getting started with the architecture a few things have to be set up. Depending on each situation all of the items below have to completed or just some of them.

1. New project set up
    - a new project will be required where the main cluster will reside
    - after creating the project it should be attached to a network
    - once the network is created the Kubernetes Cluster can be created as well, don't forget to enable Workload Identity and Config Connector when creating the cluster

2. Create the service account which will manage resources
    - as each resource will have its own service account it is necessary to have those accounts created and grant them each the required permissions

3. Install HNS and krew
    - in order to utilize hierarchical namespaces the 2 tools will have to be installed

4. Configure the cluster
    - the service accounts will have to be added to the workload identity
    - also each project that is to be managed should be annoted
    - namespaces have to be created for each project and their resources
    ```
    kubectl annotate namespace ama-spi-test cnrm.cloud.google.com/project-id=ama-spi-test
    ```

