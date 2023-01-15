# Recipe REST-API DevOps

+ fully functioning REST API using:

 - Python
 - Django / Django-REST-Framework
 - Docker / Docker-Compose
 - Test Driven Development

## Getting started

To start project, run:

```
docker-compose up
```

The API will then be available at http://127.0.0.1:8000

### AWS Account Policy 

- "iam_mfa_policy.json" meant to force all iam users (administrators) to use Multi Factor Authentication when login to aws account. 

- "task-exec-role-policy.json" Allows Our ECS Task to retrieve the image from ECR And Put logs in to the log stream
