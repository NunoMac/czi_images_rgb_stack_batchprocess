setBatchMode(true); // Enable batch mode to prevent display updates

folder="E:/Immunohisto/Nuno6 - y;;Chat-3xGal80"; //change for each batch of images

list = getFileList(folder);

for (i = 0; i < list.length; i++) {
    if (endsWith(list[i], ".czi")) { // process only .czi files
        file_name = list[i];
        open(folder+file_name);
        
        run("Z Project...", "projection=[Standard Deviation]"); //also possible: projection=[Max Intensity]
        run("Stack to RGB"); 
		
		file_name_substr = substring(file_name, 0, lengthOf(file_name) - 4); //exclude the .czi extension
        saving_file_name = folder+file_name_substr+"MAX.tif"; //"MAX is coherent with imageJ-s internal nomenclature
        

        saveAs("Tiff", saving_file_name);
        //open(saving_file_name);
    }
}

setBatchMode(false); // Disable batch mode at the end of the script

//waitForUser;
//run("Close All");
