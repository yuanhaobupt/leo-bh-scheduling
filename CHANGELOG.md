# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-03-11

### 🐛 Fixed - Critical Bugs

#### Missing Initializations (run.m)
- **Fixed**: Added `calcuVisibleSat()` call to initialize visible satellites before they are accessed
- **Fixed**: Added `getTriCoord()` call to calculate triangle vertex coordinates 
- **Fixed**: Created `scheduler` object before calling its methods (was undefined)
- **Impact**: Code now runs successfully without "Index exceeds array bounds" errors

#### Duplicate Code Blocks (5 files)
- **Fixed** `+simSatSysClass/@simController/calcuVisibleSat.m`: Removed duplicate code at lines 217-267
- **Fixed** `+simSatSysClass/@schedulerObj/getCurUsers.m`: Removed duplicate loops at lines 29-38 and 109-119
- **Fixed** `+simSatSysClass/@simInterface/simInterface.m`: Removed duplicate property definitions at lines 116-143
- **Impact**: Eliminated syntax errors and improved code maintainability

#### Orphaned Brackets (4 files)
- **Fixed** `+simSatSysClass/@simController/getNeighborSat.m`: Removed orphan `)` at line 213
- **Fixed** `+simSatSysClass/@schedulerObj/generateBHST.m`: Removed orphan `)` at line 88
- **Fixed** `+methods/UsrsTraffic_Method.m`: Removed orphan `)` at line 72
- **Impact**: Fixed "Invalid expression" syntax errors

### ✨ Added - New Features

#### +tools Package (5 utility functions)
- **LatLngCoordi2Length.m**: Calculate distance between two geographic coordinates using Haversine formula
- **getEarthLength.m**: Calculate satellite beam ground projection length
- **find3dBAgle.m**: Calculate 3dB beamwidth angle based on frequency band (S/Ku/Ka)
- **getPointAngleOfUsr.m**: Calculate elevation and azimuth angles from satellite to user
- **findPointXY.m**: Convert latitude/longitude to Earth-Centered Earth-Fixed (ECEF) Cartesian coordinates
- **Impact**: Resolved all "Unable to find function 'tools.xxx'" errors

#### +antenna Package (3 antenna functions)
- **getSatAntennaServG.m**: Calculate satellite antenna gain pattern using Gaussian approximation
- **getUsrAntennaServG.m**: Calculate user terminal antenna gain (omnidirectional/directional)
- **initialUsrAntenna.m**: Initialize user antenna configuration with standard parameters
- **Impact**: Enabled antenna gain calculations for link budget analysis

#### Testing & Documentation
- **test_fix.m**: Comprehensive test script with performance metrics output
- **debug_visible_sat.m**: Debug script for satellite visibility verification
- **apply_all_fixes.m**: Automated fix application script (for future reference)
- **BUGFIX_CHECKLIST.md**: Detailed checklist of all fixes with line numbers
- **FIXES_COMPLETED.md**: Summary report with test results
- **GITHUB_SUBMISSION_GUIDE.md**: Step-by-step guide for GitHub submission
- **Impact**: Improved code maintainability and user support

### 🔧 Changed - Improvements

#### Satellite Data Generation
- **Improved** `utils/generate_test_satellite_data.m`:
  - Now ensures satellites pass through the research area [102-108°E, 26-30°N]
  - Added verification of coverage at t=0
  - Better distribution of satellites across orbital planes
  - **Impact**: Tests now have guaranteed satellite visibility

#### Configuration
- **Enhanced** error handling and debug messages in multiple functions
- **Improved** code comments and documentation

### 📊 Performance

Test results after fixes (single scheduling period, 800 users, 7 visible satellites):

| Metric | Value | Status |
|--------|-------|--------|
| **Average SINR** | 9.82 dB | ✅ Good |
| **Median SINR** | 10.00 dB | ✅ Good |
| **SINR p90** | 11.38 dB | ✅ Good |
| **Outage Rate (<0 dB)** | 0.00% | ✅ Excellent |
| **Average Delay** | 48.59 ms | ✅ Good |
| **Jain Fairness Index** | 0.9898 | ✅ Excellent |
| **Avg Satisfaction Rate** | 85.03% | ✅ Good |
| **SSR@80%** | 66.88% | ✅ Good |
| **SSR@90%** | 32.88% | ✅ Acceptable |

### 🔒 Security

- No security issues identified
- All input validation maintained

### 📝 Documentation

- Updated README.md with prominent update notice
- Added inline comments for complex calculations
- Created comprehensive troubleshooting guide

### 🗑️ Deprecated

- None in this release

### ❌ Removed

- Removed duplicate code blocks (5 files)
- Removed orphaned brackets (4 files)

---

## [1.0.0] - Initial Release

### Added
- Initial implementation of Tabu Search algorithm
- Beam hopping scheduling framework
- User traffic generation
- Performance metric calculation
- Visualization tools
- Basic documentation

---

## [Unreleased]

### Planned Features
- [ ] Integration with STK for real orbit data
- [ ] Machine learning-based beam scheduling (DQN)
- [ ] Multi-beam coordination
- [ ] Real-time visualization dashboard
- [ ] Python interface
- [ ] Docker container for easy deployment

### Known Issues
- Satellite orbit data uses synthetic model (not STK-generated)
- Some functions may need optimization for large-scale scenarios
- Documentation could be more detailed for new users

---

## Version History

- **v1.1.0** (2026-03-11): Critical bug fixes and missing functions added
- **v1.0.0** (Initial): Original implementation

---

## Migration Guide

### From v1.0.0 to v1.1.0

**If you cloned before 2026-03-11**, you need to:

1. **Update your local repository**:
   ```bash
   git pull origin main
   ```

2. **Regenerate satellite data** (recommended):
   ```matlab
   generate_test_satellite_data();
   ```

3. **Verify the fixes**:
   ```matlab
   test_fix;
   ```

**Breaking Changes**: None (backward compatible)

**Manual Fix Required**: None (all fixes applied automatically via git pull)

---

## Acknowledgments

Thanks to all users who reported issues and tested the fixes!

---

[Compare v1.0.0...v1.1.0](https://github.com/yuanhaobupt/leo-bh-scheduling/compare/v1.0.0...v1.1.0)
