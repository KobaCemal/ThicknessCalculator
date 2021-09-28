## Get all the coordinates in gray matter mask
3dmaskdump -mask lh.ribbon.nii lh.ribbon.nii | awk '{print $1 " " $2 " " $3}' > surfacein1D.txt


## Sort the coordinates in each direction (because I couldn't use "sort" function efficiently). 
awk '{print $1 " " $2 " " $3}' surfacein1D.txt | sort -k1n > valuesinXtemp.txt
awk '{print $3 " " $1 " " $2}' surfacein1D.txt | sort -k1n > valuesinYtemp.txt
awk '{print $2 " " $3 " " $1}' surfacein1D.txt | sort -k1n > valuesinZtemp.txt



for direction in X Y Z 
do
	thicknessValue=1
	prevLine=( 0 0 0 )

	 ## Read the lines one by one so we can see how many consecutive voxels there are in the mask 
	 while IFS= read line 
	 do
	 	 currentLine=($line)
	 	 difference=$(( ${currentLine[2]} - ${prevLine[2]} ))

	 	## Check if the previous voxel is next to current voxel in given direction. If they are next to each other, add one to thickness value.
	 	if [ "$difference" -eq 1 ]
		 	then
		 		thicknessValue=$(( thicknessValue + 1 ))
		 		echo "$thicknessValue" >> thicknessin"$direction"_temp.txt
		 	else
		 		thicknessValue=1
		 		echo "$thicknessValue" >> thicknessin"$direction"_temp.txt
		 fi

		 prevLine=($line)
	 done < valuesin"$direction"temp.txt


## Reverse the  thickness values. This is necesarry for next step.
tac thicknessin"$direction"_temp.txt > thicknessin"$direction"_reverse.txt


## Convert increasing values to maximum value of the chunk, so the resuslts don't look like a gradient.
prevVal=( 1 )
maxVal=( 1 )
	while IFS= read line
	do
		currentVal=($line)
		difference=$(( ${prevVal[0]} - ${currentVal[0]} ))

		if [ "$difference" -eq 1 ]
		then
			echo ${maxVal[0]} >> thicknessin"$direction"_clean.txt
		else
			maxVal=${currentVal[0]}
			echo ${maxVal[0]} >> thicknessin"$direction"_clean.txt
		fi

		prevVal=($line)
	done < thicknessin"$direction"_reverse.txt

	tac thicknessin"$direction"_clean.txt > thicknessin"$direction".txt
done


## Reorder the columns to their original positions
mv valuesinXtemp.txt valuesinX.txt
awk '{print $2 " " $3 " " $1}' valuesinYtemp.txt  > valuesinY.txt
awk '{print $3 " " $1 " " $2}' valuesinYtemp.txt > valuesinZ.txt

## Merge the directions and thickness values and save them as nifti
for direction in X Y Z
do
	paste -d " " valuesin"$direction".txt thicknessin"$direction".txt >> "$direction"toVol.txt
 	3dUndump -prefix "$direction"thick.nii.gz -master lh.ribbon.nii -mask lh.ribbon.nii -datum float -ijk "$direction"toVol.txt
done

## Merge the thickness values in three directions and save the minimum number of each voxel.
3dbucket -prefix 3Dthick.nii.gz *thick.nii.gz
3dTstat -min -prefix finalThickness.nii.gz 3Dthick.nii.gz

#Smooth the final results
3dBlurToFWHM -input finalThickness.nii.gz -FHWM 6 -prefix finalThickness_6mm.nii.gz -mask lh.ribbon.nii



