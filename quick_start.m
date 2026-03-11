% quick_start.m - 最简单的快速开始脚本
% 运行此脚本以快速验证代码是否正常工作
%
% 使用方法:
%   cd('C:\Users\windows\Desktop\leo-bh-scheduling');
%   quick_start;

fprintf('\n');
fprintf('╔══════════════════════════════════════════════════════════╗\n');
fprintf('║     LEO卫星波束调度 - 快速测试                          ║\n');
fprintf('╚══════════════════════════════════════════════════════════╝\n\n');

%% 1. 添加路径
fprintf('[1/4] 添加路径...\n');
addpath(genpath('.'));
fprintf('     ✓ 完成\n\n');

%% 2. 检查卫星数据
fprintf('[2/4] 检查卫星轨道数据...\n');
if ~exist('5400.mat', 'file')
    fprintf('     卫星数据不存在，正在生成...\n');
    generate_test_satellite_data();
else
    fprintf('     ✓ 卫星数据已存在\n');
end
fprintf('\n');

%% 3. 加载配置
fprintf('[3/4] 加载配置...\n');
setConfig;
fprintf('     配置信息:\n');
fprintf('       - 卫星数量: %d\n', 54);
fprintf('       - 用户数量: %d\n', Config.meanUsrsNum);
fprintf('       - 波束数量: %d\n', Config.numOfServbeam);
fprintf('       - 研究区域: [%.1f°-%.1f°E, %.1f°-%.1f°N]\n', ...
    Config.rangeOfInves(1,1), Config.rangeOfInves(1,2), ...
    Config.rangeOfInves(2,1), Config.rangeOfInves(2,2));
fprintf('     ✓ 完成\n\n');

%% 4. 运行快速测试
fprintf('[4/4] 运行仿真测试...\n');
fprintf('     这可能需要几秒钟...\n\n');

try
    tic;
    
    % 创建控制器并运行
    controller = simSatSysClass.simController(Config, 1, 1, 0);
    DataObj = controller.run();
    
    % 计算KPI
    KPIs = calcuUserKPIs(DataObj);
    
    elapsed = toc;
    
    %% 显示结果
    fprintf('\n');
    fprintf('╔══════════════════════════════════════════════════════════╗\n');
    fprintf('║                  测试成功！                              ║\n');
    fprintf('╚══════════════════════════════════════════════════════════╝\n\n');
    
    fprintf('📊 性能指标:\n');
    fprintf('┌─────────────────────────────────────────┐\n');
    fprintf('│ 指标                    │ 值            │\n');
    fprintf('├─────────────────────────┼────────────────┤\n');
    fprintf('│ 平均 SINR              │ %6.2f dB     │\n', KPIs.avg_sinr);
    fprintf('│ 中位数 SINR            │ %6.2f dB     │\n', KPIs.median_sinr);
    fprintf('│ SINR p90               │ %6.2f dB     │\n', KPIs.p90_sinr);
    fprintf('│ 中断率 (<0 dB)         │ %6.2f %%      │\n', KPIs.outage_rate*100);
    fprintf('├─────────────────────────┼────────────────┤\n');
    fprintf('│ 平均延迟               │ %6.2f ms     │\n', KPIs.avg_delay);
    fprintf('│ Jain 公平性指数        │ %6.4f        │\n', KPIs.fairness_index);
    fprintf('│ 平均满意度             │ %6.2f %%      │\n', KPIs.avg_satisfaction*100);
    fprintf('└─────────────────────────────────────────┘\n\n');
    
    fprintf('⏱️  运行时间: %.2f 秒\n\n', elapsed);
    
    fprintf('✅ 所有测试通过！代码运行正常。\n\n');
    
    fprintf('📖 下一步:\n');
    fprintf('   1. 查看 setConfig.m 修改参数\n');
    fprintf('   2. 运行 run_TabuSearch.m 进行完整实验\n');
    fprintf('   3. 查看 visualize/ 文件夹进行结果可视化\n');
    fprintf('   4. 阅读 README.md 了解更多功能\n\n');
    
catch ME
    fprintf('\n');
    fprintf('╔══════════════════════════════════════════════════════════╗\n');
    fprintf('║                  测试失败！                              ║\n');
    fprintf('╚══════════════════════════════════════════════════════════╝\n\n');
    
    fprintf('❌ 错误信息: %s\n', ME.message);
    fprintf('   位置: %s (第 %d 行)\n\n', ME.stack(1).name, ME.stack(1).line);
    
    fprintf('🔍 故障排除:\n');
    fprintf('   1. 确保运行了 git pull origin main\n');
    fprintf('   2. 删除 5400.mat 并重新运行 generate_test_satellite_data()\n');
    fprintf('   3. 查看 FIXES_COMPLETED.md 了解已知修复\n');
    fprintf('   4. 在 GitHub 上提交 issue\n\n');
    
    rethrow(ME);
end
