from diagrams import Diagram, Cluster, Edge
from diagrams.aws.compute import EC2
from diagrams.aws.network import ELB, Route53, VPC
from diagrams.aws.network import InternetGateway




graph_attr = {
    "fontsize": "20",
}

with Diagram("tf-stack-test", show=True, graph_attr=graph_attr, direction="RL"):

    with Cluster("VPC: my_vpc\nCIDR: 10.10.0.0/16"):
       elb = ELB("Load Balancer")
       igw = InternetGateway("internet gw")

       igw >> elb

       with Cluster("az:  us-east-2b"):
           with Cluster("subnet_2\nCIDR: 10.10.1.0/24"):
             ws2 = EC2("webServer_2")
             elb >> ws2

       with Cluster("az:  us-east-2a"):
           with Cluster("subnet_1\nCIDR: 10.10.0.0/24"):
             ws1 = EC2("webServer_1")
             elb >> ws1
