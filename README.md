# Cloud based online concert ticketing system
Assignment for Capita Selecta in Software Engineering — October 2019

## Architecture
Architecture is modeled using ABS Deployment Components model.

### Deployment diagram

![Deployment diagram](out/model/DeploymentDiagram/DeploymentDiagram.svg)

1. `FrontendServer` accepts client requests over HTTPS
2. `LoadBalancer` handles pool of workers
3. `Autoscaler` scales `VirtualMachine`s (aka pool of workers) 
4. `Endpoint` handles incomming requests, gets a `Worker` from `LoadBalancer` and executes work
5. `FrontendServer` communicates with `VirtualMachine`s over HTTPS
6. `Worker` accepts handles work request and gives jobs to `Service`
7. `Service` executes jobs and reads/writes to `Database`