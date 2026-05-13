# AWS VPC Lab - Terraform and CloudFormation

## Mục tiêu

Triển khai hạ tầng AWS bằng Terraform và CloudFormation, bao gồm:

- VPC
- Public Subnet
- Private Subnet
- Internet Gateway
- NAT Gateway
- Route Tables
- Security Groups
- Public EC2
- Private EC2

## Region

```text
us-east-1

Công cụ sử dụng
AWS Academy Learner Lab
AWS CLI
Terraform
CloudFormation
GitHub

---

## 1.3. Tạo file test cases ban đầu

Chạy:

```cmd
notepad tests\test-cases.md

# Test Cases

| ID   | Thành phần          | Mục tiêu                                    | Trạng thái |
|------|---------------------|---------------------------------------------|------------|
| TC01 | VPC                 | Kiểm tra VPC được tạo đúng CIDR             | Pending    |
| TC02 | Public Subnet       | Kiểm tra Public Subnet được tạo             | Pending    |
| TC03 | Private Subnet      | Kiểm tra Private Subnet được tạo            | Pending    |
| TC04 | Internet Gateway    | Kiểm tra IGW attach vào VPC                 | Pending    |
| TC05 | Public Route Table  | Kiểm tra route 0.0.0.0/0 qua IGW            | Pending    |
| TC06 | NAT Gateway         | Kiểm tra NAT Gateway available              | Pending    |
| TC07 | Private Route Table | Kiểm tra route 0.0.0.0/0 qua NAT Gateway    | Pending    |
| TC08 | Security Groups     | Kiểm tra rule SSH đúng yêu cầu              | Pending    |
| TC09 | Public EC2          | Kiểm tra Public EC2 có Public IP            | Pending    |
| TC10 | Private EC2         | Kiểm tra Private EC2 không có Public IP     | Pending    |
| TC11 | SSH Public EC2      | Kiểm tra SSH vào Public EC2                 | Pending    |
| TC12 | SSH Private EC2     | Kiểm tra SSH vào Private EC2 qua Public EC2 | Pending    |
| TC13 | NAT Internet Access | Kiểm tra Private EC2 ra Internet qua NAT    | Pending    |
| TC14 | CloudFormation      | Kiểm tra stack CREATE_COMPLETE              | Pending    |

