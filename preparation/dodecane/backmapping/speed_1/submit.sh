declare -a RNG=(12345 12355 12365 12375)
#declare -a RNG=(12345)
if [ "X$1" == "X" ]; then
  pattern="test_"
else
  pattern=$1
fi

ls | grep $pattern | sort -k2 -t_ -n | while read i; do
  cd $i
  resolution="`cat RES`"
  for idx in "${!RNG[@]}"; do
     echo "Submit $i $resolution $idx ${RNG[$idx]}"
     qsub -v "OUTPUT_PREFIX=sim${idx}","SEED=${RNG[$idx]}" -N "dd1_res_${resolution}_$idx" run_job.sh
  done
  cd $OLDPWD 
done
