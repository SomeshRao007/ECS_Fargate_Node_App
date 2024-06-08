# ECS_Fargate_Node_App


This is a project we make a deployment of a simple Node.js "Hello World" application on AWS using ECS (Fargate) leveraging IAC via Terraform.

## Architecture  Diagram 

![ECS Fragate githubCD_DiagramWBG2](https://github.com/SomeshRao007/ECS_Fargate_Node_App/assets/111784343/26b26684-9063-4038-95d2-0f3bcb778d9d)


This is the flow of our project, this architecture shows deployment of a Node.js application on AWS ECS using Fargate and a continuous deployment pipeline with GitHub Actions. we are going to achieve this via Terraform

Whenever a user makes code changes in code and pushes into GitHub repository, this triggers an Action Workflow. We would configure GitLab actions to:
- create a Docker image for the Node.js application and push it to the Amazon ECR public/private repositories.
- Use this ECR Image to generate the ECS tasks, which ensures that the latest available version of the Node.js app is deployed and running via the Fargate task under the Application Load Balancer.

>Note: You dont have to create IGW, VPC and all other extra stuff, I am following AWS best practices so i did it. you can just use default vpc and subnets. you dont even have to create an ALB. 


**Task 1: Create a HelloWorld NodeJS App**

For evering i will be using Linux Env. to keep it organised i am keeping everything in a directory. 

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
     <h2 style="text-align: center;">Hello World this is screencast</h2>
     <p style="text-align: center;">Current Date and Time: ${dateTimeString}</p>
   `);
};

const server = http.createServer(listener);
server.listen(3000);

// To print the message
console.log('Server running at http://<public_ip>:3000/');
~~~


to run this :

~~~
node HelloWorld.js
~~~

Don't forget to install nodejs in your system before running. [check this](https://nodejs.org/en/download/package-manager/all#debian-and-ubuntu-based-linux-distributions)


**Task 2: Create a Docker image for the Node.js application**

To create a docker image, you need to create a docker file 

~~~
vi Dockerfile
~~~

I have writen dockerfile in 2 ways:
1. Normal basic format
2. multistage format

the difference in image size is huge i think i will try to improve evern further 
docker ignore shrink



**Task 3: Configure AWS credentials and secrets**

- Create an AWS IAM user with the necessary permissions, bascially with admin access.
- In CLI define your default credentials.


**Task 4: Create Terraform IAC files**

- Set up a new Terraform configuration files for provisioning the necessary AWS resources.

- These are Terraform files we are going to create:
  - To store statefile, and Provider 
  - AWS ECS Cluster (Fargate launch type)
  - AWS ECS Task Definition
  - AWS ECS Service
  - AWS VPC, Subnets
  - Security Groups
  - AWS IAM Roles and Policies for ECS


**Task 5: Set up GitHub Actions for the CD pipeline**

- Store the AWS access key and secret key as GitHub Actions secrets in the repository.
- Store other required secrets, such as the ECR repository name, ECS cluster name, and ECS service name.
- Create a new GitHub Actions workflow file (.github/workflows/workflow.yml)


**Task 6: Test and deploy the application**

Commit and push the changes to the GitHub repository
Verify that the GitHub Actions workflow is triggered and successfully deploys the application, by accessing ALB end point.


