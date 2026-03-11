# Contributing to LEO Beam Hopping Scheduling

First off, thank you for considering contributing to this project! 🎉

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)

---

## Code of Conduct

This project and everyone participating in it is governed by basic principles of respect and collaboration. By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainer.

---

## How Can I Contribute?

### 🐛 Reporting Bugs

Before creating bug reports, please check the [issue list](https://github.com/yuanhaobupt/leo-bh-scheduling/issues) as you might find out that you don't need to create one.

**When you are creating a bug report, please include as many details as possible:**

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples to demonstrate the steps**
- **Describe the behavior you observed and what you expected**
- **Include screenshots or animated GIFs if helpful**
- **Include your environment details:**
  ```text
  MATLAB version: R2024a
  OS: Windows 11 / macOS 14 / Ubuntu 22.04
  Repository version: v1.1.0
  ```

### 💡 Suggesting Enhancements

Enhancement suggestions are tracked as [GitHub issues](https://github.com/yuanhaobupt/leo-bh-scheduling/issues).

**When creating an enhancement suggestion, include:**

- **Use a clear and descriptive title**
- **Provide a step-by-step description of the suggested enhancement**
- **Provide specific examples to demonstrate the steps**
- **Describe the current behavior and explain the expected behavior**
- **Explain why this enhancement would be useful**

### 🔧 Your First Code Contribution

Unsure where to begin contributing? You can start by looking through these issues:

- `beginner` - issues which should only require a few lines of code
- `help wanted` - issues which should be a bit more involved than beginner issues
- `documentation` - issues related to improving or adding documentation

---

## Development Setup

### 1. Fork and Clone

```bash
# Fork the repository on GitHub, then:
git clone https://github.com/your-username/leo-bh-scheduling.git
cd leo-bh-scheduling

# Add upstream remote
git remote add upstream https://github.com/yuanhaobupt/leo-bh-scheduling.git
```

### 2. MATLAB Setup

```matlab
% Open MATLAB in the project directory
% Add all paths
addpath(genpath('.'));

% Generate test data
generate_test_satellite_data();

% Run tests to verify setup
test_fix;
```

### 3. Keep Your Fork Updated

```bash
# Fetch upstream changes
git fetch upstream

# Merge into your main branch
git checkout main
git merge upstream/main

# Push to your fork
git push origin main
```

---

## Coding Standards

### MATLAB Code Style

We follow MATLAB's official [Programming Guidelines](https://www.mathworks.com/help/matlab/matlab_prog/programming-guidelines.html) with some additions:

#### Naming Conventions

```matlab
% ✅ Good
numOfSatellites = 54;           % Variables: camelCase
function [theta, phi] = getPointAngleOfUsr(...)  % Functions: camelCase
classdef simController < handle  % Classes: PascalCase
properties
    Config                      % Properties: PascalCase
end

% ❌ Avoid
num_satellites = 54;            % Don't use snake_case for variables
```

#### Comments

```matlab
function result = calculateSINR(signal, interference, noise)
% CALCULATESINR Calculate Signal-to-Interference-plus-Noise Ratio
%
%   result = calculateSINR(signal, interference, noise)
%
%   Inputs:
%       signal       - Signal power (W)
%       interference - Interference power (W)
%       noise        - Noise power (W)
%
%   Output:
%       result - SINR in dB
%
%   Example:
%       sinr = calculateSINR(1e-3, 1e-6, 1e-9);
%
%   See also: calcuUserKPIs, calcuInterference

    % Validate inputs
    if signal <= 0 || interference < 0 || noise <= 0
        error('Invalid input values');
    end
    
    % Calculate SINR
    sinr_linear = signal / (interference + noise);
    result = 10 * log10(sinr_linear);
end
```

#### Function Length

- Keep functions under **50 lines** when possible
- If longer, consider splitting into sub-functions
- Each function should do **one thing** well

#### Error Handling

```matlab
% ✅ Good
if ~exist('LLAresult', 'var')
    error('generate_test_satellite_data:MissingData', ...
          'Satellite orbit data not found. Run generate_test_satellite_data() first.');
end

% ❌ Avoid
if ~exist('LLAresult', 'var')
    error('Data not found');
end
```

### Documentation

- **Every function** must have a help comment block
- **Complex algorithms** should have inline comments
- **Update README.md** when adding new features
- **Update CHANGELOG.md** for user-facing changes

---

## Commit Guidelines

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

#### Type

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting, missing semicolons, etc.
- `refactor`: Code change without fixing bug or adding feature
- `perf`: Performance improvement
- `test`: Adding missing tests
- `chore`: Maintenance tasks

#### Examples

```bash
# Feature
feat(algorithm): add simulated annealing mechanism to tabu search

The SA mechanism allows escaping local optima by probabilistically
accepting worse solutions during early iterations.

Fixes #42

# Bug fix
fix(initialization): add missing calcuVisibleSat() call

The VisibleSat array was being accessed before initialization,
causing index out of bounds errors. Added calcuVisibleSat() call
in run.m after area discretization.

# Documentation
docs(readme): add troubleshooting section for satellite data issues

# Refactor
refactor(antenna): simplify gain pattern calculation
```

---

## Pull Request Process

### 1. Create a Branch

```bash
# Create a feature branch
git checkout -b feature/your-feature-name

# Or a bugfix branch
git checkout -b bugfix/issue-description
```

### 2. Make Your Changes

- Write clean, documented code
- Follow the coding standards
- Add/update tests if applicable
- Update documentation

### 3. Test Your Changes

```matlab
% Run the test script
test_fix;

% If you added new functionality, add tests
% Edit test_fix.m to include your tests
```

### 4. Commit Your Changes

```bash
git add .
git commit -m "feat(your-feature): brief description"
```

### 5. Push to Your Fork

```bash
git push origin feature/your-feature-name
```

### 6. Create a Pull Request

1. Go to your fork on GitHub
2. Click "New Pull Request"
3. Fill in the PR template:

```markdown
# Description

Brief description of changes

Fixes # (issue)

## Type of Change

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing

- [ ] I have run `test_fix.m` successfully
- [ ] I have added tests for new functionality
- [ ] All new and existing tests passed

## Checklist:

- [ ] My code follows the style guidelines
- [ ] I have performed a self-review
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works

## Screenshots (if applicable)

## Additional Notes

Any additional information or context
```

### 7. Code Review

- Respond to all review comments
- Make requested changes
- Push new commits (don't squash until merge)
- Be patient and respectful

### 8. After Merge

- Delete your feature branch
- Update your local main branch
- Celebrate! 🎉

---

## Questions?

- Open an issue for bugs or feature requests
- Email: yuan_hao@bupt.edu.cn for private inquiries
- Check existing documentation: [README.md](README.md), [CHANGELOG.md](CHANGELOG.md)

---

## Recognition

Contributors will be recognized in:
- README.md contributors section
- CHANGELOG.md for significant contributions
- GitHub contributors page

Thank you for contributing! 🙏
