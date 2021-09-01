#!/bin/bash
cd output
md5sum --status --check hashes
Result=$?
if [[ "$Result" == "0" ]]; then
  Outcome="success"
fi
if [[ "$Result" == "1" ]]; then
  Outcome="failure - md5sums do not match"
fi
echo "File check status is: $Outcome"
exit $Result
