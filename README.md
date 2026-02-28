# ML部署基准测试实验材料

## 脚本说明
- `benchmark.sh`: 测量不同系统（Ubuntu/RHEL）上ML环境部署耗时。
- `perf_test.sh`: 测量调优前后矩阵乘法性能。

## 运行方式
```bash
./benchmark.sh      # 自动识别系统并测试
./perf_test.sh raw  # 调优前测试
./perf_test.sh tuned # 调优后测试