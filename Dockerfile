FROM docker.io/ubuntu:bionic
ARG DEBIAN_FRONTEND=noninteractive
# Can not use /temp on our cluster
WORKDIR /temp
COPY . /temp/install/
ENV LANG C.UTF-8  
ENV LC_ALL C.UTF-8

# Update and create base image
RUN apt-get update -y &&\
    apt-get install apt-utils -y &&\
    apt-get install -y file bzip2 default-jre gcc g++ git make ssh unzip wget &&\
    apt-get clean

# Install Anaconda
SHELL ["/bin/bash", "-c"]
RUN wget -q https://repo.anaconda.com/archive/Anaconda3-2019.10-Linux-x86_64.sh &&\
    bash Anaconda3-2019.10-Linux-x86_64.sh -b -p /home/anaconda3
ENV PATH="/home/anaconda3/bin:${PATH}"
RUN conda update -y conda &&\
    conda update -y conda-build

# Install OnTAD
RUN cd /opt && git clone https://github.com/anlin00007/OnTAD.git &&\
    cd OnTAD &&\
    git checkout 3da5d9a4569b1f316d4508e60781f22f338f68b1
RUN              cd /opt/OnTAD/src && make clean && make
ENV PATH="/opt/OnTAD/src:${PATH}"

# Install fastqc
RUN cd /opt && wget http://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.9.zip &&\
    unzip /opt/fastqc_v0.11.9.zip &&\
    chmod +x /opt/FastQC/fastqc
ENV PATH="/opt/FastQC:${PATH}"

# Install ngs_base environment
RUN conda env create -f /temp/install/ngs_base.yml 

WORKDIR /home

# Install bioframe, cooltools and pairlib as well as our own tools
RUN source activate ngs_base &&\
    # Creates a file into the container that logs which version conda installs and all pip installs
    conda list > software_versions.txt &&\
    # Install mirnylabtools - frozen
    pip install git+git://github.com/mirnylab/bioframe@40ca346f8726cf809a16fca4df21298f7c096dc3 &&\
    echo "# pip install git+git://github.com/mirnylab/bioframe@40ca346f8726cf809a16fca4df21298f7c096dc3" >> software_versions.txt &&\
    pip install git+git://github.com/mirnylab/cooltools@26b885356e5fd81dd6f34ef688edc45a020ca9d0 &&\
    echo "# pip install git+git://github.com/mirnylab/cooltools@26b885356e5fd81dd6f34ef688edc45a020ca9d0" >> software_versions.txt &&\
    pip install git+git://github.com/mirnylab/pairlib@34691e24b5c36b8f48266fb386b32b9fbd1210d6 &&\
    echo "# pip install git+git://github.com/mirnylab/pairlib@34691e24b5c36b8f48266fb386b32b9fbd1210d6" >> software_versions_list.txt &&\
    # Install gerlich repos and safe the latest git hash
    # ngs
    githash=`git ls-remote git@github.com:gerlichlab/ngs.git | grep HEAD | cut -f 1` &&\
    pip install git+git://github.com/gerlichlab/ngs@$githash &&\
    echo "# pip install git+git://github.com/gerlichlab/ngs@$githash" >> software_versions.txt &&\
    # cooler_ontad
    githash=`git ls-remote git@github.com:cchlanger/cooler_ontad.git | grep HEAD | cut -f 1` &&\
    pip install git+git://github.com/cchlanger/cooler_ontad@$githash &&\
    echo "# pip install ggit+git://github.com/cchlanger/cooler_ontad@$githash" >> software_versions.txt &&\
    # higlassup
    githash=`git ls-remote git@github.com:Mittmich/higlassupload.git | grep HEAD | cut -f 1` &&\
    pip install git+git://github.com/Mittmich/higlassupload.git@$githash &&\
    echo "# pip install git+git://github.com/Mittmich/higlassupload.git@$githash" >> software_versions.txt

ENV PATH="/home/anaconda3/envs/ngs_base/bin/:${PATH}"

CMD /bin/bash