# Docker Fundamentals and Architecture

## Overview

Docker is a containerization platform that packages applications with all their dependencies into standardized units called containers. These containers ensure consistent behavior across different environments—from development machines to production servers—eliminating the "it works on my machine" problem.

## What is Docker?

### Core Concept

Docker uses **operating system-level virtualization** to create isolated application environments. Unlike traditional virtual machines that virtualize entire operating systems, containers share the host's OS kernel while maintaining isolated file systems, processes, and networking.

### Key Characteristics

- **Lightweight**: Containers start in milliseconds and consume minimal resources
- **Portable**: Packages include all dependencies (application code, runtime, system libraries)
- **Consistent**: Applications behave identically regardless of where the container runs
- **Language and OS Agnostic**: Works with any programming language, operating system, or technology stack

### Use Cases

- **Microservices Architecture**: Deploy independent, loosely-coupled services
- **Lift-and-Shift Migration**: Move on-premises applications to AWS cloud
- **Continuous Integration/Deployment**: Standardized build and deployment pipeline
- **Development Environment Consistency**: Developers run identical containers locally as in production

## Docker vs Virtual Machines

### Architecture Comparison

| Aspect | Docker Containers | Virtual Machines |
|--------|------------------|------------------|
| **Virtualization Level** | OS-level (shared kernel) | Full machine-level |
| **Guest OS** | None (uses host OS) | Full OS per VM |
| **Resource Usage** | Minimal (MB to low GB) | Significant (GB to tens of GB) |
| **Startup Time** | Milliseconds | Seconds to minutes |
| **Density** | Many containers per host | Few VMs per host |
| **Isolation** | Process and namespace isolation | Complete isolation |

### Docker Architecture

```
┌─────────────────────────────────────────────┐
│         Host OS (EC2 Instance)              │
│                                             │
│  ┌─────────────┐  ┌─────────────┐           │
│  │ Container 1 │  │ Container 2 │  ...      │
│  │  (App)      │  │  (App)      │           │
│  └─────────────┘  └─────────────┘           │
│                                             │
│         Docker Daemon                       │
│    (manages containers)                     │
│                                             │
│         Linux Kernel (shared)               │
└─────────────────────────────────────────────┘
```

### Virtual Machine Architecture

```
┌─────────────────────────────────────────────┐
│         Host OS                             │
│                                             │
│  ┌──────────────┐  ┌──────────────┐         │
│  │   Guest OS   │  │   Guest OS   │  ...    │
│  │              │  │              │         │
│  │  ┌────────┐  │  │  ┌────────┐  │         │
│  │  │  App   │  │  │  │  App   │  │         │
│  │  └────────┘  │  │  └────────┘  │         │
│  └──────────────┘  └──────────────┘         │
│                                             │
│         Hypervisor (manages VMs)            │
└─────────────────────────────────────────────┘
```

## Docker Terminology

### Dockerfile

A text file containing instructions to build a Docker image. Example structure:

```dockerfile
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y python3
COPY app.py /app/
WORKDIR /app
CMD ["python3", "app.py"]
```

### Image

A lightweight, standalone, executable package that contains:
- Application code
- Runtime environment
- System libraries and dependencies
- Environment variables
- Metadata

Images are **immutable** and serve as templates for containers.

### Container

A running instance of a Docker image. Containers are:
- **Isolated**: Each container has its own file system, processes, and network namespace
- **Ephemeral**: Stopped containers' data is lost unless volumes are used
- **Executable**: Runs the application defined in the image

### Docker Registry/Repository

A centralized storage location for Docker images where images can be pushed (uploaded) and pulled (downloaded).

## Docker Lifecycle

```
1. Build: Create image from Dockerfile
   $ docker build -t myapp:1.0 .

2. Push: Upload to registry
   $ docker push registry.example.com/myapp:1.0

3. Pull: Download from registry
   $ docker pull registry.example.com/myapp:1.0

4. Run: Create and start container
   $ docker run -d registry.example.com/myapp:1.0

5. Stop/Remove: Terminate and delete container
   $ docker stop container_id
   $ docker rm container_id
```

## Benefits for AWS Developers

### Consistency Across Environments

Development, staging, and production all run identical containers, eliminating environment-specific bugs.

### Scalability

Containers can be quickly spun up or down to handle varying loads, enabling efficient auto-scaling.

### Resource Efficiency

Shared kernel and minimal overhead allow running more applications per server compared to VMs.

### Operational Simplicity

Developers focus on application code; infrastructure concerns are abstracted through container orchestration services like ECS and Fargate.

## References

- AWS. [Docker Basics](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/docker-basics.html)
- AWS. [Introduction to Container Fundamentals](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/fundamentals.html)
- Docker. [What is Docker?](https://www.docker.com/resources/what-docker)
