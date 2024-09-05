#!/bin/bash

# Create a timestamped folder
FOLDER=$(date +"%Y-%m-%d-%H-%M-%S")
mkdir -p "$FOLDER"

# Change to the new folder
cd "$FOLDER"

# Run Vegeta attack and save results
echo "GET http://localhost:4000/" | vegeta attack -duration=30s -rate=50 -output=results.bin

# Generate text report
vegeta report -type=text results.bin > report.txt

# Generate JSON report
vegeta report -type=json results.bin > report.json

# Generate histogram
vegeta report -type=hist[0,100ms,200ms,300ms] results.bin > histogram.txt

# Generate plot
vegeta plot -title="Load Test Results" results.bin > plot.html

# Display text report
cat report.txt

echo "Reports and visualizations have been saved in the folder: $FOLDER"
