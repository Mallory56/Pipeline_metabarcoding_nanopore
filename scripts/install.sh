#!/bin/bash

# Check if Conda is installed
if ! command -v conda &> /dev/null; then
    echo "Conda could not be found. Please install Conda and try again."
    exit 1
fi

# Create Conda environments and install required packages
create_env() {
    env_name=$1
    shift
    packages=("$@")
    
    if conda env list | grep -q "${env_name}"; then
        echo "Conda environment '${env_name}' already exists."
    else
        echo "Creating Conda environment '${env_name}'..."
        conda create -y -n "${env_name}" "${packages[@]}"
    fi
}

# Create environment for Python 3.8 with required packages


create_env pip38 python=3.8 cutadapt porechop chopper=0.2.0 vsearch nanostat fastqc

# Create environment for Python 3.7 with emu package
create_env pip37 python=3.7 emu

echo "Conda environments and packages are set up."



