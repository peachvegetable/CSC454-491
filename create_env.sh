#!/usr/bin/env bash

# Create environment setup script for CSC454-491 Peachy project

echo "Setting up development environment for Peachy iOS app..."

# Check if conda is installed
if ! command -v conda &> /dev/null; then
    echo "Error: conda is not installed. Please install Anaconda or Miniconda first."
    exit 1
fi

# Create conda environment
echo "Creating conda environment '454' with Python 3.11..."
conda create -y -n 454 python=3.11

# Activate the environment
echo "Activating conda environment..."
source $(conda info --base)/etc/profile.d/conda.sh
conda activate 454

# Install Python dependencies (optional - for any backend/API work)
echo "Installing Python dependencies..."
pip install fastapi black pre-commit uvicorn pydantic python-jose[cryptography] python-multipart

# Install pre-commit hooks
echo "Setting up pre-commit hooks..."
cat > .pre-commit-config.yaml << EOF
repos:
  - repo: https://github.com/psf/black
    rev: 23.3.0
    hooks:
      - id: black
        language_version: python3.11
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
EOF

pre-commit install

# Check for Xcode
echo "Checking for Xcode installation..."
if ! command -v xcodebuild &> /dev/null; then
    echo "Warning: Xcode is not installed. Please install Xcode from the Mac App Store."
else
    echo "Xcode found: $(xcodebuild -version | head -n 1)"
fi

# Check for SwiftLint (optional)
if ! command -v swiftlint &> /dev/null; then
    echo "SwiftLint not found. To install: brew install swiftlint"
else
    echo "SwiftLint found: $(swiftlint version)"
fi

# Create .gitignore if it doesn't exist
if [ ! -f .gitignore ]; then
    echo "Creating .gitignore file..."
    cat > .gitignore << EOF
# Xcode
#
# gitignore contributors: remember to update Global/Xcode.gitignore, Objective-C.gitignore & Swift.gitignore

## User settings
xcuserdata/

## compatibility with Xcode 8 and earlier (ignoring not required starting Xcode 9)
*.xcscmblueprint
*.xccheckout

## compatibility with Xcode 3 and earlier (ignoring not required starting Xcode 4)
build/
DerivedData/
*.moved-aside
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3

## Obj-C/Swift specific
*.hmap

## App packaging
*.ipa
*.dSYM.zip
*.dSYM

## Playgrounds
timeline.xctimeline
playground.xcworkspace

# Swift Package Manager
.build/
.swiftpm/

# CocoaPods
Pods/

# Carthage
Carthage/Build/

# fastlane
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots/**/*.png
fastlane/test_output

# Python
__pycache__/
*.py[cod]
*$py.class
.Python
env/
venv/
.env

# IDE
.idea/
.vscode/
*.swp
*.swo
*~

# macOS
.DS_Store
.AppleDouble
.LSOverride

# Thumbnails
._*
EOF
fi

echo ""
echo "✅ Environment setup complete!"
echo ""
echo "To activate the Python environment in the future, run:"
echo "  conda activate 454"
echo ""
echo "To open the Peachy iOS project in Xcode, run:"
echo "  cd Peachy && open Package.swift"
echo ""
echo "Happy coding! 🍑"