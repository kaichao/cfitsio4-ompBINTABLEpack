#!/bin/bash

if [[ "$ACTION" != "COMPRESS" ]] && [[ "$ACTION" != "DECOMPRESS" ]]; then
    echo "ACTION not COMPRESS/DECOMPRESS, not action"
    exit 0
fi

f=$1
if [ "$ACTION" = "COMPRESS" ]; then
    input_file="/local"${SOURCE_ROOT}/$1
    output_file="/local"${TARGET_ROOT}/$1".fz"
else
    input_file="/local"${SOURCE_ROOT}/$1
    f="/local"${TARGET_ROOT}/$1
    # delete the rightmost three characters .fz
    output_file=${f%???}
fi
output_dir=$(dirname ${output_file})
mkdir -p ${output_dir}
rm -f /work/*.txt

echo -n "start time:" && date --iso-8601=ns
if [ "$ACTION" = "DECOMPRESS" ]; then
    funpack -C -threads ${NUM_THREADS} -O ${output_file} ${input_file}
    echo -n "finish time:" && date --iso-8601=ns
    exit $?
fi

if [[ $ENABLE_RECHECK != 'yes' ]]; then
    fpack -table -C -threads ${NUM_THREADS} -O ${output_file} ${input_file}
    echo -n "finish time:" && date --iso-8601=ns
    exit $?
fi

echo "ENABLE_RECHECK"
in_file=$(basename ${input_file})
out_file=$(basename ${output_file})

cd /work 
cp ${input_file} . \
    && chk0=$(sha1sum ${in_file} | awk '{print $1}') \
    && len0=$(stat --printf="%s" ${in_file}) \
    && fpack -table -C -threads ${NUM_THREADS} ${in_file} \
    && rm -f ${in_file} \
    && chk1=$(sha1sum ${out_file} | awk '{print $1}') \
    && len1=$(stat --printf="%s" ${out_file}) \
    && funpack -C -threads ${NUM_THREADS} ${out_file} \
    && chk2=$(sha1sum ${in_file} | awk '{print $1}') \
    && len2=$(stat --printf="%s" ${in_file}) \
    && cp ${out_file} $(dirname ${output_file})
code=$?
    
# RAM disk insufficient, error code 106
# FITSIO status = 106: error writing to FITS file
# Error writing data buffer to file: Dec+4204_12_05_arcdrift-M11_0926.fitsTmp2
rm -f *fits*

if [[ $code -ne 0 ]]; then
    echo runtime error with recheck, input_file:$1, error_code:$code >&2
    exit $code
fi

if [[ $len0 != $len2 || $chk0 != $chk2 ]]; then 
    echo checksum error while rechecking, input_file:$1 >&2
    exit 201
fi

if [[ $CHECKSUM_FILE != "" ]]; then
    #  orig_file orig_checksum orig_file_len fz_file_checksum fz_file_len
    echo $1 $chk0 $len0 $chk1 $len1 >> /local/${TARGET_URL}/${CHECKSUM_FILE}
fi

echo -n "finish time:" && date --iso-8601=ns
exit $code
