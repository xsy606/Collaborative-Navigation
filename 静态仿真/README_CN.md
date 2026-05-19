# USV-AUV 协同导航静态仿真项目

本项目用于分析静态或准静态 USV 编队辅助 AUV 水下定位的性能。代码比较 `line`、`wedge`、`polygon` 三类编队，包含声学测距物理约束、动态 BCRLB、工程代价、鲁棒策略搜索、Monte Carlo EKF 验证以及论文风格出图。

## 快速开始

在 MATLAB 中进入本目录后运行：

```matlab
cfg = init_workspace();
main_run_smoke_tests
```

生成论文图和表格：

```matlab
cfg = init_workspace('paper');
out = main_paper_run_all();
```

输出会保存在：

```text
paper_outputs/YYYYMMDD_HHMMSS/
  figures/
  tables/
  paper_experiment_summary.txt
```

## 重要入口

- `main_paper_run_all.m`：论文实验总入口。
- `main_paper_geometry_fairness.m`：新增的 wedge/polygon 公平性诊断实验。
- `main_fig6_spatial_precision_map.m`：空间精度图和最佳 family 区域图。
- `main_scheme1_offline.m`：多场景离线设计规则。
- `main_scheme2_robust_paper.m`：鲁棒固定策略选择。
- `main_scheme3_mc_verify_paper.m`：Monte Carlo / EKF 验证。
- `RESULT_FIGURE_GUIDE_CN.md`：每张结果图的含义和预期趋势说明。

## 新增公平性实验

由于原始固定 `s` 的比较中，wedge 和 polygon 的实际 footprint、平均锚点距离和目标相对位置可能并不一致，`main_paper_geometry_fairness.m` 补充了三组诊断：

1. 实验 A：固定 footprint。
   将三类编队缩放到相同最大锚点间距。如果 polygon 在该设置下改善，说明原先 wedge 的优势可能来自尺度不公平。

2. 实验 B：目标严格放在编队中心。
   分别测试 `center-stationary` 和 `center-moving`，且只比较 wedge 与 polygon，不加入 line，避免 line 在中心退化造成纵轴尺度失真。若静止中心下 polygon 更接近各向同性，而运动后 wedge 变强，说明动态目标轨迹会削弱 polygon 的中心包围优势。

3. 实验 C：固定平均锚点距离。
   将三类编队缩放到与 AUV 相同的平均水平距离。如果结果明显变化，说明原始实验可能受“锚点整体更近”影响。

## Figure 6 修正说明

`Fig6_spatial_precision_maps` 中颜色只表示 RMSE，USV 锚点改为中性黑色，避免与 RMSE 色标混淆。

`Fig6_best_family_regions` 中颜色表示最佳 family 类别，不表示 RMSE 大小；该图不再叠加三族 USV 锚点，因为三族编队不是同时部署的。

`Fig6_best_family_masks` 将 line、wedge、polygon 的获胜区域拆成三个分面图，避免单张分类图中边界和图例混在一起看不清。

## 验证建议

快速检查：

```matlab
main_run_smoke_tests
main_paper_geometry_fairness('tune')
main_fig6_spatial_precision_map
```

正式论文结果：

```matlab
out = main_paper_run_all();
```
