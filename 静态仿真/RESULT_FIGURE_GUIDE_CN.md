# 结果图含义与预期趋势说明

本文档说明当前静态 USV-AUV 协同导航项目中主要结果图的含义，以及在当前模型设定下通常应看到的结果趋势。实际数值以每次运行生成的表格和图片为准。

## Figure 1: 编队几何与误差椭圆

入口脚本：`main_fig1_ellipse_paper.m`

含义：展示 line、wedge、polygon 三类 USV 编队在 RTK-like 和 GNSS-degraded 条件下的几何布局、AUV 位置、声学测距视线以及 95% 定位误差椭圆。

预期结果：GNSS 锚点误差增大时，所有编队误差椭圆都会变大。line 编队通常方向性最强，椭圆更容易拉长；wedge 和 polygon 对二维几何约束更均衡，误差椭圆更圆、更稳定。该图主要支撑“编队几何直接影响可观测性和误差各向异性”的论述。

## Figure 2: 间距敏感性

入口脚本：`main_fig2_spacing_paper.m`

含义：扫描 USV 相邻间距 `s`，比较不同编队在共同可行声学更新率下的水平 RMSE 下界。图中的浅绿色区域表示满足目标 RMSE 的区间，星形标注表示当前曲线组中的最优点。

预期结果：过小间距会造成几何基线不足，定位精度较差；增大间距通常改善几何约束，但过大间距会受到声学传播周期和更新率上限约束。一般会出现一个中等或偏大的有效间距区间，而不是“越大越好”的单调结论。

## Figure 3: Wedge 开口角敏感性

入口脚本：`main_fig3_wedge_angle_paper.m`

含义：只针对 wedge 编队，扫描开口角 `beta`，分析不同间距下角度对 RMSE 的影响。

预期结果：开口角过小时 wedge 会退化得接近 line，二维约束变弱；开口角过大时部分 USV 的几何贡献和声学代价可能变差。通常 90 到 120 度附近会更稳健，但最优角度会随间距、GNSS 误差和声学更新率变化。

## Figure 4: 声学更新率敏感性与物理上限

入口脚本：`main_fig4_rate_paper.m`

含义：展示请求声学更新率对定位下界的影响，并区分物理可行区域和被声学传播周期限制后的 capped 曲线。独立的物理上限图给出每类编队在当前几何下的最大可行更新率。

预期结果：提高声学更新率会降低 RMSE，但收益会逐渐饱和。超过物理上限后，请求频率不再真实可行，因此 solid 曲线会中断，dashed capped 曲线表示按物理上限截断后的理论效果。编队 footprint 越大、USV 数越多，通常物理更新率上限越低。

## Figure 5: GNSS 退化影响

入口脚本：`main_fig5_gnss_degradation_paper.m`

含义：扫描 USV GNSS 锚点误差，观察定位 RMSE 和对 GNSS 误差的灵敏度。

预期结果：GNSS 误差越大，AUV 定位 RMSE 通常单调增大。较好的编队不仅 RMSE 较低，而且灵敏度曲线更平缓。曲线穿过目标 RMSE 的位置可解释为该编队在当前设置下可承受的 GNSS 退化上限。

## Figure 6: 空间精度图与最佳编队区域

入口脚本：`main_fig6_spatial_precision_map.m`

含义：把 AUV 放到不同相对位置，绘制每类编队的空间 RMSE 分布、三维误差面，以及不同位置下的最佳编队类型区域。

预期结果：polygon 或 wedge 通常在 AUV 位于编队包围区域或开口覆盖区域附近更有优势；line 在某些方向上可能有局部优势，但整体各向异性更强。白色虚线目标等值线可用来判断哪些空间区域满足定位精度要求。

说明：`Fig6_spatial_precision_maps` 中颜色表示 RMSE 大小，USV 锚点使用中性黑色，避免把 family 颜色误读成 RMSE 色标。`Fig6_best_family_regions` 使用离散 RGB 分类底图，颜色直接表示获胜 family，不表示 RMSE 大小；该图不再叠加三族 USV 锚点，因为三族编队并不是同时部署的。`Fig6_best_family_masks` 将三类 family 的获胜区域拆成三个分面，便于单独观察每一类编队在哪些 AUV 位置上最优。

## Geometry Fairness: Wedge/Polygon 公平性诊断

入口脚本：`main_paper_geometry_fairness.m`

含义：补充三组实验解释为什么某些原始设置下 wedge 可能优于 polygon。

实验 A 固定 footprint：将 line、wedge、polygon 缩放到相同最大锚点间距，再比较 RMSE。若 polygon 明显改善或超过 wedge，说明原先固定 `s` 的设置可能让 wedge 获得了更大的实际尺度。

实验 B 目标在中心：将目标严格放在编队中心，并分为 `center-stationary` 和 `center-moving` 两种情况。该实验只比较 wedge 和 polygon，不纳入 line，因为 line 在中心附近二维几何退化明显，会拉大图的纵轴并干扰 wedge/polygon 展示。若静止中心下 polygon 的 RMSE 或误差椭圆轴比更优，而从中心运动后 wedge 变强，说明动态模型和目标运动方向改变了“中心包围”的优势。

实验 C 固定平均锚点距离：将三类编队缩放到与 AUV 相同的平均水平距离，再比较 RMSE。若结果变化明显，说明原始比较中可能存在“某个编队整体离 AUV 更近”的距离偏置。

预期结果：在目标严格位于 polygon 中心且角度分布均匀时，polygon/circular 的 FIM 应更接近各向同性，因此误差椭圆轴比应更接近 1。wedge 可能在目标偏离中心或沿某一方向运动时取得接近甚至更好的局部效果。

## Scheme 1: 多场景离线设计规则

入口脚本：`main_scheme1_offline.m`

含义：在多个 AUV 方位场景下，寻找满足目标 RMSE 所需的最小间距、最小声学更新率、最小 USV 数量，并估计间距、更新率、数量三类变量的局部重要性。

预期结果：GNSS 误差增大时，满足目标精度通常需要更大的几何间距、更高声学更新率或更多 USV。变量重要性反映当前设计附近最敏感的调参方向：若 spacing 重要性高，说明几何尺度是主要瓶颈；若 rate 重要性高，说明声学更新频率是主要瓶颈；若 count 重要性高，说明增加 USV 数量可能更有效。

## Scheme 1 Spacing Limit: 间距有效上限诊断

入口脚本：`main_scheme1_spacing_limit.m`

含义：诊断不同 family 的最小有效间距、最优间距和可接受间距上界。

预期结果：间距通常存在有效范围。小于下界时几何约束不足，大于上界时声学更新率、代价或几何边际收益会限制继续增大间距的价值。

## Scheme 2: 鲁棒固定策略选择

入口脚本：`main_scheme2_robust_paper.m`

含义：在 GNSS 误差网格上为每类编队寻找 family-best 固定策略，并通过 RMSE、超标量、成本分解和策略表选择全局鲁棒策略。

预期结果：鲁棒策略不一定是单点 RMSE 最低的策略，而是在 GNSS 退化、物理可行性和工程成本之间折中最好的策略。当前模型下 wedge 经常表现为较强候选，因为它兼顾二维几何约束、声学 footprint 和成本。

## Scheme 3: Monte Carlo / EKF 验证

入口脚本：`main_scheme3_mc_verify_paper.m`

含义：用 Monte Carlo EKF 仿真验证 BCRLB 下界分析。图中包括时间 RMSE、最终 RMSE 与 BCRLB 对比、所有 family 的最终误差云和误差椭圆、鲁棒策略散点图，以及对比策略散点图。

预期结果：Monte Carlo RMSE 应接近并略高于 BCRLB；若 MC/BCRLB 比值过大，说明滤波器、运动模型或量测模型存在不一致。鲁棒策略的误差云应更集中，误差椭圆应较小或更均衡。

## Baseline Ablation: 基线对比

入口脚本：`main_paper_baseline_ablation.m`

含义：把协同编队策略与 dead-reckoning、single-USV、未优化示例编队和随机布局等基线区分比较。弱基线采用 log 轴单独展示，公平基线使用相近协同资源进行比较。

预期结果：dead-reckoning 和 single-USV 通常显著差于多 USV 协同策略，因此只适合说明协同导航的必要性。公平基线图应体现优化编队相对于未优化或随机布局的稳定收益，而不是被量级差异压缩到没有参考意义。

## Noise Sensitivity: 噪声敏感性

入口脚本：`main_paper_noise_sensitivity.m`

含义：扰动声学测距噪声 `sigma_range` 和过程加速度噪声 `sigma_acc`，观察鲁棒策略的 RMSE 和 95% 椭圆面积变化。

预期结果：测距噪声或过程噪声增大时，RMSE 和面积通常增大。归一化图用于判断结论是否依赖某个特定噪声设定：若曲线平滑且不突然跨越目标线，说明结论更稳健。

## Pareto Analysis: 精度-成本-尺度-频率权衡

入口脚本：`main_paper_pareto_analysis.m`

含义：在 RMSE、成本、footprint 和声学更新率之间做多目标 Pareto 分析，并单独标出满足目标 RMSE 的 target-feasible Pareto 设计。

预期结果：低成本设计通常精度略差，高精度设计通常需要更大 footprint、更高更新率或更多 USV。推荐对比集合应优先来自 target-feasible Pareto 点，因为它们在满足目标精度的前提下没有明显被其它方案支配。

## 论文出图入口

推荐入口：`main_paper_run_all.m`

含义：按论文顺序运行主要结果图、Scheme 1-3、基线、敏感性和 Pareto 分析，并导出 `paper_outputs/<timestamp>/figures` 与 `tables`。

预期结果：输出文件夹中应包含所有论文图的 PNG/FIG 文件和核心 CSV 表格。若只想快速预览 Scheme 3，可运行 `main_scheme3_mc_verify_paper('tune')`；正式结果使用默认 `paper` 模式。
