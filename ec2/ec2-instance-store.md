# EC2 Instance Store

- EBS volumes are network drives with limited performance
- If you need a high-performance hardware disk, use **EC2 Instance Store**

## Key Characteristics

- An instance store provides temporary block-level storage for the EC2 instance
- Storage is provided by disks that are **physically attached to the host computer**. 
- Better I/O performance
- Attached only at instance launch. 
- Can’t detach an instance store volume from one instance and attach it to a different instance.
- Exists only during the lifetime of the instance to which it is attached (**ephemeral**)
- Risk of data loss if hardware fails
- Backups and Replication are user's responsibility

## Use Cases

EC2 Instance Store is ideal for temporary storage of information that changes frequently, such as 
- buffers
- caches
- scratch data
- other temporary content 
- temporary data that you replicate across a fleet of instances, such as a load-balanced pool of web servers.
