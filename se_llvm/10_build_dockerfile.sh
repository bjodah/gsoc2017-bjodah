#!/bin/bash
docker build -t ${1:-"bjodah/se_llvm"} environment
