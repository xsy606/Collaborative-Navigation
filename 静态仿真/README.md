# USV-AUV Cooperative Navigation MATLAB Project

本项目用于分析 USV 编队辅助 AUV 水下定位的协同导航性能。代码以 MATLAB 脚本为入口，围绕三类 USV 编队（line、wedge、polygon）计算声学测距约束下的动态 BCRLB，搜索满足定位精度要求的工程策略，并用 Monte Carlo EKF 进行验证。

## 快速开始

在 MATLAB 中打开项目根目录，然后运行：

```matlab
cfg = init_workspace();
```

这会递归加入项目路径，加载默认配置，并在 base workspace 中放入：

- `cfg`：默认配置结构体
- `project_root`：项目根目录

如需使用更密的论文绘图网格：

```matlab
cfg = init_workspace('paper');
```

运行全部主要仿真和图：

```matlab
main_run_all
```

单独运行某一部分时，可直接调用对应脚本，例如：

```matlab
main_fig1_ellipse
main_scheme2_robust
main_scheme3_mc_verify
```

## 目录结构

```text
cfg/      全局参数配置
geom/     USV 编队几何生成
model/    BCRLB、声学约束、指标计算、Monte Carlo EKF
scheme/   策略搜索和代价函数
viz/      绘图样式和误差椭圆工具
main_*.m  图表和方案分析入口脚本
```

## 核心配置

主要参数集中在 `cfg/default_config.m`。该函数支持直接指定模式：

```matlab
cfg = default_config('paper');
```

也可以通过 `init_workspace('paper')` 设置当前 MATLAB 会话的默认模式，后续主脚本内部调用 `default_config()` 时会继承该模式。

- `cfg.run.mode`：`tune` 为快速粗网格，`paper` 为更密网格。
- `cfg.target`：仿真步长、时长、AUV 深度和名义状态。
- `cfg.prior`：初始位置和速度先验不确定度。
- `cfg.process`：运动过程噪声。
- `cfg.meas`：声学测距噪声、RTK 类锚点误差、退化 GNSS 误差。
- `cfg.acoustic`：声速、包长、保护间隔、同步开销和声学更新率网格。
- `cfg.example`：示例编队参数 `N`、间距 `s`、楔形角 `beta_deg`、声学更新率 `f`。
- `cfg.requirement.rmse_xy`：水平定位 RMSE 目标。
- `cfg.cost`：船数、覆盖范围、更新率和编队类型的工程代价权重。
- `cfg.grid`：GNSS 误差、间距、船数、楔形角等搜索网格。
- `cfg.mc`：Monte Carlo 运行次数和初值扰动。

## 算法流程

典型计算链如下：

```text
build_formation
  -> acoustic_physical_limit
  -> bcrlb_dynamic
      -> range_snapshot_info_schur
      -> metrics_from_P
  -> family_cost
  -> evaluate_design
```

其中：

- `geom/build_formation.m` 生成 line、wedge、polygon 三类 USV 锚点坐标，并支持整体旋转。
- `model/acoustic_physical_limit.m` 根据声传播往返时间、包长、保护间隔和同步开销计算最大可行声学更新率。
- `model/range_snapshot_info_schur.m` 建立含锚点位置不确定度的增广 Fisher 信息矩阵，并通过 Schur 补得到目标二维位置信息。
- `model/bcrlb_dynamic.m` 在匀速模型和过程噪声下进行动态 BCRLB 递推，并在声学更新时刻注入测距信息。
- `model/metrics_from_P.m` 将二维协方差转换为水平 RMSE、95% 误差椭圆长短轴、面积和条件数。
- `scheme/family_cost.m` 计算工程代价，包括船数、编队 footprint、更新率和编队类型惩罚。
- `model/evaluate_design.m` 是单个设计点的统一评估入口，返回几何、BCRLB 指标、物理可行性和代价。

## 主要入口脚本

| 脚本 | 作用 |
| --- | --- |
| `main_run_all.m` | 依次运行图 1-5 和方案 1-3。 |
| `main_fig1_ellipse.m` | 比较三类编队在 RTK-like 和 GNSS-degraded 条件下的物理布局、95% 误差椭圆和椭圆指标。 |
| `main_fig2_spacing.m` | 扫描 USV 相邻间距 `s`，观察几何尺度对水平 RMSE 下界的影响。 |
| `main_fig3_wedge_angle.m` | 扫描 wedge 开口角 `beta`，分析不同间距下的最佳角度。 |
| `main_fig4_rate.m` | 扫描请求声学更新率，区分物理可行区和受物理上限截断后的性能饱和。 |
| `main_fig5_gnss_degradation.m` | 扫描 GNSS 锚点误差，计算 RMSE 退化曲线和灵敏度。 |
| `main_fig6_spatial_precision_map.m` | 生成不同 AUV 相对位置下的空间精度图和最佳编队类型图。 |
| `main_scheme1_offline.m` | 多场景离线设计规则分析，输出最小间距、最小更新率、最小船数和变量重要性。 |
| `main_scheme1_spacing_limit.m` | 诊断间距的有效上限，包括 `s_min`、`s_opt`、`s_upper`。 |
| `main_scheme2_robust.m` | 在 GNSS 误差网格上为各编队搜索固定最优策略，并选择全局鲁棒策略。 |
| `main_scheme3_mc_verify.m` | 对各 family-best 策略运行 Monte Carlo EKF，比较仿真 RMSE 与 BCRLB。 |
| `main_paper_baseline_ablation.m` | 增加论文基线实验，对比无声学辅助的 dead-reckoning、单 USV 测距和多 USV 协同编队。 |
| `main_paper_noise_sensitivity.m` | 增加论文敏感性实验，考察声学测距噪声和运动过程噪声扰动下的鲁棒策略稳定性。 |
| `main_paper_run_all.m` | 论文实验总入口，运行主要论文图、基线、敏感性、鲁棒策略和 MC 验证，并保存图表。 |

带 `_paper` 后缀的脚本是面向论文风格图件的版本，通常使用更细致的样式和布局。

## 输出变量

多个入口脚本会把关键结果写入 base workspace，便于后续检查：

- `scheme1_out`、`scheme1_summary_table`
- `scheme1_spacing_limit_out`
- `scheme2_summary_table`
- `scheme3_strategy_table`
- `fig4_fmax_table`
- `fig6_spatial_precision_out`
- `paper_baseline_ablation_out`
- `paper_noise_sensitivity_out`
- `paper_run_all_out`

大多数主脚本也会返回结构体，例如：

```matlab
out = main_scheme2_robust();
```

## 论文实验输出

推荐用下面的入口生成投稿前的图表材料：

```matlab
out = main_paper_run_all();
```

该脚本会在项目根目录创建：

```text
paper_outputs/YYYYMMDD_HHMMSS/
  figures/   PNG 和 FIG 格式图件
  tables/    CSV 格式结果表
  paper_experiment_summary.txt
```

新增的论文支撑实验包括：

- 基线对比：无声学辅助 dead-reckoning、单 USV 测距、多 USV 编队策略。
- 敏感性分析：改变声学测距噪声 `sigma_range` 和过程加速度噪声 `sigma_acc`。
- 自动导出：保存当前打开的全部论文图和核心 CSV 表格。

## 修改和扩展建议

1. 调整工况：优先修改 `cfg/default_config.m` 中的 `target`、`meas`、`acoustic` 和 `grid` 字段。
2. 增加新编队：在 `geom/build_formation.m` 添加新 `family`，并在 `scheme/family_cost.m` 中补充代价惩罚。
3. 增加新指标：在 `model/metrics_from_P.m` 中扩展指标，并在 `model/evaluate_design.m` 中写入返回结构体。
4. 改变鲁棒策略评分：修改 `scheme/find_family_best_fixed.m` 和 `scheme/find_global_robust_strategy.m` 中的 `score` 权重。
5. 提高 Monte Carlo 精度：把 `cfg.mc.Nrun` 调大，或切换到 `init_workspace('paper')`。

## 注意事项

- `main_run_all.m` 会连续生成多张图并运行网格搜索，`paper` 模式下耗时会明显增加。
- 物理可行性由 `f_ac <= f_phys_max` 判定；如果声学更新率超过物理上限，设计会被标记为不可行。
- `range_snapshot_info_schur.m` 使用 `cfg.num.min_sigma_anchor` 避免锚点先验方差为零导致数值问题。
- 当前代码主要是仿真和分析脚本，没有外部数据依赖。
