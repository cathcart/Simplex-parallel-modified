#!/bin/sh
#
#  run_script for basis optimization
#
#  Takes a name as parameter.
#
SIESTA="srun --mpi=mvapich /home/users/cathcart/code/trunk-367/Obj/siesta"
#
#
name=$1
#
#if [ -s $name/$name.out ] ; then
#  echo "Calculation $name completed"
#  exit
#fi

ERROR=$(grep -i -s -c -e "ERROR" -e "Stopping" $name/$name.out)
COMPLETE=$(grep -s -c "Total =" $name/$name.out)
PENDING=$(squeue -h -u cathcart -o "%j"|grep -c -s -i "$name")

echo $PENDING
echo $COMPLETE
echo $ERROR
grep -i -e "ERROR" -e "Stopping" $name/$name.out

if [ "$ERROR" = "" ];then
ERROR=0
fi

if [ "$COMPLETE" = "" ];then
COMPLETE=0
fi

if [ "$PENDING" -ge "1" ] && [ "$COMPLETE" = "0" ] && [ "$ERROR" = "0" ] ;then
  echo "Calculation $name is pending/running."
    exit
elif [ "$COMPLETE" -ge "1" ] && [ "$ERROR" = "0" ] ; then
  echo "Calculation $name is complete."
    exit
elif [ "$ERROR" -ge "1" ]; then
  echo "Calculation $name failed."
  cp null_file $name/OPTIM_OUTPUT
    exit
fi


if [ ! -d $name ];then
mkdir $name
fi
sed -f $name.sed TEMPLATE > $name/$name.fdf
cp *.psf $name
sed -e 's/JOBNAME/'$name'/' <batchfile  >$name/batchfile
cd $name
echo -e $SIESTA "< $name.fdf > $name.out\ncp BASIS_ENTHALPY OPTIM_OUTPUT">>batchfile
source ~/.bashrc
echo "submit $name"
sbatch batchfile
##rm -f *.psf *.xml *.psdump      # Optional. To save space
##cp BASIS_ENTHALPY OPTIM_OUTPUT
#---------
cd ..
