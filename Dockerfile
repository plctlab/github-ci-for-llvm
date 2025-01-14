# ==============================================================================
# Dockerfile to test a branch from a PR
# Pass PR number when building:
#   docker build --build-arg pr_num=NNN .
# ==============================================================================

FROM ubuntu:focal as llvm-base

RUN apt-get upgrade -yqq

RUN apt-get update && apt-get upgrade -yqq && \
     DEBIAN_FRONTEND=noninteractive \
     apt-get -yqq install \
          curl \
          git \
          lsb-release \
          pkg-config \
          python3 \
          python3-pip \
          build-essential \
          cmake \
          ninja-build \
          sudo \
          tzdata

RUN git clone https://github.com/llvm/llvm-project.git

FROM llvm-base as llvm-plct

ARG repo=plctlab/llvm-project
ENV GITHUB_REPOSITORY=$repo
ARG pr_num=1
ENV PR_NUM=$pr_num
ARG sha=xxx

WORKDIR /llvm-project
RUN (git remote add plct https://github.com/${GITHUB_REPOSITORY} && \
     git fetch plct pull/${PR_NUM}/head:ci-${PR_NUM} && \
     git checkout ci-${PR_NUM})


FROM llvm-plct as llvm-precheck
RUN git fetch -v --all
RUN echo "TODO: Add code sytle check here."


FROM llvm-plct as llvm-debug-build
RUN mkdir build
WORKDIR /llvm-project/build
# ENV MAX_LINK_JOBS $(free --giga | grep Mem | awk '{print int($2 / 16)}')
RUN cmake \
    CMAKE_BUILD_TYPE="Debug" \
    -DLLVM_PARALLEL_LINK_JOBS=8 \
    -DLLVM_TARGETS_TO_BUILD="X86;RISCV" \
    -DLLVM_ENABLE_PROJECTS="clang" \
    -G Ninja ../llvm
RUN ninja

FROM llvm-debug-build as llvm-debug-test
RUN ninja check
