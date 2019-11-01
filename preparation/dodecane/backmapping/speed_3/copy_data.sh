for d in test_*; do
  CPWD="`pwd`"
  cd $d

  res="`cat RES`"
  if [ "X$res" != "X" ]; then
    cp -v energy.csv "../data/energy_${res}.csv"
  fi

  cd $CPWD
done
