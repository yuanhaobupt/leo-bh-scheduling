# Release v1.1.0 - Bug Fixes and Improvements

**Release Date**: March 11, 2026
**Status**: Stable ✅

---

## 🎉 Highlights

This release fixes **all critical bugs** that prevented the code from running. The simulation now works correctly out of the box!

### Test Results
```
Average SINR:           9.82 dB
Jain Fairness Index:    0.9898
Average Satisfaction:   85.03%
Outage Rate:            0.00%
```

---

## 🐛 Bug Fixes

### Critical Fixes (Code Now Runs!)

#### 1. Missing Initialization Calls
**Problem**: Code crashed with "Index exceeds array bounds" error
**Fixed**: Added missing initialization calls in `run.m`
- `calcuVisibleSat()` - Initialize visible satellites
- `getTriCoord()` - Calculate triangle coordinates
- `scheduler` object creation

#### 2. Missing Utility Functions
**Problem**: "Unable to find function 'tools.xxx'" errors
**Fixed**: Added two new packages with 8 functions

**+tools package** (5 functions):
- `LatLngCoordi2Length.m` - Geographic distance calculation
- `getEarthLength.m` - Satellite beam ground projection
- `find3dBAgle.m` - 3dB beamwidth calculation
- `getPointAngleOfUsr.m` - Satellite-to-user pointing angles
- `findPointXY.m` - Coordinate transformation

**+antenna package** (3 functions):
- `getSatAntennaServG.m` - Satellite antenna gain
- `getUsrAntennaServG.m` - User terminal antenna gain
- `initialUsrAntenna.m` - Antenna configuration

#### 3. Code Quality Issues
**Fixed**: Removed duplicate code and orphaned brackets in 7 files
- `calcuVisibleSat.m`
- `getCurUsers.m`
- `simInterface.m`
- `getNeighborSat.m`
- `generateBHST.m`
- `UsrsTraffic_Method.m`

---

## ✨ New Features

### Testing & Documentation
- **test_fix.m** - Comprehensive test script with performance metrics
- **apply_all_fixes.m** - Automatic fix application script
- **debug_visible_sat.m** - Satellite visibility debugging tool

### Documentation
- **CHANGELOG.md** - Detailed version history
- **CONTRIBUTING.md** - Contribution guidelines
- **BUGFIX_CHECKLIST.md** - Complete fix checklist
- **FIXES_COMPLETED.md** - Fix completion report
- **GITHUB_SUBMISSION_GUIDE.md** - Submission guide

### Improvements
- Enhanced satellite data generation to ensure coverage
- Better error messages and debugging output
- Improved code comments

---

## 📦 Installation

### New Installation

```bash
git clone https://github.com/yuanhaobupt/leo-bh-scheduling.git
cd leo-bh-scheduling
git checkout v1.1.0
```

### Update Existing Installation

```bash
cd leo-bh-scheduling
git fetch --all --tags
git checkout tags/v1.1.0
```

### MATLAB Setup

```matlab
% Add paths
addpath(genpath('.'));

% Generate test data
generate_test_satellite_data();

% Run test
test_fix;
```

---

## ⚠️ Breaking Changes

**None** - This release is backward compatible with v1.0.0

However, if you have local modifications to the fixed files, you may need to merge changes.

---

## 📊 Performance

### Test Configuration
- **Satellites**: 54 (6 planes × 9 satellites)
- **Users**: 800
- **Beams**: 10 per satellite
- **Duration**: 1 scheduling period (40 ms)

### Results
| Metric | Value | Rating |
|--------|-------|--------|
| Average SINR | 9.82 dB | ✅ Good |
| Median SINR | 10.00 dB | ✅ Good |
| SINR p90 | 11.38 dB | ✅ Good |
| Min SINR | 1.23 dB | ✅ Acceptable |
| Outage (<0 dB) | 0.00% | ✅ Excellent |
| Avg Delay | 48.59 ms | ✅ Good |
| Delay p95 | 93.85 ms | ✅ Good |
| Jain Index | 0.9898 | ✅ Excellent |
| Satisfaction | 85.03% | ✅ Good |
| SSR@80% | 66.88% | ✅ Good |
| SSR@90% | 32.88% | ✅ Acceptable |

---

## 🐞 Known Issues

1. **Satellite Data**: Uses synthetic orbit model, not STK-generated
   - **Workaround**: Generate your own orbit data with STK
   - **Impact**: Functional for testing, but not representative of real constellations

2. **Large-Scale Performance**: May be slow with >2000 users
   - **Workaround**: Reduce user count or increase beam count
   - **Future**: Optimization planned for v1.2.0

---

## 🔮 What's Next?

### Planned for v1.2.0
- [ ] STK integration for real orbit data
- [ ] Performance optimization for large-scale scenarios
- [ ] Additional baseline algorithms
- [ ] Real-time visualization dashboard

### Help Wanted
- [ ] Python interface
- [ ] Docker containerization
- [ ] CI/CD pipeline
- [ ] Additional test cases

See [CONTRIBUTING.md](CONTRIBUTING.md) to get started!

---

## 📝 Upgrade Guide

### From v1.0.0 to v1.1.0

1. **Backup your work** (if you have local changes)
   ```bash
   git stash
   ```

2. **Update to v1.1.0**
   ```bash
   git fetch --all --tags
   git checkout tags/v1.1.0
   ```

3. **Regenerate satellite data** (recommended)
   ```matlab
   generate_test_satellite_data();
   ```

4. **Verify the update**
   ```matlab
   test_fix;
   ```

5. **Restore local changes** (if needed)
   ```bash
   git stash pop
   ```

---

## 🙏 Acknowledgments

Special thanks to all users who reported issues and tested the fixes!

---

## 📞 Support

- **Issues**: https://github.com/yuanhaobupt/leo-bh-scheduling/issues
- **Email**: yuan_hao@bupt.edu.cn
- **Docs**: [README.md](README.md), [CHANGELOG.md](CHANGELOG.md)

---

**Full Changelog**: [v1.0.0...v1.1.0](https://github.com/yuanhaobupt/leo-bh-scheduling/compare/v1.0.0...v1.1.0)
