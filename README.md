# Radio Resource Allocation for Beam Hopping Scheduling in LEO Satellite Communications: A Spatio-Temporal Perspective

[![MATLAB](https://img.shields.io/badge/MATLAB-R2024a-blue.svg)](https://www.mathworks.com/products/matlab.html)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Fixed-brightgreen.svg)](https://github.com/yuanhaobupt/leo-bh-scheduling/releases)

> **⚠️ 重要更新 (2026-03-11): 所有代码错误已修复！**
> 
> 如果您之前克隆过此仓库，请立即更新：
> ```bash
> git pull origin main
> ```
> 
> 详见 [修复报告](FIXES_COMPLETED.md) 和 [更新日志](CHANGELOG.md)

---

This repository contains the MATLAB implementation of the Radio Resource Allocation for Beam Hopping Scheduling in LEO Satellite Communications: A Spatio-Temporal Perspective.

## 📋 Overview

This project addresses the beam-hopping (BH) scheduling problem in LEO satellite communications, where a satellite dynamically illuminates multiple cells within its coverage area to maximize service satisfaction while managing interference constraints.

### Key Features

- **Tabu Search with Simulated Annealing (SA)**: Hybrid metaheuristic combining tabu search's memory mechanism with SA's probabilistic acceptance
- **Adaptive Tabu Tenure**: Dynamic tabu list size based on problem scale ($L_{tabu} = \lfloor\sqrt{N_b} \cdot \sqrt{N_m}\rfloor$)
- **Interference-Aware Scheduling**: Spatial separation constraints to minimize co-channel interference
- **User-Centric KPIs**: Comprehensive performance metrics including throughput percentiles, fairness, and service satisfaction

## 🚀 Quick Start

### Prerequisites

- MATLAB R2024a or later
- Required toolboxes:
  - Communications Toolbox
  - Optimization Toolbox (optional, for baseline comparison)
- **Satellite Orbit Data**: This project requires satellite orbit data files (`5400.mat` or `1800.mat`) containing position information. See [DATA_REQUIREMENT.md](DATA_REQUIREMENT.md) for details on how to obtain or generate these files.

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/leo-bh-scheduling.git

# Navigate to the project directory
cd leo-bh-scheduling

# Open MATLAB and add to path
addpath(genpath('.'));
```

### Running a Simple Example

```matlab
% Load default configuration
setConfig;

% Run a quick test (single scheduling period)
controller = simSatSysClass.simController(Config, 1, 1, 0);
DataObj = controller.run();

% Calculate performance metrics
KPIs = calcuUserKPIs(DataObj);
```

## 📁 Repository Structure

```
leo-bh-scheduling/
│
├── +methods/                    # Algorithm implementations
│   ├── BHST_MY.m               # Original Tabu Search
│   ├── BHST_MY_SA.m            # Tabu Search with SA
│   ├── BHST_greedy.m           # Greedy baseline
│   ├── BHST_DQN.m              # DQN baseline
│   └── Evolution.m             # Genetic Algorithm baseline
│
├── +simSatSysClass/            # Simulation framework
│   ├── @simController/         # Main controller
│   ├── @simInterface/          # Data interface
│   ├── @dataObj/               # Result storage
│   └── +tools/                 # Utility functions
│
├── utils/                      # Helper utilities
│   ├── calcuUserKPIs.m         # User-centric KPI calculation
│   ├── generateTraffic.m       # Traffic demand generation
│   └── perform_statistics.m    # Statistical analysis
│
├── visualize/                  # Visualization tools
│   ├── plot_SINR_CDF.m
│   ├── plot_Throughput_Comparison.m
│   └── plot_ablation_results.m
│
├── results/                    # Experiment results (git-ignored)
│
├── setConfig.m                 # Configuration script
├── run_ablation_SA_v3.m        # SA ablation experiment
├── run_ablation_Ltabu.m        # Tabu tenure ablation
├── run_traffic_skew_experiment.m  # Traffic skew experiment
│
└── README.md                   # This file
```

## 🔬 Experiments

### 1. SA Mechanism Ablation

Compare the proposed method (Tabu + SA) against Tabu-only baseline:

```matlab
run('run_ablation_SA.m')
```

**Expected Results:**
| Variant | Throughput (Mbps) | Satisfaction (%) |
|---------|------------------|------------------|
| Tabu + SA | 202.6 | 85.0 |
| Tabu-only | 189.3 | 82.5 |

### 2. Tabu Tenure Ablation

Compare adaptive vs. fixed tabu tenure:

```matlab
run('run_ablation_Ltabu.m')
```

**Expected Results:**
| Configuration | Throughput (Mbps) | Satisfaction (%) |
|---------------|------------------|------------------|
| Fixed L=10 | 178.5 | 79.8 |
| Fixed L=20 | 195.2 | 82.5 |
| Fixed L=30 | 188.3 | 81.2 |
| **Adaptive** | **202.6** | **85.0** |

### 3. Traffic Skew Experiment

Test performance under different traffic distributions:

```matlab
run('run_traffic_skew_experiment.m')
```

**Traffic Modes:**
- **Uniform**: All users have identical demands
- **Light Skew**: 2× demand variance
- **Heavy Skew**: 5× demand variance
- **Pareto (80/20)**: 20% users account for 80% demand

## ⚙️ Configuration

Key parameters can be modified in `setConfig.m`:

```matlab
% Satellite parameters
heightOfSat = 508e3;           % Orbital altitude (m)
numOfServbeam = 10;            % Number of beams

% Scheduling parameters
BhDispCycle = 40e-3;           % Scheduling period (s)
SubCarrierSpace = 30e3;        % Subcarrier spacing (Hz)

% Traffic parameters
meanUsrsNum = 800;             % Average number of users
traffic_mode = 'uniform';      % Traffic distribution mode

% Algorithm parameters
enable_SA = true;              % Enable SA mechanism
L_tabu_mode = 'adaptive';      % Tabu tenure mode
```

## 📊 Performance Metrics

The framework calculates the following user-centric KPIs:

| Metric | Description |
|--------|-------------|
| **Throughput** | Average, p50, p90, p95 percentiles |
| **SINR** | Signal-to-Interference-plus-Noise Ratio |
| **Outage Rate** | Users with SINR < 0 dB |
| **Service Satisfaction** | Transported/Requested traffic ratio |
| **Fairness Index** | Jain's Fairness Index |
| **Delay** | Average and p95 latency |

Example usage:

```matlab
KPIs = calcuUserKPIs(DataObj);
fprintf('Average Throughput: %.2f Mbps\n', KPIs.avg_throughput/1e6);
fprintf('p90 Throughput: %.2f Mbps\n', KPIs.p90_throughput/1e6);
fprintf('Fairness Index: %.4f\n', KPIs.fairness_index);
```

## 📈 Complexity Analysis

**Time Complexity (per iteration):**
$$T_{iter} = O(|N(x)| \cdot N_b \cdot K)$$

Where:
- $|N(x)|$: Neighborhood size (default: 10)
- $N_b$: Number of beams (default: 10)
- $K$: Average users per beam (default: 80)

**Space Complexity:**
$$S_{total} = O(L_{tabu} \cdot N_b + N_m^2)$$

**Typical Performance:**
- Computation time: ~5 seconds (50 iterations)
- Memory usage: <100 MB
- Suitable for real-time satellite scheduling

## 📝 Citation

Waiting...

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📧 Contact

For questions or issues:
- **Hao Yuan** - [Email](mailto:yuan_hao@bupt.edu.cn)



---

**Note**: This code is provided for academic research purposes. For commercial use, please contact the authors.
