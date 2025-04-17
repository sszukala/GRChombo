FROM ubuntu:20.04

# Set environment variables to avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    gfortran \
    cmake \
    git \
    wget \
    libhdf5-dev \
    libfftw3-dev \
    liblapack-dev \
    libblas-dev \
    libopenmpi-dev \
    openmpi-bin \
    python3 \
    python3-pip \
    vim \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Set up working directory
RUN mkdir -p /grchombo
WORKDIR /grchombo

# Clone Chombo and GRChombo repositories
RUN git clone https://github.com/GRChombo/Chombo.git && \
    git clone https://github.com/GRChombo/GRChombo.git

# Set environment variables
ENV GRCHOMBO_SOURCE=/grchombo/GRChombo
ENV CHOMBO_HOME=/grchombo/Chombo

# Configure and build Chombo library
WORKDIR /grchombo/Chombo
RUN echo 'DIM              = 3' > Make.defs.local && \
    echo 'DEBUG            = FALSE' >> Make.defs.local && \
    echo 'OPT              = TRUE' >> Make.defs.local && \
    echo 'PRECISION        = DOUBLE' >> Make.defs.local && \
    echo 'CXX              = mpicxx -std=c++14' >> Make.defs.local && \
    echo 'FC               = mpif90' >> Make.defs.local && \
    echo 'MPI              = TRUE' >> Make.defs.local && \
    echo 'USE_HDF          = TRUE' >> Make.defs.local && \
    echo 'HDFINCFLAGS      = -I/usr/include/hdf5/serial' >> Make.defs.local && \
    echo 'HDFLIBFLAGS      = -L/usr/lib/x86_64-linux-gnu/hdf5/serial -lhdf5 -lz' >> Make.defs.local && \
    echo 'HDFMPIINCFLAGS   = -I/usr/include/hdf5/serial' >> Make.defs.local && \
    echo 'HDFMPILIBFLAGS   = -L/usr/lib/x86_64-linux-gnu/hdf5/serial -lhdf5 -lz' >> Make.defs.local && \
    make lib

# Create a simple script to run scalar field cosmo example
RUN echo '#!/bin/bash' > /usr/local/bin/run-scalar-cosmo && \
    echo 'cd /grchombo/GRChombo/Examples/ScalarFieldCosmo' >> /usr/local/bin/run-scalar-cosmo && \
    echo 'if [ ! -f ./ScalarFieldCosmo3d ]; then' >> /usr/local/bin/run-scalar-cosmo && \
    echo '    make' >> /usr/local/bin/run-scalar-cosmo && \
    echo 'fi' >> /usr/local/bin/run-scalar-cosmo && \
    echo 'mpirun -np 2 ./ScalarFieldCosmo3d params.txt' >> /usr/local/bin/run-scalar-cosmo && \
    chmod +x /usr/local/bin/run-scalar-cosmo

# Verify ScalarFieldCosmo exists before trying to build it
RUN if [ ! -d "/grchombo/GRChombo/Examples/ScalarFieldCosmo" ]; then \
        echo "ScalarFieldCosmo example not found!" && \
        find /grchombo/GRChombo/Examples -type d -maxdepth 1 && \
        exit 1; \
    fi

# Build the ScalarFieldCosmo example
WORKDIR /grchombo/GRChombo/Examples/ScalarFieldCosmo
RUN make -j$(nproc)

# Add Python visualization tools
RUN pip3 install matplotlib numpy scipy h5py

# Set default work directory to /workspace (will be mounted from host)
WORKDIR /workspace

CMD ["/bin/bash"]
