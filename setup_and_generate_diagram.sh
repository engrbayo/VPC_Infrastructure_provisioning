#!/bin/bash

##############################################################################
# VPC Architecture Diagram Generator Setup & Execution Script
##############################################################################

set -e

echo "🚀 Setting up environment for diagram generation..."
echo ""

# Check if Graphviz is installed
if ! command -v dot &> /dev/null; then
    echo "❌ Graphviz not found. Installing via Homebrew..."
    brew install graphviz
else
    echo "✅ Graphviz is installed"
fi

# Create virtual environment
echo ""
echo "📦 Creating Python virtual environment..."
python3 -m venv venv_diagrams

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv_diagrams/bin/activate

# Install diagrams library
echo "📥 Installing diagrams library..."
pip install --upgrade pip
pip install diagrams

# Generate the diagram
echo ""
echo "🎨 Generating architecture diagram..."
python3 generate_architecture_diagram.py

# Deactivate virtual environment
deactivate

echo ""
echo "✅ Done! Architecture diagram generated:"
echo "   📄 File: vpc_architecture_diagram.png"
echo ""
echo "🖼️  Opening diagram..."
open vpc_architecture_diagram.png

echo ""
echo "💡 To regenerate the diagram later, run:"
echo "   source venv_diagrams/bin/activate"
echo "   python3 generate_architecture_diagram.py"
echo "   deactivate"
