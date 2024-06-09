# ECS_Fargate_Node_App


This is a project we make a deployment of a simple Node.js "Hello World" application on AWS using ECS (Fargate) leveraging IAC via Terraform.

## Architecture  Diagram 

![ECS Fragate githubCD_DiagramWBG2](https://github.com/SomeshRao007/ECS_Fargate_Node_App/assets/111784343/26b26684-9063-4038-95d2-0f3bcb778d9d)


This is the architecture of our project, it shows deployment of a Node.js application on AWS ECS using Fargate and a continuous deployment pipeline with GitHub Actions. we are going to achieve this via **Terraform**.

Goal is.. 

Whenever a user makes code changes in code and pushes into GitHub repository, this triggers an Action Workflow. This github runner should:
- create a Docker image for the Node.js application and push it to the Amazon ECR public/private repositories.
- Use this ECR Image to generate the ECS tasks, which ensures that the latest available version of the Node.js app is deployed and running via the Fargate task under the Application Load Balancer.

>Note: You dont have to create IGW, VPC and all other extra stuff, I am following AWS best practices so i did it. you can just use all default elements such as vpc, subnets and etc. You dont even have to create an ALB. 


### Step 1: Create a HelloWorld NodeJS App

For everthing i will be using Linux Env. to keep it organised, i am storing all files in a directory. 

~~~
mkdir ecs_fragate_node && cd ecs_fragate_node 

vi HelloWorld.js
~~~

you can use this code:

~~~
const http = require('node:http');

const listener = function (request, response) {
   const currentDate = new Date();
   const dateTimeString = currentDate.toLocaleString();

   response.writeHead(200, {'Content-Type': 'text/html'});
   response.end(`
     <h2 style="text-align: center;">Hello World </h2>
     <p style="text-align: center;">Current Date and Time: ${dateTimeString}</p>
   `);
};

const server = http.createServer(listener);
server.listen(3000);

// To print the message
console.log('Server running at http://<public_ip>:3000/');
~~~


to run this command from present working directory :

~~~
node HelloWorld.js
~~~

Don't forget to install nodejs in your system before running. [check this](https://nodejs.org/en/download/package-manager/all#debian-and-ubuntu-based-linux-distributions)


### Step 2: Create a Docker image for the Node.js application

To create a docker image, you need to create a docker file 

~~~
vi Dockerfile
~~~

I have writen dockerfile in 2 ways:
1. Normal basic format
2. Multistage format

The difference in image size is huge!!! from 1Gb to 200Mb Nevertheless, it can be still be improved to 10Mb - 30Mb range, i will try to improve evern further.

![Screenshot from ](https://github.com/SomeshRao007/ECS_Fargate_Node_App/assets/111784343/7a66cf49-4161-43c4-b36e-a46cd89090e8)


**Normal structure:**

~~~
FROM node:16
WORKDIR /app
COPY package*.json ./
RUN npm install


COPY . .
EXPOSE 3000
CMD ["node", "HelloWorld.js"]

~~~

I am creating `package.json` file to define our Node.js project dependencies and metadata.

~~~
vi package.json
~~~

write this inside:

~~~
{
  "name": "hello_world",
  "version": "1.0.0",
  "description": "creating a hellooworld node.js app",
  "main": "server.js",
  "scripts": {
    "start": "node helloworld.js"
  },
  "dependencies": {
    "node": "^16.0.0"
  }
}
~~~

You can add any other dependencies and change node version here. 

Build an image :

~~~
docker build -t hello-world .
~~~

to verify our image, Run: 

~~~
docker run -p 3000:3000 hello-world
~~~


![Screenshot from 2024-06-07 22-28-52](https://github.com/SomeshRao007/ECS_Fargate_Node_App/assets/111784343/5592cc47-ac55-4551-a1d5-52a4211af56d)


we can optimise our docker image, lets try multistage structure to achieve same thing.

**MultiStage structure:**

~~~
# build stage
FROM node:16-alpine AS build

WORKDIR /app
COPY package*.json ./
RUN npm install --production

COPY . .

# run stage
FROM node:16-alpine

WORKDIR /app
COPY --from=build /app /app
EXPOSE 3000
CMD ["node", "helloworld.js"]
~~~

In this is `Dockerfile` i have done 2 things:
1. I have seperated build stage and running stage.
2. I have used `node16-alpine` Image which is alot lighter than `node:16`. It is lighter because, it only has limited packages which is required to run node applications.

Use the same build and run commands with this docker file. 

In both the images one thing quite common, that's build time its `76.8s` which is a lot!! to **shrink** that, i have used `.dockerignore` .

~~~
vi .dockerignore
~~~

Include these:

~~~
node_modules
npm-debug.log
Dockerfile
.dockerignore
.git
.gitignore
README.md
~~~
   
And you just see the magic!

![Screenshot from 2024-06-08 09-28-31](https://github.com/SomeshRao007/ECS_Fargate_Node_App/assets/111784343/63eeee00-7754-4042-8729-fe7225a5c87b)


### Step 3: Configure AWS credentials and secrets

- Create an AWS IAM user with the necessary permissions, bascially with admin access.

create a User:

![image](https://github.com/SomeshRao007/ECS_Fargate_Node_App/assets/111784343/679f9f68-8287-4d76-945b-f60a9481f146)

add this permission:

![image](https://github.com/SomeshRao007/ECS_Fargate_Node_App/assets/111784343/eb16042b-372f-455b-bfbb-f70eee3bb474)


Now, in your system install AWS CLI. [check this](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#:~:text=Next%20steps-,AWS%20CLI%20install%20and%20update%20instructions,-For%20installation%20instructions)


- In CLI define your default credentials.

After aws cli installation:

~~~
cd ~

aws configure
~~~


now add your Access keys and set default region i choose to keep `ap-south-1` then default format `json`.

You can check your configuration by:

~~~
cat /.aws/credentials
~~~

### Push your docker file to ECR

Retrieve an authentication token and authenticate your Docker client to your registry. Use the AWS CLI:

~~~
aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/n8y8c3i1
~~~

~~~
docker tag HelloworldMultistage2:latest public.ecr.aws/n8y8c3i1/somesh007:latest
~~~

~~~
docker push public.ecr.aws/n8y8c3i1/somesh007:latest
~~~

![Screenshot 2024-06-07 233342](https://github.com/SomeshRao007/ECS_Fargate_Node_App/assets/111784343/ac536173-a3b9-46ee-85a5-3a45075cb350)



### Step 4: Create Terraform IAC files

I am using VScode for to write terraform files. I installed thee plugins:

1. TERRAFORM
2. TERRAFORM DOC SNIPPETS
3. TERRAFORM FORMAT ON SAVE
4. AWS TOOLKIT

You install these in vscode and start writing terraform code.

I will be diving tf file as per section instead of writing everything in one file, it looks neat and clean and each file can be reused for other projects.  

These are Terraform files we are going to create:
  - To store statefile, and Provider 
  - AWS ECS Cluster (Fargate launch type)
  - AWS ECS Task Definition
  - AWS ECS Service
  - AWS VPC, Subnets
  - Security Groups
  - AWS IAM Roles and Policies for ECS

> Remember to create these files [terraform registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) is your bestfriend!! follow documentation provided online for this. I have followed this documentation inch by inch, it took me sometime to understand but gives u alot more understanding. 


#### Backend.tf
cretae a folder `mkdir terraform_files`  and open vs code with this command `code .` in that directory.

Let's start with storing statefiles:

Create `backend.tf` file add this content:

~~~
terraform {
  backend "s3" {
    bucket  = "ecs-fragate-tf-file"
    region  = "ap-south-1"
    key     = "ecs-fargate-tf-file/node-hello-app/terraform.tfstate"
    encrypt = true
  }
  required_version = ">=0.13.0"
  required_providers {
    aws = {
      version = "~> 5.0"
      source  = "hashicorp/aws"
    }
  }
}
~~~

This `backend.tf` file is configured to use Amazon S3 for storing Terraform state files, ensuring reliable and centralized state management for your ECS Fargate deployment. you can keep it your local system too but i prefer storing in S3 for security reasons.

you have tp create a bucket prior to configuring this, 

- **bucket**: Name of the S3 bucket (ecs-fragate-tf-file) where the state file will be stored.
- **region**: AWS region (ap-south-1) where the S3 bucket is located.
- **key**: Path (ecs-fargate-tf-file/node-hello-app/terraform.tfstate) within the S3 bucket to store the state file.
- **encrypt**: Ensures the state file is stored encrypted in S3.
- Use Terraform versions 0.13.0 or higher.
- **Provider Configuration** specifies the AWS provider version and source. you can create a new `provider.tf` file for this, incase u have a different configuration. 


#### vpc.tf

`vpc.tf` file defines the network infrastructure using AWS resources to create a Virtual Private Cloud (VPC) and associated components. This is a crucial setup for deploying and running ECS Fargate tasks within a **secure** and **isolated network** environment.

Lets create `VPC.tf` 

~~~
resource "aws_vpc" "hellovpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Hello-node-VPC"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.hellovpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1a"

  tags = {
    Name = "Hello-public-Subnet1"
  }
}


resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.hellovpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1b"

  tags = {
    Name = "Hello-public-Subnet2"
  }
}

resource "aws_internet_gateway" "HelloIG" {
  vpc_id = aws_vpc.hellovpc.id

  tags = {
    Name = "Internet-Gateway"
  }
}


resource "aws_route_table" "HelloRT" {
  vpc_id = aws_vpc.hellovpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.HelloIG.id
  }
}


resource "aws_route_table_association" "RTA1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.HelloRT.id
}


resource "aws_route_table_association" "RTA2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.HelloRT.id
}
~~~

- I have Created two public subnets (subnet1 and subnet2) within the VPC. Each subnet is assigned a CIDR block and is mapped to a specific availability zone (**ap-south-1a** and **ap-south-1b**). Subnets are configured to automatically assign public IPs on instance launch. 

- I have Created an Internet Gateway so that we can communicate with internet and attached it to the VPC we created. A route table that routes traffic to the Internet Gateway, and Associates the route table with the two subnets to ensure they can route traffic to and from the internet are also defined in this code. 


#### IAM Roles and Policies 

We are going to configuration an IAM role and policy which is required for ECS Fargate tasks to function correctly. It involves three main files: _iam-role.json, iam-role.tf, and iam-policy.tf_.



create `iam-role.json` file in the same directory and write this: 

~~~
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "ecs-tasks.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
~~~

It defines a trust policy that allows the ECS tasks service (ecs-tasks.amazonaws.com) to assume the IAM role.
The policy grants permission to the ECS service to assume the role, necessary for ECS to manage and execute tasks on your behalf.

In the same directory create `iam-role.tf` file and write this:

~~~
resource "aws_iam_role" "iam-role" {
  name               = "ECS-execution-role"
  assume_role_policy = file("${path.module}/iam-role.json")
}
~~~

we Created an IAM role named **ECS-execution-role**. The role uses the trust policy defined in iam-role.json to specify the entities that can assume the role.

create `iam-policy.json`

~~~
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
~~~

Grants permissions necessary for ECS tasks to pull images from ECR and send logs to CloudWatch.

create `iam-policy.tf`

~~~
resource "aws_iam_role_policy" "iam-policy" {
  name   = "ECS-execution-role-policy"
  role   = aws_iam_role.iam-role.id
  policy = file("${path.module}/iam-policy.json")
}
~~~

We associated a policy with the IAM role created in `iam-role.tf` . This policy grants the permissions for ECS tasks to interact with other AWS services. The policy document is specified in `iam-policy.json`

#### ecs-cluster.tf

we are going to configure an ECS cluster to run your Node.js application. The ECS cluster serves as the foundational resource that manages your containerized application. 

create `ecs-cluster.tf` file and write this:

~~~
resource "aws_ecs_cluster" "HelloECS" {
  name = "Hello-Node-app"
  tags = {
    name = "hello-world-node-app"
  }
}
~~~

The **resource** aws_ecs_cluster creates an ECS cluster named _Hello-Node-app_. The cluster is tagged with a name hello-world-node-app for easy identification and management.

> Again in almost all configurations i have given tags as it is the best pratice to follow.


 #### ecs-service.tf 

we are configuring an ECS service to run our Node.js application using the Fargate launch type. The service makes sure that the application is running with the specified settings and integrates with the load balancer and network infrastructure and alot more which depends on the our configurations.


create `ecs-service.tf` file:

~~~
resource "aws_ecs_service" "nodeapp" {
  name                               = "nodeapp"
  launch_type                        = "FARGATE"
  platform_version                   = "LATEST"
  cluster                            = aws_ecs_cluster.HelloECS.id
  task_definition                    = aws_ecs_task_definition.HelloTD.arn
  scheduling_strategy                = "REPLICA"
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  desired_count                      = 1

  depends_on = [aws_alb_listener.Listener, aws_iam_role.iam-role]


  load_balancer {
    target_group_arn = aws_lb_target_group.HelloTG.arn
    container_name   = "main-container"
    container_port   = 3000
  }

  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.HelloSG.id]
    subnets          = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  }


}
~~~

The resource aws_ecs_service creates an ECS service named **nodeapp**. The service uses the FARGATE launch type and the latest platform version. It runs in the ECS cluster defined by **aws_ecs_cluster.HelloECS**. 

we associated the service with a load balancer target group aws_lb_target_group.HelloTG. And specified the container name `main-container` along with the port `3000` for the load balancer to forward traffic to.


> if you notice this line in `ecs-serivce.tf` file `  depends_on = [aws_alb_listener.Listener, aws_iam_role.iam-role] ` this creates a dependency, now ECS service **waits** for the ALB listener (aws_alb_listener.Listener) and IAM role (aws_iam_role.iam-role) to be created **before** deploying.


#### ecs-taskdefination.tf 


Task definition specifies the task's requirements, such as CPU, memory, and container details, required for our Nodejs application running on ECS.


create ecs-taskdefination.tf file: 

~~~
resource "aws_ecs_task_definition" "HelloTD" {
  family                   = "nginx"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.iam-role.arn
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  container_definitions = jsonencode([
    {
      name      = "main-container"
      image     = "###########.dkr.ecr.ap-south-1.amazonaws.com/somesh007"
      cpu       = 1024
      memory    = 2048
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
    }
  ])
}


data "aws_ecs_task_definition" "HelloTD" {
  task_definition = aws_ecs_task_definition.HelloTD.family
}
~~~

In Container Definitions we are encoding the container definition in JSON format. And Defining a container named `main-container`. That Uses the image `469563970583.dkr.ecr.ap-south-1.amazonaws.com/somesh007` whihc is private image repository we can also use a public repository like `public.ecr.aws/n8y8c3i1/somesh007:latest` from Amazon ECR. I ahve Allocates 1024 CPU units and 2048 MB of memory to the container. and at the end marked the container as essential, ensuring the task fails if the container fails. FInally, Configuring port mappings to **map container port 3000 to host port 3000**.

last "**data**" tag, Retrieves information about the ECS task definition named HelloTD using the family name nginx. It is useful for referencing the task definition details in other resources or outputs.


#### security-group.tf

Creating a security group named HelloSG.  

> an ingress rule to allow incoming TCP traffic on port 3000 from any IP address aka 0.0.0.0/0
> an egress rule to allow all outbound traffic on any port as from_port and to_port set to 0 and protocol which is set to -1, to any IP address aka 0.0.0.0/0


create security-group.tf file:

~~~
resource "aws_security_group" "HelloSG" {
  name        = "HelloSG"
  description = "Allow Port 3000"
  vpc_id      = aws_vpc.hellovpc.id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG"
  }
}
~~~

#### Load-balancer.tf 

I am seting up an Application Load Balancer (ALB) to distribute incoming HTTP traffic to our Node.js application running on ECS. It includes the load balancer resource and the listener that forwards traffic to a specified target group. This is to future proof our application, incase we have a large user base and wehave manage traffic we use load balancers.  


create loadbalancer.tf file :

~~~
resource "aws_lb" "HelloLB" {
  name               = "HelloLB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.HelloSG.id]
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  tags = {
    Name = "LB"
  }
}

resource "aws_alb_listener" "Listener" {
  load_balancer_arn = aws_lb.HelloLB.id
  port              = "3000"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.HelloTG.id
    type             = "forward"
  }
}
~~~

#### target-group.tf

the target group refers to a logical grouping of targets, such as EC2 instances, (thouugh it is serverless in our case we still have to do it) that the load balancer routes traffic to based on various criteria like IP address, host, or path.

create targer-group.tf:

~~~
resource "aws_lb_target_group" "HelloTG" {
  name        = "HelloTG"
  port        = "3000"
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.hellovpc.id

  tags = {
    Name = "TG"
  }
}
~~~

by this we came to an end of writing Infrastructure as code now let put this code into action. 

#### Deploy .tf files 

To run Terraform files and deploy our infrastructure we will start from initializing.

From the directory where all .tf files exist run :

~~~
terraform init
~~~

This command initializes the Terraform working directory and downloads any required provider plugins.

![Screenshot 2024-06-08 111513](https://github.com/SomeshRao007/ECS_Fargate_Node_App/assets/111784343/af203ed7-2258-4ea7-8e49-b4d6b0ed0d42)


check formating and validate your code by running :

~~~
terraform fmt && terraform validate
~~~

![Screenshot 2024-06-08 111833](https://github.com/SomeshRao007/ECS_Fargate_Node_App/assets/111784343/6dda3392-a1dd-4e20-98c5-f2d37aa05732)


Before applying any changes, it's a good practice to review the execution plan:

~~~
terraform plan
~~~

then start applying changes :

~~~
terraform apply -auto-approve
~~~

Terraform will start provisioning the resources defined in your configuration files.

![Screenshot 2024-06-08 112613](https://github.com/SomeshRao007/ECS_Fargate_Node_App/assets/111784343/bcf2103f-1175-4306-8f8e-4bd9a1929799)

Checking out ALB endppoint:3000 

~~~
http://hellolb-1543709965.ap-south-1.elb.amazonaws.com:3000/
~~~

![Screenshot 2024-06-08 112704](https://github.com/SomeshRao007/ECS_Fargate_Node_App/assets/111784343/bc6d9ec8-1a2e-4c01-8635-166f50f14d50)


Here are some confugration images:

![Screenshot 2024-06-08 112742](https://github.com/SomeshRao007/ECS_Fargate_Node_App/assets/111784343/e06a267a-4dcd-48f7-b97f-817868dc2aa4)

![Screenshot 2024-06-08 112828](https://github.com/SomeshRao007/ECS_Fargate_Node_App/assets/111784343/061c4054-9c77-4792-9894-7ecd6d2e05c2)

![Screenshot 2024-06-08 112853](https://github.com/SomeshRao007/ECS_Fargate_Node_App/assets/111784343/b2ecdce0-287f-46f7-a5e1-3a24aa52fced)


![Screenshot 2024-06-08 112932](https://github.com/SomeshRao007/ECS_Fargate_Node_App/assets/111784343/a28efd9e-d0d3-4f39-9bf6-14d8f4a7127d)


![Screenshot 2024-06-08 112946](https://github.com/SomeshRao007/ECS_Fargate_Node_App/assets/111784343/b9485352-accc-41fc-8ead-1e962c7f7f4b)

![Screenshot 2024-06-08 113000](https://github.com/SomeshRao007/ECS_Fargate_Node_App/assets/111784343/591d9a49-0e9d-46f2-900c-8c8b3e631c52)

![Screenshot 2024-06-08 113144](https://github.com/SomeshRao007/ECS_Fargate_Node_App/assets/111784343/421ab2c0-f4e9-49b1-b314-8f45864d293a)



### Step5: Set up GitHub Actions for the CD pipeline

- Store the AWS access key and secret key as GitHub Actions secrets in the repository. preferably in a new environment call DEV.
- Store other required secrets, such as the ECR repository name, ECS cluster name, and ECS service name.


![image](https://github.com/SomeshRao007/ECS_Fargate_Node_App/assets/111784343/418cc031-d109-4788-8a72-307548faa38a)


![image](https://github.com/SomeshRao007/ECS_Fargate_Node_App/assets/111784343/d5e6edc7-3204-440f-9cf6-34f29d08dd2b)

### workflow.yml file

A workflow is a configurable automated process made up of one or more jobs that will be executed sequentially. It is written in YAML format. A job consists of several steps of instructions that perform in a remote server to be executed. In this project, we are going to write a continuous integration (CI) and continuous deployment (CD) pipeline for a Node.js "Hello World" application that will be deployed on AWS ECS using Fargate..

> Must be created in this path: `.github/workflows/workflow.yml`

~~~
---
name: "NODE-HELLO-APP-ECS-Deployment"

'on':
  push:
    branches:
      - master
    tags:
      - "*"
  pull_request:
    branches:
      - master
  workflow_dispatch:
    inputs:
      parameter-name:
        description: 'Start Mannual Workflow'
        required: true    

jobs:
  ci:
    name: "NODE-HELLO-APP-ECS-Integration"
    runs-on: "ubuntu-latest"
    steps:
      - name: "Checkout Code"
        uses: "actions/checkout@v2"

      - name: "Lint code"
        run: |
          echo "Linting repository"
          
      - name: "Run unit tests"
        run: |
          echo "Running unit tests"

  cd:
    name: "NODE-HELLO-APP-ECS-Deployment"
    runs-on: "ubuntu-latest"
    needs:
      - ci
    environment: DEV
    steps:
      - name: "Checkout Code"
        uses: "actions/checkout@v2"

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION }}

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1

      - name: Build, tag, and push image to Amazon ECR
        id: build-image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }} 
          ECR_REPOSITORY: ${{ secrets.ECR_REPOSITORY_NAME }}
          IMAGE_TAG: latest
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          echo "::set-output name=image::$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG"

      # - name: Download task definition
      #   run: |
      #     aws ecs describe-task-definition --task-definition service \
      #     --query taskDefinition > task-definition.json

      - name: Download task definition
        run: |
          TASK_DEFINITION_ARN=$(aws ecs describe-services --cluster ${{ secrets.ECS_CLUSTER }} --services ${{ secrets.ECS_SERVICE }} | jq -r '.services[0].taskDefinition')
          aws ecs describe-task-definition --task-definition $TASK_DEFINITION_ARN --query taskDefinition > task-definition.json

      - name: Fill in the new image ID in the Amazon ECS task definition
        id: task-def
        uses: aws-actions/amazon-ecs-render-task-definition@v1
        with:
          task-definition: task-definition.json
          container-name: main-container
          image: ${{ steps.build-image.outputs.image }}

      - name: Deploy Amazon ECS task definition
        uses: aws-actions/amazon-ecs-deploy-task-definition@v1
        with:
          task-definition: ${{ steps.task-def.outputs.task-definition }}
          service: ${{ secrets.ECS_SERVICE }}
          cluster: ${{ secrets.ECS_CLUSTER }}
          wait-for-service-stability: true
~~~


+ The workflow is triggered on pushes to the master branch, pull requests to the master branch, and manual triggers via the GitHub Actions UI.

- I have written CI/CD workflow for a Node.js "Hello World" app.(Although CI is just a dummy code as i have just written Echo statements, all the good stuff is in CD section)

1. CI job:
   - Checks out code
   - Runs code linting
   - Runs unit tests

> Code linting is the process of analyzing source code to identify potential errors, bugs, stylistic inconsistencies, and deviations from best practices. A code linter is a tool that performs this analysis and provides feedback to the developer. something i want to do it in future so, i left a space for it. until then its just an echo statement.

2. CD job:
   - Checks out code
   - Configures AWS credentials
   - Logs into Amazon ECR
   - Builds and pushes Docker image to ECR
   - Downloads current ECS task definition
   - Updates task definition with new image
   - Deploys updated task definition to ECS service

> all the jobs runs on the latest Ubuntu runner and requires the CI job to complete. (dependency as i mentioned above) we can make the jobs run faster by choosing a lighter version of images such as Alpine Linux but that comes with its own cost you may loose a few functionality so i went with ubuntu.

 ![Screenshot 2024-06-08 183006](https://github.com/SomeshRao007/ECS_Fargate_Node_App/assets/111784343/7f1c7fb8-8ba3-425e-8a8d-437f73979995)

![Screenshot 2024-06-08 181958](https://github.com/SomeshRao007/ECS_Fargate_Node_App/assets/111784343/25684271-ecb8-4dc2-a80e-fa652697988e)


**Task 6: Test and deploy the application**

After completing our workflow, we’ll push it to our GitHub repository. In the “Actions” tab, you’ll notice a new action indicated by the yellow color indicator. You can explore the build logs there, with each tab showing the current task. If any errors occur, we’ll investigate each step to resolve them.

Automating deployments to ECS using GitHub Actions is straightforward and powerful. It ensures automatic deployment whenever there’s a code change. 

To Verify that the GitHub Actions workflow is triggered and successfully deploys the application, lets make some changes in our code and push it.

new image is pushed!!

![Screenshot 2024-06-08 081404](https://github.com/SomeshRao007/ECS_Fargate_Node_App/assets/111784343/caea0262-811d-4d15-98ef-1947186646ec)


![Screenshot 2024-06-08 182956](https://github.com/SomeshRao007/ECS_Fargate_Node_App/assets/111784343/39fb98b2-ad4b-4184-8bb4-a4574650f723)


EVERYTHING WORKS!!


FOR THOSE WHO ARE READING THIS, THANKS FOR YOUR VALUABLE TIME. 


IF YOU HAVE SOME SUGGESTION PLEASE EMAIL ME. 🙌
