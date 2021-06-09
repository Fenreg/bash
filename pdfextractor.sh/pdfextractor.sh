#!/bin/bash
#==============================================================================
#d NAME: pdfextractor.sh
#d AUTHOR: Clément Feller (cxlfeller--at--gmx<dot>com)
#d PURPOSE: (short descr)
#d CHANGELOG: 2019-05-08 v1.0 first light
#d I/O:
#d <- $1 -> (string) name of input pdf document
#d    $2 -> (string) name of output pdf document
#d    $3 -> (single value) number of page to start extracting from (inclusive)
#d    $4 -> (single value) number of page to finish the extraction on (incl.)
#d -> none
#d
#d USAGE: (example)
#d COMMENTS: (give it a blue thumb)
#d DEPENDANCIES: (compiler version, version of functions used)
#d NOTES: None
#d COPYRIGHT: CC-BY-NC-ND
#==============================================================================
 gs -dFirstPage="$3" -dLastPage="$4" -sOutputFile="$2" \
    -dSAFER -dNOPAUSE -dBATCH -dPDFSETTING=/default -sDEVICE=pdfwrite \
    -dCompressFonts=true -c \
  ".setpdfwrite << /EncodeColorImages true /DownsampleMonoImages false /SubsetFonts true /ASCII85EncodePages false /DefaultRenderingIntent /Default /ColorConversionStrategy \
  /LeaveColorUnchanged /MonoImageDownsampleThreshold 1.5 /ColorACSImageDict << /VSamples [ 1 1 1 1 ] /HSamples [ 1 1 1 1 ] /QFactor 0.4 /Blend 1 >> /GrayACSImageDict \
  << /VSamples [ 1 1 1 1 ] /HSamples [ 1 1 1 1 ] /QFactor 0.4 /Blend 1 >> /PreserveOverprintSettings false /MonoImageResolution 400 /MonoImageFilter /FlateEncode \
  /GrayImageResolution 400 /LockDistillerParams false /EncodeGrayImages true /MaxSubsetPCT 100 /GrayImageDict << /VSamples [ 1 1 1 1 ] /HSamples [ 1 1 1 1 ] /QFactor \
  0.4 /Blend 1 >> /ColorImageFilter /FlateEncode /EmbedAllFonts true /UCRandBGInfo /Remove /AutoRotatePages /PageByPage /ColorImageResolution 400 /ColorImageDict << \
  /VSamples [ 1 1 1 1 ] /HSamples [ 1 1 1 1 ] /QFactor 0.4 /Blend 1 >> /CompatibilityLevel 1.7 /EncodeMonoImages true /GrayImageDownsampleThreshold 1.5 \
  /AutoFilterGrayImages false /GrayImageFilter /FlateEncode /DownsampleGrayImages false /AutoFilterColorImages false /DownsampleColorImages false /CompressPages true \
  /ColorImageDownsampleThreshold 1.5 /PreserveHalftoneInfo false >> setdistillerparams" \
  -f "$1" &>> /tmp/pdfextractor_log.txt
#end
