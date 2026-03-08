# Satellite Orbit Data Requirement

## Overview

This project requires satellite orbit data files to run simulations. These files contain position information for satellites in the constellation over time.

## Required Files

The code expects one of the following data files:
- `5400.mat` - For satellite network (54 satellites)
- `1800.mat` - For thesis project (18 satellites)

## File Format

The .mat file should contain a variable named `LLAresult` with the following format:
- **Dimensions**: `[Number of satellites × Total simulation steps × 2]`
- **Content**: Longitude and latitude coordinates
- **Format**: 
  - `LLAresult(k, s, 1)` - Longitude of satellite k at simulation step s
  - `LLAresult(k, s, 2)` - Latitude of satellite k at simulation step s

## How to Generate

### Option 1: Using STK (Systems Tool Kit)
1. Create a satellite constellation in STK
2. Set up the desired orbital parameters (altitude: 508km for this project)
3. Generate position data over the simulation period
4. Export to MATLAB .mat format

### Option 2: Using Custom Scripts
You can create synthetic satellite data using orbital mechanics equations. A sample generator script is provided in `utils/generate_satellite_data.m` (if available).



## Quick Start Without Data

If you want to test the code structure without the satellite data:

1. Review the configuration in `setConfig.m`
2. Examine the algorithm implementations in `+methods/`
3. Study the simulation framework in `+simSatSysClass/`

## Note

The .mat data files are excluded from the repository (.gitignore) due to their large size. If you have the data files, place them in the project root directory before running simulations.

## Example Usage

Once you have the data file:

```matlab
% Load configuration
setConfig;

% Run simulation
controller = simSatSysClass.simController(Config, 1, 1, 0);
DataObj = controller.run();

% Calculate KPIs
KPIs = calcuUserKPIs(DataObj);
```

## Troubleshooting

**Error: "Unable to find file 5400.mat"**
- Ensure the .mat file is in the project root directory
- Check that the file name matches what's expected in simController.m (line 194)

**Error: "Variable LLAresult not found"**
- Verify the .mat file contains the correct variable name
- Check the variable dimensions match the expected format
