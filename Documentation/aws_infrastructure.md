## VPC and Network Setup

In this section, we will create the networking infrastructure required for the application. The web server will be deployed inside a public subnet.
Network Architecture

The infrastructure consists of:

- 1 Virtual Private Cloud (VPC)
- 2 Public Subnets
- 2 Private Subnets
- 1 Internet Gateway
- 2 Route Tables
- Security Groups for EC2

This design follows AWS best practices by ensuring that the web server is publicly accessible.

## Step 1: Create a VPC

From the AWS Console, search for **VPC**.

Select **Create VPC**.

Choose **VPC only** and configure:

  | Setting  |   Value |
  |-----------| -------------------|
  | Name        | techflow-vpc|
  | IPv4 CIDR |  10.0.0.0/16 |
  | IPv6     |   None |
  | Tenancy    | Default |

Click **Create VPC**.

## Step 2: Create an Internet Gateway

Create an Internet Gateway named **techflow-igw** and attach it to your VPC.

## Step 3: Create Subnets

Create two public subnets.

 | Name            |  AZ        |  CIDR|
 | -----------------| -----------| -------------|
 | public-subnet-1  | First AZ   | 10.0.1.0/24|
 | public-subnet-2  | Second AZ  | 10.0.3.0/24|

 Enable **Auto-assign public IPv4 address** on both public subnets.

Create Private Subnets

  |Name               | AZ         |  CIDR|
  |------------------ |----------- | ------------|
  |private-subnet-1   | First AZ   | 10.0.2.0/24 |
  | private-subnet-2  | Second AZ  | 10.0.4.0/24 |


## Step 4: Create Route Tables

### Public Route Table

Associate with both public subnets and Add a route:

  |Destination   |Target|
  |------------- |-------------------|
  | 0.0.0.0/0    | Internet Gateway|

### Private Route Table

Associate with both private subnets to the private route table.


## Step 5: Create Security Groups

### Web Server Security Group

Inbound:

  | Type   | Port |  Source | 
  | -------| ------ | -----------| 
  | SSH    | 22    | 0.0.0.0/0 |
  | HTTP   | 80   |   0.0.0.0/0 |
  | HTTPS  | 443   | 0.0.0.0/0 |
  | Custom TCP | 5000 | 0.0.0.0/0 |

Outbound: Allow all.

## Step 6: Launch an EC2 Instance (Web Server)

Launch an Ubuntu EC2 Instance in one of the Public Subnet

1. Go to EC2 Dashboard
2. Click Launch Instance
3. Under Network Settings, edit and select your VPC and public subnet
4. Select your public security group, ensure you enable public IP
5. In the **Advanced Details** configuration, paste the following script into the **User data** field.

```bash
#!/bin/bash

# Update package lists
sudo apt update

# Install Docker
sudo apt install -y docker.io

# Enable and start Docker
sudo systemctl enable docker
sudo systemctl start docker

# Add the ubuntu user to the Docker group
sudo usermod -aG docker ubuntu
```

Then Click Launch. Once running, the instance should have internet access. 

To SSH into your instance:

```bash
ssh -i your-key.pem ubuntur@your-instance-public-ip
```