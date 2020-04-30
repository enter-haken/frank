#!/bin/bash 
echo "compressing with gzip and brotli"
ls dist/Frank/ -1 | while read line; 
do 
  gzip -c dist/Frank/$line > dist/Frank/$line.gz; 
  brotli -c dist/Frank/$line > dist/Frank/$line.br; 
done
