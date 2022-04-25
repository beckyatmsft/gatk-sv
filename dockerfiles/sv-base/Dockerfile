# This is the base dockerfile for the GATK SV pipeline that adds R, a few R packages, and GATK
ARG SAMTOOLS_CLOUD_IMAGE=samtools-cloud:latest
ARG VIRTUAL_ENV_IMAGE=sv-base-virtual-env:latest
ARG UBUNTU_RELEASE=22.04
ARG GATK_COMMIT="a33bf19dd3188af0af1bd17bce015eb20ba73227"
ARG GATK_JAR="/opt/gatk.jar"
ARG R_INSTALL_PATH=/opt/R
ARG APT_REQUIRED_PACKAGES="/opt/apt-required-packages.list"

#################### install GATK (needed for PrintSVEvidence)
FROM ubuntu:$UBUNTU_RELEASE as build_gatk
ARG GATK_BUILD_DEP="git git-lfs openjdk-8-jdk"
ARG GATK_RUN_DEP="openjdk-8-jre-headless libgomp1"
ARG GATK_COMMIT
ARG GATK_JAR
ARG DEBIAN_FRONTEND=noninteractive
# install build deps
RUN apt-get -qqy update --fix-missing && \
    apt-get -qqy install --no-upgrade --no-install-recommends \
                 $GATK_BUILD_DEP $GATK_RUN_DEP
# clone requested GATK_COMMIT
RUN git clone https://github.com/broadinstitute/gatk.git && \
    cd gatk && \
    git lfs install && \
    git checkout ${GATK_COMMIT}
# build GATK_JAR
RUN cd gatk && \
    ./gradlew localJar && \
    mv $(readlink -f build/libs/gatk.jar) ${GATK_JAR}
# store the required run dependencies, combined from samtools-cloud image, virtual image, and GATK install
ARG APT_REQUIRED_PACKAGES
RUN mkdir -p $(dirname $APT_REQUIRED_PACKAGES) && \
    printf "$GATK_RUN_DEP" | sed 's/\s\s*/ /g' > $APT_REQUIRED_PACKAGES


#################### get alias for updating required dependencies
FROM $SAMTOOLS_CLOUD_IMAGE as samtools_cloud


#################### remove unneeded R library files and combine required packages before copying
FROM $VIRTUAL_ENV_IMAGE as virtual_env_image
RUN rm_unneeded_r_library_files.sh
RUN mv $APT_REQUIRED_PACKAGES /tmp/r-packages.list
COPY --from=samtools_cloud $APT_REQUIRED_PACKAGES $APT_REQUIRED_PACKAGES
COPY --from=build_gatk $APT_REQUIRED_PACKAGES /tmp/gatk-packages.list
RUN export NEW_PACKAGES=$(diff_of_lists.sh "$(union_lists.sh  /tmp/r-packages.list /tmp/gatk-packages.list)" \
                                           $APT_REQUIRED_PACKAGES) && \
    printf " $NEW_PACKAGES" | fix_spaces.sh >> $APT_REQUIRED_PACKAGES


################## copy GATK and R installs to final image
FROM $SAMTOOLS_CLOUD_IMAGE

# Copy virtual environment
COPY --from=virtual_env_image /opt /opt

# copy GATK jar
ARG GATK_JAR
ENV GATK_JAR=$GATK_JAR
COPY --from=build_gatk $GATK_JAR $GATK_JAR

# Install libraries required for runtime
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get -qqy update --fix-missing && \
    apt-get -qqy install --no-upgrade --no-install-recommends $(fix_spaces.sh $APT_REQUIRED_PACKAGES) && \
    apt-get -qqy clean && \
    rm -rf /tmp/* \
           /var/tmp/* \
           /var/cache/apt/* \
           /var/lib/apt/lists/* \
           /usr/share/man/?? \
           /usr/share/man/??_*

# Add R executables to PATH.
ARG R_INSTALL_PATH
ARG R_INSTALL_BIN=$R_INSTALL_PATH/bin
ENV PATH=$R_INSTALL_BIN:$PATH

# Test that R and GATK can execute
RUN R --version
RUN java -jar ${GATK_JAR}
