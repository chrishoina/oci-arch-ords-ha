# 1. ORDS in an OCI compute instance using available RPMs

## 2. Some questions

- What happens when you install ORDS in a compute instance, in OCI, with the `sudo dnf install ords -y` command?
- What does the configuration folder structure look like?
- What does the bin look like?
- What are the users that install and invoke the `ords serve` command?
- Detail the steps for installing sqlcl, and java.
- Do you need to explicitly set the `PATH`s for the ORDS `/bin` and SQLcl `/bin`? Or is that already done with the `sudo dnf instal [product]` command?

## 3. Technical details

What am I supposed to call this? I am doing some testing, and here are the "variables" in my experimentation:

| Name | Characteristics | Notes/Details |
| ---- | --------------- | ------------- |
|testinstance01 | IPv4, no Boot volume | In ords-vcn, public subnet-ords-vcn |
| Linux OS | 9 | Image build: 2025.02.28-0|
|Shape | AMD VM.Standard.E4.Flex | 1 OCPU, 16GB memory, 1 Gbps bandwidth |

Saved the private key file in the .ssh folder.
Public IP address: 132.226.202.219

> **:memo: NOTE:** When you view the compute instance details in the OCI dashnboard, the OS shows what looks to be a "fully-qualified" version. When you create the compute instance, you'll see soemthing like `Linux 9`.  
>
>But when you view the details (after the instance has provisioned) it will show something like this: `Oracle-Linux-9.5-2025.02.28-0`. 
>
> I believe, for Terraform files you need to use `9.5` as the OS. Just noting for future steps.

To access the compute instance, we follow the steps outlined [here](https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/connect-to-linux-instance.htm).

### 3.1 Accessing the Compute Instance

1. I'll `cd` to my .ssh directory to make those steps a little easier.
2. Issue the `chmod 400 [your private key file]` command.[^3.1]
<!-- Question for me, do we need to do this chmod command when we are doing this with Terraform? -->
3. Use `ssh -i [your private key file] opc@[your compute's public IP address`

[^3.1]: About the [chmod](https://ss64.com/bash/chmod.html) commmand.
