#!/usr/bin/env python3
"""
VPC Infrastructure Architecture Diagram Generator
Generates a visual architecture diagram similar to AWS architecture diagrams
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.aws.network import VPC, InternetGateway, NATGateway, Route53, ElbApplicationLoadBalancer
from diagrams.aws.compute import EC2, ECS, AutoScaling
from diagrams.aws.database import RDS, ElastiCache
from diagrams.aws.storage import S3
from diagrams.aws.security import IAM, SecretsManager, KMS
from diagrams.aws.management import Cloudwatch, CloudwatchEventTimeBased
from diagrams.aws.integration import SNS
from diagrams.aws.devtools import Codebuild
from diagrams.onprem.client import Users
from diagrams.onprem.vcs import Github
from diagrams.aws.general import User

# Configure diagram settings
graph_attr = {
    "fontsize": "20",
    "bgcolor": "white",
    "pad": "0.5",
    "splines": "spline",
    "nodesep": "0.8",
    "ranksep": "1.2"
}

with Diagram("AWS VPC Infrastructure Architecture",
             filename="vpc_architecture_diagram",
             outformat="png",
             show=False,
             direction="TB",
             graph_attr=graph_attr):

    # External Users
    users = Users("Internet Users")

    # GitHub & CI/CD
    with Cluster("CI/CD Pipeline"):
        github = Github("GitHub Repo")
        with Cluster("GitHub Actions"):
            kics_scan = Codebuild("KICS\nSecurity Scan")
            terraform = Codebuild("Terraform\nDeploy")

    # Main VPC
    with Cluster("VPC (10.0.0.0/16)"):
        igw = InternetGateway("Internet Gateway")

        # Public Tier
        with Cluster("Public Subnets (DMZ)"):
            with Cluster("AZ-1 (10.0.1.0/24)"):
                alb1 = ElbApplicationLoadBalancer("ALB")
                nat1 = NATGateway("NAT GW 1")

            with Cluster("AZ-2 (10.0.2.0/24)"):
                alb2 = ElbApplicationLoadBalancer("ALB")
                nat2 = NATGateway("NAT GW 2")

        # Private Tier
        with Cluster("Private Subnets (Application)"):
            with Cluster("AZ-1 (10.0.10.0/24)"):
                app1 = EC2("App Servers")
                ecs1 = ECS("Containers")

            with Cluster("AZ-2 (10.0.20.0/24)"):
                app2 = EC2("App Servers")
                ecs2 = ECS("Containers")

        # Data Tier
        with Cluster("Data Subnets (Database)"):
            with Cluster("AZ-1 (10.0.100.0/24)"):
                db_primary = RDS("RDS Primary")
                cache1 = ElastiCache("Cache")

            with Cluster("AZ-2 (10.0.200.0/24)"):
                db_standby = RDS("RDS Standby")
                cache2 = ElastiCache("Cache")

    # AWS Services
    with Cluster("AWS Services"):
        s3_flow = S3("Flow Logs\nBucket")
        s3_endpoint = S3("S3 VPC\nEndpoint")
        secrets = SecretsManager("Secrets\nManager")
        kms_key = KMS("KMS Key")

    # Monitoring & Logging
    with Cluster("Monitoring & Security"):
        cloudwatch = Cloudwatch("CloudWatch\nLogs")
        flow_logs = Cloudwatch("VPC\nFlow Logs")
        sns = SNS("SNS Alerts")

    # IAM
    with Cluster("Identity & Access"):
        iam = IAM("IAM Roles\n& Policies")

    # Security Team
    security_team = User("Security Team\nEmail Alerts")

    # Traffic Flows

    # Inbound User Traffic
    users >> Edge(color="darkgreen", style="bold", label="HTTPS") >> igw
    igw >> Edge(color="darkgreen") >> alb1
    igw >> Edge(color="darkgreen") >> alb2
    alb1 >> Edge(color="blue", label="App Traffic") >> app1
    alb2 >> Edge(color="blue") >> app2
    app1 >> Edge(color="red", label="DB Query") >> db_primary
    app2 >> Edge(color="red") >> db_standby

    # Outbound Internet (via NAT)
    app1 >> Edge(color="orange", label="Updates") >> nat1
    app2 >> Edge(color="orange") >> nat2
    nat1 >> Edge(color="orange") >> igw
    nat2 >> Edge(color="orange") >> igw

    # Database Replication
    db_primary >> Edge(color="purple", style="dashed", label="Replication") >> db_standby
    cache1 >> Edge(color="purple", style="dashed") >> cache2

    # VPC Endpoints
    app1 >> Edge(color="teal", label="Private") >> s3_endpoint
    app2 >> Edge(color="teal") >> secrets

    # Flow Logs
    flow_logs >> Edge(label="Store") >> cloudwatch
    flow_logs >> Edge(label="Archive") >> s3_flow

    # CI/CD Flow
    github >> Edge(label="Push") >> kics_scan
    kics_scan >> Edge(label="✓ Pass") >> terraform
    terraform >> Edge(label="Deploy", style="dashed") >> igw

    # IAM
    iam >> Edge(color="gray", style="dotted") >> app1
    iam >> Edge(color="gray", style="dotted") >> app2

    # Encryption
    kms_key >> Edge(color="gray", style="dotted", label="Encrypt") >> cloudwatch
    kms_key >> Edge(color="gray", style="dotted") >> s3_flow

    # Alerts
    flow_logs >> Edge(label="Anomaly") >> sns
    sns >> Edge(label="Notify") >> security_team

print("✅ Architecture diagram generated: vpc_architecture_diagram.png")
