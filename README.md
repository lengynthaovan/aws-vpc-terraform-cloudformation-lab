# AWS VPC Infrastructure Lab with Terraform and CloudFormation

## 1. Giới thiệu

Dự án này triển khai hạ tầng mạng trên AWS theo mô hình **Public Subnet / Private Subnet** bằng hai công cụ Infrastructure as Code:

- **Terraform**: triển khai hạ tầng theo dạng module.
- **AWS CloudFormation**: triển khai hạ tầng bằng AWS-native template.

Hạ tầng đã được thiết kế để đáp ứng yêu cầu bài lab: Public EC2 có thể SSH từ Internet, Private EC2 không có Public IP và chỉ truy cập được thông qua Public EC2/Bastion Host. Private EC2 vẫn có thể truy cập Internet outbound thông qua NAT Gateway.

Các thành phần chính:

- VPC
- Public Subnet
- Private Subnet
- Internet Gateway
- NAT Gateway và Elastic IP
- Public Route Table
- Private Route Table
- Public EC2 Instance
- Private EC2 Instance
- Security Groups kiểm soát SSH

---

## 2. Kiến trúc hạ tầng

```text
                         Internet
                            |
                    +----------------+
                    | Internet       |
                    | Gateway        |
                    +----------------+
                            |
+----------------------------------------------------------------+
|                            VPC                                 |
|                       10.0.0.0/16                              |
|                                                                |
|  +---------------------------+      +------------------------+ |
|  | Public Subnet             |      | Private Subnet         | |
|  | 10.0.1.0/24               |      | 10.0.2.0/24            | |
|  |                           |      |                        | |
|  |  +---------------------+  | SSH  |  +------------------+  | |
|  |  | Public EC2          | +-----> |  | Private EC2       |  | |
|  |  | Bastion Host        |        |  | No Public IP      |  | |
|  |  | Has Public IP       |        |  | Private IP only   |  | |
|  |  +---------------------+        |  +------------------+  | |
|  |                           |      |           |            | |
|  |  +---------------------+  |      |           | Outbound   | |
|  |  | NAT Gateway         | <-------------------+ Internet   | |
|  |  | Elastic IP          |  |      |                        | |
|  |  +---------------------+  |      |                        | |
|  +---------------------------+      +------------------------+ |
|          |                                        |             |
|  Public Route Table                       Private Route Table   |
|  0.0.0.0/0 -> IGW                         0.0.0.0/0 -> NAT GW  |
+----------------------------------------------------------------+
```

Luồng hoạt động:

```text
Máy người dùng
   |
   | SSH port 22
   v
Public EC2 / Bastion Host
   |
   | SSH port 22 bằng Private IP
   v
Private EC2
   |
   | Internet outbound
   v
NAT Gateway -> Internet Gateway -> Internet
```

---

## 3. Cấu trúc thư mục

```text
aws-vpc-terraform-cloudformation-lab/
│
├── README.md
├── .gitignore
│
├── keys/
│   └── labuser.pem                  # Không commit lên GitHub
│
├── terraform/
│   ├── providers.tf
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   │
│   └── modules/
│       ├── vpc/
│       ├── network/
│       ├── security-groups/
│       └── ec2/
│
└── cloudformation/
    ├── vpc-ec2.yml
    ├── parameters.example.json
    └── README.md
```

> Ghi chú: Nếu project của bạn đang để Terraform ở thư mục gốc thay vì `terraform/`, vẫn có thể chạy bình thường. Tuy nhiên, tách `terraform/` và `cloudformation/` sẽ giúp repo rõ ràng hơn khi nộp bài.

---

## 4. Yêu cầu trước khi chạy

Máy cần cài đặt:

- AWS CLI
- Terraform
- Git
- SSH client

Kiểm tra AWS CLI:

```powershell
aws --version
aws sts get-caller-identity
```

Nếu dùng AWS Academy Learner Lab, copy credentials từ:

```text
AWS Academy > Cloud Access > AWS CLI
```

vào file:

```text
C:\Users\<YourUser>\.aws\credentials
```

Nội dung có dạng:

```ini
[default]
aws_access_key_id=...
aws_secret_access_key=...
aws_session_token=...
```

Kiểm tra Key Pair:

```powershell
aws ec2 describe-key-pairs --query "KeyPairs[*].KeyName" --output table
```

Trong AWS Academy, Key Pair thường là:

```text
vockey
```

File `.pem` tải về để SSH có thể tên là `labuser.pem`. Terraform/CloudFormation dùng **Key Pair name** là `vockey`, còn SSH dùng **file PEM** là `labuser.pem`.

---

# PHẦN A - TRIỂN KHAI BẰNG TERRAFORM

## 5. Cấu hình Terraform

File `terraform.tfvars` hoặc biến truyền vào Terraform cần có:

```hcl
aws_region          = "us-east-1"
project_name        = "vpc-lab"
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidr  = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"

allowed_ssh_cidr = "YOUR_PUBLIC_IP/32"
key_name         = "vockey"
instance_type    = "t2.micro"
```

Lấy IP public của máy:

```powershell
$myip = (Invoke-RestMethod https://checkip.amazonaws.com).Trim()
$myip
```

Ví dụ nếu IP là `113.161.20.10`, cấu hình:

```hcl
allowed_ssh_cidr = "113.161.20.10/32"
```

---

## 6. Chạy Terraform

Nếu Terraform nằm trong thư mục `terraform/`:

```powershell
cd terraform
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

Nếu Terraform nằm ở thư mục gốc project, chạy trực tiếp tại root:

```powershell
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

Khi Terraform hỏi xác nhận, nhập:

```text
yes
```

Xem output:

```powershell
terraform output
terraform output -raw public_ec2_public_ip
terraform output -raw private_ec2_private_ip
```

---

# PHẦN B - TRIỂN KHAI BẰNG CLOUDFORMATION

## 7. Cấu hình CloudFormation

Thư mục CloudFormation gồm:

```text
cloudformation/
├── vpc-ec2.yml
├── parameters.example.json
└── README.md
```

Trong đó:

- `vpc-ec2.yml`: template tạo VPC, Subnets, IGW, NAT Gateway, Route Tables, Security Groups và EC2.
- `parameters.example.json`: file tham số mẫu.
- `README.md`: hướng dẫn chạy riêng cho phần CloudFormation.

Ví dụ parameters:

```json
[
  {
    "ParameterKey": "ProjectName",
    "ParameterValue": "vpc-lab-cfn"
  },
  {
    "ParameterKey": "VpcCidr",
    "ParameterValue": "10.0.0.0/16"
  },
  {
    "ParameterKey": "PublicSubnetCidr",
    "ParameterValue": "10.0.1.0/24"
  },
  {
    "ParameterKey": "PrivateSubnetCidr",
    "ParameterValue": "10.0.2.0/24"
  },
  {
    "ParameterKey": "AllowedSshCidr",
    "ParameterValue": "YOUR_PUBLIC_IP/32"
  },
  {
    "ParameterKey": "KeyName",
    "ParameterValue": "vockey"
  },
  {
    "ParameterKey": "InstanceType",
    "ParameterValue": "t2.micro"
  }
]
```

---

## 8. Validate và deploy CloudFormation

Validate template:

```powershell
aws cloudformation validate-template `
  --template-body file://cloudformation/vpc-ec2.yml
```

Deploy stack:

```powershell
aws cloudformation deploy `
  --stack-name vpc-lab-cfn-stack `
  --template-file cloudformation/vpc-ec2.yml `
  --parameter-overrides `
    ProjectName=vpc-lab-cfn `
    VpcCidr=10.0.0.0/16 `
    PublicSubnetCidr=10.0.1.0/24 `
    PrivateSubnetCidr=10.0.2.0/24 `
    AllowedSshCidr=YOUR_PUBLIC_IP/32 `
    KeyName=vockey `
    InstanceType=t2.micro
```

Kiểm tra trạng thái stack:

```powershell
aws cloudformation describe-stacks `
  --stack-name vpc-lab-cfn-stack `
  --query "Stacks[*].{StackName:StackName,Status:StackStatus}" `
  --output table
```

Xem outputs:

```powershell
aws cloudformation describe-stacks `
  --stack-name vpc-lab-cfn-stack `
  --query "Stacks[0].Outputs" `
  --output table
```

---

## 9. Kiểm tra hạ tầng bằng AWS CLI

Kiểm tra VPC:

```powershell
aws ec2 describe-vpcs `
  --filters "Name=tag:Name,Values=vpc-lab-vpc" `
  --query "Vpcs[*].{VpcId:VpcId,CidrBlock:CidrBlock,State:State,Name:Tags[?Key=='Name']|[0].Value}" `
  --output table
```

Kiểm tra subnets:

```powershell
aws ec2 describe-subnets `
  --filters "Name=tag:Name,Values=vpc-lab-public-subnet,vpc-lab-private-subnet" `
  --query "Subnets[*].{SubnetId:SubnetId,CidrBlock:CidrBlock,AvailabilityZone:AvailabilityZone,MapPublicIpOnLaunch:MapPublicIpOnLaunch,Name:Tags[?Key=='Name']|[0].Value}" `
  --output table
```

Kiểm tra NAT Gateway:

```powershell
aws ec2 describe-nat-gateways `
  --filter "Name=tag:Name,Values=vpc-lab-nat-gateway" `
  --query "NatGateways[*].{NatGatewayId:NatGatewayId,State:State,SubnetId:SubnetId,PublicIp:NatGatewayAddresses[0].PublicIp,Name:Tags[?Key=='Name']|[0].Value}" `
  --output table
```

Kiểm tra EC2:

```powershell
aws ec2 describe-instances `
  --filters "Name=tag:Name,Values=vpc-lab-public-ec2,vpc-lab-private-ec2" `
  --query "Reservations[*].Instances[*].{Name:Tags[?Key=='Name']|[0].Value,InstanceId:InstanceId,State:State.Name,PrivateIp:PrivateIpAddress,PublicIp:PublicIpAddress,SubnetId:SubnetId,KeyName:KeyName}" `
  --output table
```

Kiểm tra Security Groups:

```powershell
aws ec2 describe-security-groups `
  --filters "Name=group-name,Values=vpc-lab-public-ec2-sg,vpc-lab-private-ec2-sg" `
  --query "SecurityGroups[*].{GroupId:GroupId,GroupName:GroupName,Inbound:IpPermissions}" `
  --output json
```

---

## 10. Kiểm thử SSH và NAT Gateway

SSH vào Public EC2:

```powershell
ssh -i .\keys\labuser.pem ec2-user@<PUBLIC_EC2_PUBLIC_IP>
```

Nếu lỗi quyền file PEM trên Windows, sửa quyền:

```powershell
$key = ".\keys\labuser.pem"
$me = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

takeown /F $key
icacls $key /inheritance:r
icacls $key /remove:g "Users" "Authenticated Users" "Everyone" 2>$null
icacls $key /grant:r "$($me):(R)"
```

Upload key lên Public EC2 để SSH vào Private EC2:

```powershell
scp -i .\keys\labuser.pem .\keys\labuser.pem ec2-user@<PUBLIC_EC2_PUBLIC_IP>:/home/ec2-user/labuser.pem
```

Trên Public EC2:

```bash
chmod 400 labuser.pem
ssh -i labuser.pem ec2-user@<PRIVATE_EC2_PRIVATE_IP>
```

Test NAT Gateway trên Private EC2:

```bash
curl -I https://aws.amazon.com
```

Nếu có HTTP response, Private EC2 đã truy cập Internet outbound thông qua NAT Gateway thành công.

Sau khi test xong, xóa key trên Public EC2:

```bash
rm -f /home/ec2-user/labuser.pem
```

---

## 11. Test cases

| Test case | Công cụ        | Mục tiêu                          | Lệnh/cách kiểm tra                     | Kết quả mong đợi                                        |
| --------- | -------------- | --------------------------------- | -------------------------------------- | ------------------------------------------------------- |
| TC01      | Chung          | Kiểm tra AWS credentials          | `aws sts get-caller-identity`          | Trả về Account ID và Arn                                |
| TC02      | Terraform      | Kiểm tra cú pháp                  | `terraform validate`                   | Configuration valid                                     |
| TC03      | Terraform      | Xem kế hoạch tạo tài nguyên       | `terraform plan`                       | Hiển thị resource sẽ tạo                                |
| TC04      | Terraform      | Triển khai hạ tầng                | `terraform apply`                      | Apply complete                                          |
| TC05      | CloudFormation | Validate template                 | `aws cloudformation validate-template` | Template hợp lệ                                         |
| TC06      | CloudFormation | Deploy stack                      | `aws cloudformation deploy`            | Stack deploy thành công                                 |
| TC07      | CloudFormation | Kiểm tra stack                    | `aws cloudformation describe-stacks`   | Stack status `CREATE_COMPLETE`                          |
| TC08      | AWS CLI        | Kiểm tra VPC                      | `aws ec2 describe-vpcs`                | Có VPC đúng CIDR                                        |
| TC09      | AWS CLI        | Kiểm tra Subnets                  | `aws ec2 describe-subnets`             | Public/Private subnet đúng CIDR                         |
| TC10      | AWS CLI        | Kiểm tra NAT Gateway              | `aws ec2 describe-nat-gateways`        | NAT Gateway `available`                                 |
| TC11      | AWS CLI        | Kiểm tra EC2                      | `aws ec2 describe-instances`           | Public EC2 có Public IP, Private EC2 không có Public IP |
| TC12      | SSH            | SSH vào Public EC2                | `ssh -i key ec2-user@public_ip`        | SSH thành công                                          |
| TC13      | SSH            | SSH từ Public EC2 vào Private EC2 | `ssh -i key ec2-user@private_ip`       | SSH thành công                                          |
| TC14      | NAT            | Private EC2 đi Internet           | `curl -I https://aws.amazon.com`       | Có HTTP response                                        |

---

## 12. Bảo mật

Bài Lab áp dụng các cấu hình bảo mật sau:

- Public EC2 chỉ mở SSH port 22 cho IP public cụ thể của người dùng.
- Private EC2 không có Public IP.
- Private EC2 chỉ cho phép SSH từ Public EC2 Security Group.
- NAT Gateway nằm trong Public Subnet và chỉ phục vụ outbound traffic cho Private Subnet.
- Không mở SSH toàn Internet bằng `0.0.0.0/0` trong bản nộp chính thức.
- Không commit file `.pem`, `terraform.tfvars`, `terraform.tfstate`, credentials AWS lên GitHub.

`.gitignore` khuyến nghị:

```gitignore
.terraform/
*.tfstate
*.tfstate.*
terraform.tfvars
*.pem
crash.log
*.tfplan
cloudformation/parameters.json
```

---

## 13. Dọn tài nguyên

Dọn Terraform:

```powershell
terraform destroy
```

Dọn CloudFormation:

```powershell
aws cloudformation delete-stack `
  --stack-name vpc-lab-cfn-stack
```

Kiểm tra lại sau khi xóa để tránh phát sinh chi phí, đặc biệt là EC2, NAT Gateway và Elastic IP.

---

## 14. Link báo cáo và source code

- Link GitHub source code: `<Dán link GitHub tại đây>`
- Báo cáo Word: nộp theo yêu cầu của giảng viên.
