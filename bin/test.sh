
a=0
while [ $a = 0 ] 
do
ls *.Mod | xargs -n 1 ./aoc
a=$?
echo $a
done



