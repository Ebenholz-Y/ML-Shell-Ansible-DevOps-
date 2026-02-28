# ML部署基准测试实验材料

## 🔧 技术栈
- **自动化工具**：Bash 脚本、Ansible
- **组件**：NVIDIA 驱动、CUDA 12.x、cuDNN、PyTorch（CUDA 版）、Jupyter Lab
- **操作系统**：Ubuntu 20.04 / 22.04 LTS


## 脚本说明
- `benchmark.sh`: 测量不同系统（Ubuntu/RHEL）上ML环境部署耗时。
- `perf_test.sh`: 测量调优前后矩阵乘法性能。

## 运行方式
```bash
./benchmark.sh      # 自动识别系统并测试
./perf_test.sh raw  # 调优前测试
./perf_test.sh tuned # 调优后测试

chmod +x 输入对应脚本名.sh
sudo 输入对应脚本名.sh [参数]
```

## 运行方式
单机环境配置时间从 2 小时缩短至 10 分钟
实现 100% 环境一致性，消除配置漂移
已被校内 3 个科研小组采纳使用
输出《面向科研团队的 ML 环境标准化实践》技术报告

## 📸 效果截图（详参输出例文件及截图）
RHEL系统:

<img width="490" height="192" alt="RHEL部署流程耗时" src="https://github.com/user-attachments/assets/2670b27d-91cf-407d-974f-465ab30f8fb1" />

<img width="563" height="406" alt="RHEL调优前后数据对比" src="https://github.com/user-attachments/assets/0297da39-0f28-4655-bbe2-340de0957beb" />

Ubuntu系统：

<img width="531" height="202" alt="Ubuntu部署流程耗时" src="https://github.com/user-attachments/assets/3f471af3-0037-4eae-b642-0819bd5a4552" />

<img width="661" height="272" alt="Ubuntu调优前数据" src="https://github.com/user-attachments/assets/801dbb1c-65f2-4bdb-8ff3-cb83c96707dc" />

<img width="577" height="294" alt="Ubuntu调优后数据" src="https://github.com/user-attachments/assets/8a32ec37-5b3f-458b-b229-af5ea18c691f" />




