# AWS VPC Infrastructure Lab with Terraform

## 1. Giới thiệu

Dự án này triển khai hạ tầng mạng trên AWS bằng Terraform theo mô hình **Public Subnet / Private Subnet**. Hạ tầng được tổ chức theo dạng module nhằm đảm bảo dễ quản lý, dễ tái sử dụng và đáp ứng yêu cầu của bài thực hành.

Các thành phần chính được triển khai gồm:

- VPC
- Public Subnet
- Private Subnet
- Internet Gateway
- NAT Gateway
- Public Route Table
- Private Route Table
- EC2 Instance trong Public Subnet
- EC2 Instance trong Private Subnet
- Security Groups kiểm soát truy cập SSH

---

## 2. Mục tiêu bài thực hành

Mục tiêu của bài lab là xây dựng một hạ tầng AWS đảm bảo:

1. Public EC2 có thể truy cập từ Internet thông qua SSH.
2. Private EC2 không có Public IP và không thể truy cập trực tiếp từ Internet.
3. Private EC2 chỉ có thể SSH từ Public EC2.
4. Private EC2 có thể truy cập Internet outbound thông qua NAT Gateway.
5. Toàn bộ tài nguyên được triển khai bằng Terraform và được chia thành các module riêng biệt.
6. Có test cases để kiểm tra từng thành phần hạ tầng được triển khai thành công.

---

## 3. Kiến trúc hạ tầng

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
|  |  +---------------------+        |  +------------------+  | |
|  |                           |      |           |            | |
|  |  +---------------------+  |      |           | Outbound   | |
|  |  | NAT Gateway         | <-------------------+ Internet   | |
|  |  +---------------------+  |      |                        | |
|  +---------------------------+      +------------------------+ |
|          |                                        |             |
|  Public Route Table                       Private Route Table   |
|  0.0.0.0/0 -> IGW                         0.0.0.0/0 -> NAT GW  |
+----------------------------------------------------------------+
```

Luồng truy cập:

```text
Laptop người dùng
   |
   | SSH port 22
   v
Public EC2 / Bastion Host
   |
   | SSH port 22 thông qua private IP
   v
Private EC2
   |
   | Outbound Internet
   v
NAT Gateway -> Internet Gateway -> Internet
```

---

## 4. Thành phần hạ tầng

| Thành phần          | Mô tả                                                                   |
| ------------------- | ----------------------------------------------------------------------- |
| VPC                 | Mạng riêng ảo trên AWS, CIDR `10.0.0.0/16`                              |
| Public Subnet       | Subnet có route đi Internet Gateway, CIDR `10.0.1.0/24`                 |
| Private Subnet      | Subnet không có route trực tiếp ra Internet Gateway, CIDR `10.0.2.0/24` |
| Internet Gateway    | Cho phép Public Subnet giao tiếp với Internet                           |
| NAT Gateway         | Cho phép Private EC2 truy cập Internet outbound                         |
| Public Route Table  | Định tuyến `0.0.0.0/0` đến Internet Gateway                             |
| Private Route Table | Định tuyến `0.0.0.0/0` đến NAT Gateway                                  |
| Public EC2          | EC2 trong Public Subnet, có Public IP, dùng làm Bastion Host            |
| Private EC2         | EC2 trong Private Subnet, không có Public IP                            |
| Security Groups     | Kiểm soát traffic vào/ra cho EC2 instances                              |

---

## 5. Cấu trúc thư mục

```text
Lab01/
│
├── providers.tf
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
├── README.md
│
└── modules/
    ├── vpc/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── network/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── security-groups/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── ec2/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## 6. Mô tả các module

### 6.1. Module `vpc`

Module này dùng để tạo:

- VPC
- Default Security Group cho VPC

### 6.2. Module `network`

Module này dùng để tạo:

- Public Subnet
- Private Subnet
- Internet Gateway
- Elastic IP cho NAT Gateway
- NAT Gateway
- Public Route Table
- Private Route Table
- Route Table Association

### 6.3. Module `security-groups`

Module này dùng để tạo:

- Public EC2 Security Group
- Private EC2 Security Group

Quy tắc bảo mật:

- Public EC2 chỉ cho phép SSH port 22 từ IP cụ thể của người dùng.
- Private EC2 chỉ cho phép SSH port 22 từ Security Group của Public EC2.

### 6.4. Module `ec2`

Module này dùng để tạo:

- Public EC2 trong Public Subnet
- Private EC2 trong Private Subnet

---

## 7. Yêu cầu trước khi chạy

Máy cần cài đặt:

- Terraform
- AWS CLI
- Git
- SSH client

Kiểm tra Terraform:

```powershell
terraform -version
```

Kiểm tra AWS CLI:

```powershell
aws --version
```

Kiểm tra AWS credentials:

```powershell
aws sts get-caller-identity
```

Nếu sử dụng AWS Academy Learner Lab, cần copy credentials từ:

```text
AWS Academy > Cloud Access > AWS CLI
```

vào file:

```text
C:\Users\<YourUser>\.aws\credentials
```

Nội dung credentials có dạng:

```ini
[default]
aws_access_key_id=...
aws_secret_access_key=...
aws_session_token=...
```

---

## 8. Cấu hình biến Terraform

File `terraform.tfvars` dùng để cấu hình các giá trị đầu vào:

```hcl
aws_region          = "us-east-1"
project_name        = "vpc-lab"
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidr  = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"

allowed_ssh_cidr = "YOUR_PUBLIC_IP/32"

key_name = "vockey"

instance_type = "t2.micro"
```

Lưu ý:

- `allowed_ssh_cidr` là IP public của máy người dùng, ví dụ `113.161.20.10/32`.
- `key_name` là tên Key Pair trên AWS, không phải tên file `.pem`.
- File `.pem` chỉ dùng khi SSH vào EC2.

Kiểm tra Key Pair trên AWS:

```powershell
aws ec2 describe-key-pairs --query "KeyPairs[*].KeyName" --output table
```

---

## 9. Cách triển khai hạ tầng

### Bước 1: Khởi tạo Terraform

```powershell
terraform init
```

### Bước 2: Định dạng source code

```powershell
terraform fmt -recursive
```

### Bước 3: Kiểm tra cấu hình

```powershell
terraform validate
```

Kết quả mong đợi:

```text
Success! The configuration is valid.
```

### Bước 4: Xem kế hoạch triển khai

```powershell
terraform plan
```

### Bước 5: Triển khai hạ tầng

```powershell
terraform apply
```

Nhập:

```text
yes
```

---

## 10. Kiểm tra output sau khi triển khai

Sau khi `terraform apply` thành công, chạy:

```powershell
terraform output
```

Một số output quan trọng:

```text
vpc_id
public_subnet_id
private_subnet_id
internet_gateway_id
nat_gateway_id
public_ec2_public_ip
public_ec2_private_ip
private_ec2_private_ip
```

Lấy riêng Public IP của Public EC2:

```powershell
terraform output -raw public_ec2_public_ip
```

Lấy riêng Private IP của Private EC2:

```powershell
terraform output -raw private_ec2_private_ip
```

---

## 11. Hướng dẫn SSH kiểm tra EC2

### 11.1. SSH vào Public EC2

```powershell
ssh -i .\keys\labsuser.pem ec2-user@<PUBLIC_EC2_PUBLIC_IP>
```

Ví dụ:

```powershell
ssh -i .\keys\labsuser.pem ec2-user@54.123.45.67
```

### 11.2. Upload key lên Public EC2 để SSH vào Private EC2

```powershell
scp -i .\keys\labsuser.pem .\keys\labsuser.pem ec2-user@<PUBLIC_EC2_PUBLIC_IP>:/home/ec2-user/labsuser.pem
```

### 11.3. SSH từ Public EC2 vào Private EC2

Sau khi SSH vào Public EC2, chạy:

```bash
chmod 400 labsuser.pem
ssh -i labsuser.pem ec2-user@<PRIVATE_EC2_PRIVATE_IP>
```

Ví dụ:

```bash
ssh -i labsuser.pem ec2-user@10.0.2.45
```

### 11.4. Xóa key khỏi Public EC2 sau khi test

```bash
rm -f /home/ec2-user/labsuser.pem
```

---

## 12. Test NAT Gateway

Sau khi SSH vào Private EC2, chạy:

```bash
curl -I https://aws.amazon.com
```

Nếu có HTTP response trả về, nghĩa là Private EC2 có thể truy cập Internet thông qua NAT Gateway.

Có thể kiểm tra thêm bằng lệnh:

```bash
sudo dnf update -y
```

---

## 13. Test cases

| Test case | Mục tiêu                                   | Lệnh hoặc cách kiểm tra                    | Kết quả mong đợi                         |
| --------- | ------------------------------------------ | ------------------------------------------ | ---------------------------------------- |
| TC01      | Kiểm tra AWS credentials                   | `aws sts get-caller-identity`              | Trả về Account ID và Arn                 |
| TC02      | Kiểm tra Terraform syntax                  | `terraform validate`                       | `Success! The configuration is valid.`   |
| TC03      | Kiểm tra plan                              | `terraform plan`                           | Hiển thị danh sách resource sẽ tạo       |
| TC04      | Tạo hạ tầng                                | `terraform apply`                          | Apply complete                           |
| TC05      | Kiểm tra VPC                               | AWS Console hoặc `terraform output vpc_id` | Có VPC `vpc-lab-vpc`                     |
| TC06      | Kiểm tra Public Subnet                     | AWS Console hoặc output                    | Có Public Subnet `10.0.1.0/24`           |
| TC07      | Kiểm tra Private Subnet                    | AWS Console hoặc output                    | Có Private Subnet `10.0.2.0/24`          |
| TC08      | Kiểm tra Internet Gateway                  | AWS Console                                | Internet Gateway attached vào VPC        |
| TC09      | Kiểm tra NAT Gateway                       | AWS Console                                | NAT Gateway ở trạng thái Available       |
| TC10      | Kiểm tra Public Route Table                | AWS Console > Route Tables                 | Có route `0.0.0.0/0 -> Internet Gateway` |
| TC11      | Kiểm tra Private Route Table               | AWS Console > Route Tables                 | Có route `0.0.0.0/0 -> NAT Gateway`      |
| TC12      | Kiểm tra Public EC2 SSH                    | `ssh -i key ec2-user@public_ip`            | SSH thành công                           |
| TC13      | Kiểm tra Private EC2 SSH                   | SSH từ Public EC2 sang Private EC2         | SSH thành công                           |
| TC14      | Kiểm tra Private EC2 đi Internet           | `curl -I https://aws.amazon.com`           | Có HTTP response                         |
| TC15      | Kiểm tra Private EC2 không expose Internet | AWS Console > EC2                          | Private EC2 không có Public IPv4         |

---

## 14. Bảo mật

Dự án áp dụng các cấu hình bảo mật sau:

- Public EC2 chỉ mở SSH port 22 cho IP public cụ thể của người dùng.
- Private EC2 không có Public IP.
- Private EC2 chỉ cho phép SSH từ Public EC2 Security Group.
- Không mở SSH toàn Internet bằng `0.0.0.0/0`.
- File `.pem`, `terraform.tfvars`, `.terraform` và state file không được commit lên GitHub.

File `.gitignore`:

```gitignore
.terraform/
*.tfstate
*.tfstate.*
terraform.tfvars
*.pem
.terraform.lock.hcl
crash.log
```

---

## 15. Dọn tài nguyên

Sau khi hoàn thành kiểm thử và chụp ảnh báo cáo, cần xóa tài nguyên để tránh phát sinh chi phí:

```powershell
terraform destroy
```

Nhập:

```text
yes
```

Sau đó kiểm tra lại trên AWS Console để đảm bảo các tài nguyên đã được xóa.

---

## 16. Link báo cáo và source code

- Link GitHub source code: `<Dán link GitHub tại đây>`
- Báo cáo Word: nộp theo yêu cầu của giảng viên.
