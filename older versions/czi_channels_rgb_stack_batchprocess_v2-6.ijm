setBatchMode(true); // Enable batch mode to prevent display updates

//USER defines type of interaction in dialog box
////////////////////////// Ask the user to choose a projection method///////////////////////

Dialog.create("Type of Projection");
//input 1
Dialog.addChoice("Type:", newArray("Max Intensity", "Standard Deviation"));
//input 2
Dialog.addNumber("Number of channels:", 4);
//input 3
Dialog.addNumber("Channel of nc82:", 3);


// Help button that opens a webpage
Dialog.addHelp("https://imagej.net/ij/macros/DialogDemo.txt");

// show the GUI
Dialog.show();

//output 1
projection  = Dialog.getChoice();
//output 2
ch = Dialog.getNumber();
//output 3
nc82 = Dialog.getNumber();

print("Projection is: "+ projection)
////////////////////////////////////////////////////////////////////////////////////////////



//define subfolder to save tif files into	
subfolder = "flattened-channels"+projection;
subfolder_tiff = "channels-tiff";
subfolder_nrrd = "channels-nrrd"



////////////////////////// Ask the user to choose a folder to process ///////////////////////
//USER chooses the folder the images are in
folder = getDirectory("Choose a Folder"); // Prompt the user to choose a folder

/////////////////////////////////////////////////////////////////////////////////////////////

//Initialize an empty array for unprocessed files
unprocessedFiles = newArray();


//new subfolder variables
new_subfolder = folder+subfolder+"\\";
new_subfolder_tiff = folder+subfolder_tiff+"\\";
new_subfolder_nrrd = folder+subfolder_nrrd+"\\";

//make subfolders
File.makeDirectory(new_subfolder);
File.makeDirectory(new_subfolder_tiff);
File.makeDirectory(new_subfolder_nrrd);


//print("Files will be saved in: "+new_subfolder)



list = getFileList(folder);

count=0


//press space if anything goes wrong
for (i = 0; i < list.length; i++) {
	
	print("cycle in list of files: "+i);
	
	//allow user to interrupt macro if needed
	interruptMacro = isKeyDown("space");
    if (interruptMacro == true) {
        print("interrupted");
        setKeyDown("none");
        setBatchMode(false);
        break;
    }
    
    //limits 3 images at a time
    //if (count == 4) {
    //	print("3 images analyzed");
    //	setBatchMode(false);
    //	break;
    //}
         
        
        
	if (endsWith(list[i], ".czi")) { // process only .czi files
		count += 1;
		
		print("count: "+count);
		print("working on file: "+i+1+" of "+list.length);
		print("list item: "+list[i]);
		
		file_name = list[i];
		print("file_name:"+file_name);
		
		file_to_open = folder+file_name;
		print("file_to_open:"+file_to_open);
		
		run("Bio-Formats Importer", "open=file_to_open color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	    print("file opened");
	    
	        
	            
	    // Check the number of channels in the opened image    
	    getDimensions(width, height, actualCh, slices, frames);
	    print("Actual number of channels: " + actualCh);
		
		// Compare with the user-defined number of channels
		if (actualCh != ch) {
			//add file to list of unprocessed files
			unprocessedFiles = Array.concat(unprocessedFiles, file_name);
        	//warn the user
		    print("Mismatch in number of channels for file: " + file_name + ". Expected: " + ch + ", but found: " + actualCh);
		    print("Skipping this file.");
		    run("Close All"); // Close the current image
		    continue; // Skip to the next file in the list
		}
	    
	    
	                
		//some images might have series, and bioformats importer uses Series 1, naming the file as "....czi #1"
		//correct filename if images were acquired as Series
		print(getTitle());
		img_title = getTitle();
		print("img_title:"+img_title);
		
		//rename title of image to be same as file name
		rename(file_name);
		
		//if (endsWith(img_title, "#1")) {
		//file_name = substring(file_name, 0, lengthOf(file_name) - 3); //exclude the " #1" at the end of the name
		//	print("file_name minus #1: "+file_name);
		//	print(getTitle());
		//	rename(file_name);
		//	print(getTitle());
		//}
	        
	        
	        
	    run("Split Channels");
	        
	    //merge each channel with channel 3 (nc82) and save:
	    // - tiff stacked to RGB file
	    // - tiff keeping channels
	    // - RDD keeping channels (for regisration)
	    for (ii = 1; ii < ch+1; ii++) { 		//ch input by the user
	    	print("working on channel: "+ii);
	    	if (ii != nc82) {					// nc82 input by the user
	    		run("Merge Channels...", "c2=C"+ii+"-"+file_name+" "+"c3=C"+nc82+"-"+file_name+" create keep");
	    		print("c2=C"+ii+"-"+file_name);
	    		print("c3=C3-"+file_name);
	    		//run("Merge Channels...", "c2=C2-20230810_Nuno4_MCFO_VNC-01(1)-Stitch.czi c3=C3-20230810_Nuno4_MCFO_VNC-01(1)-Stitch.czi create keep");
	    		
	    		//shorten file name (without .czi) to save new file versions
	    		file_name_substr = substring(file_name, 0, lengthOf(file_name) - 4); //exclude the .czi extension
	    		
	    		//save channels as tiff file	
	    		saving_file_name_ch_tif = new_subfolder_tiff+file_name_substr+"c"+ii+".tif";
	    		saveAs("Tiff", saving_file_name_ch_tif);
	    		print("tiff saved");
	    		
	    		//save channels as rdd file
	    		saving_file_name_ch_nrdd = new_subfolder_nrrd+file_name_substr+"c"+ii+".nrrd";
	    		run("Nrrd ... ", "nrrd=["+saving_file_name_ch_nrdd+"]");
	    		print("NRRD saved");
	    		
	    		//save RGB of stacked z projection as tiff
	      		run("Z Project...", "projection=[" + projection + "]"); //possible: projection=[Max Intensity], projection=[Standard Deviation]
	    		run("Stack to RGB");
	    		
	    		//change name of file depending on projection type (in Z Project...)
				if (projection == "Max Intensity") {
					name_append = "-MAX"; //"MAX is coherent with imageJ-s internal nomenclature
				}
				if (projection == "Standard Deviation") {
					name_append = "-StDev";
				}
		
				//save file	
		        saving_file_name = new_subfolder+file_name_substr+name_append+"c"+ii+".tif";
	    		saveAs("Tiff", saving_file_name);
	    		print("stack to RGB saved");
	    	}
	
	    }
			run("Close All");	
	        
	        
	        
	        
	        
	        //run("Z Project...", "projection=[" + projection + "]"); //possible: projection=[Max Intensity], projection=[Standard Deviation]
	        //run("Stack to RGB"); 
			
			//file_name_substr = substring(file_name, 0, lengthOf(file_name) - 4); //exclude the .czi extension
			
			
			//change name of file depending on projection type (in Z Project...)
			//if (projection == "Max Intensity") {
				//name_append = "-MAX"; //"MAX is coherent with imageJ-s internal nomenclature
			//}
			//if (projection == "Standard Deviation") {
				//name_append = "-StDev";
			//}
			
			//save file	
	        //saving_file_name = new_subfolder+file_name_substr+name_append+".tif";
	
	        //saveAs("Tiff", saving_file_name);
	        //open(saving_file_name);
	        
	        print(IJ.currentMemory());
	        print(IJ.freeMemory());
	    
		}
}

	//Export the list of unprocessed files to a text file
	if (lengthOf(unprocessedFiles) > 0) {
	    savePath = folder + "unprocessed_files.txt";
	    txtfile = File.open(savePath);
	    for (j = 0; j < lengthOf(unprocessedFiles); j++) {
	        File.append(unprocessedFiles[j], txtfile);
	        File.append("\n", txtfile); // New line for each file name
	    }
	    File.close(txtfile);
	    print("List of unprocessed files saved to: " + savePath);
	}
setBatchMode(false); // Disable batch mode at the end of the script
print("You got the end of misery with the lightness of Alice in Wonderland.");
print("Congratulations!");
print("I mean... All your files have been processed and saved.");

waitForUser;
run("Close All");