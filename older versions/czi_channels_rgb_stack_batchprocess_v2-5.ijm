//this version sets a limit of 3 images to be processed because of memory contraints

//setBatchMode(true); // Enable batch mode to prevent display updates

//USER defines type of interaction in dialog box
////////////////////////// Ask the user to choose a projection method///////////////////////

Dialog.create("Type of Projection");
//input 1
Dialog.addChoice("Type:", newArray("Max Intensity", "Standard Deviation"));

// Help button that opens a webpage
Dialog.addHelp("https://imagej.net/ij/macros/DialogDemo.txt");

// show the GUI
Dialog.show();

//output 1
projection  = Dialog.getChoice();

print("Projection is: "+ projection)
////////////////////////////////////////////////////////////////////////////////////////////



//projection = "Standard Deviation"; //possible: projection=[Max Intensity], projection=[Standard Deviation]
//define subfolder to save tif files into	
subfolder = "flattened-channels"+projection;
subfolder_tiff = "channels-tiff";
subfolder_nrrd = "channels-nrrd"



////////////////////////// Ask the user to choose a folder to process ///////////////////////
//USER chooses the folder the images are in
folder = getDirectory("Choose a Folder"); // Prompt the user to choose a folder

/////////////////////////////////////////////////////////////////////////////////////////////



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

//count=0


//press space if anything goes wrong
for (i = 0; i < list.length; i++) {
	print("cycle: "+i);
	
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
         
        
        
        file_name_substr = substring(file_name, 0, lengthOf(file_name) - 4); //exclude the .czi extension
        //open(folder+file_name);
        file_to_open = folder+file_name;
        run("Bio-Formats Importer", "open=file_to_open color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
        
        //some images might have series, and bioformats importer uses Series 1, naming the file as "....czi #1"
        //correct filename if images were acquired as Series
        print(getTitle());
        if (endsWith(file_name, "#1")) {
        	file_name = substring(file_name, 0, lengthOf(file_name) - 3); //exclude the " #1" at the end of the name
        	print("file_name minus #1: "+file_name);
        	print(getTitle());
        	rename(file_name);
        	print(getTitle());
        }
        
        
        
        run("Split Channels");
        
        //merge each channel with channel 3 (nc82) and save:
        // - tiff stacked to RGB file
        // - tiff keeping channels
        // - RDD keeping channels (for regisration)
        for (ii = 1; ii < 5; ii++) {
        	print("working on channel: "+ii);
        	if (ii != 3) {
        		run("Merge Channels...", "c2=C"+ii+"-"+file_name+" "+"c3=C3-"+file_name+" create keep");
        		print("c2=C"+ii+"-"+file_name);
        		print("c3=C3-"+file_name);
        		//run("Merge Channels...", "c2=C2-20230810_Nuno4_MCFO_VNC-01(1)-Stitch.czi c3=C3-20230810_Nuno4_MCFO_VNC-01(1)-Stitch.czi create keep");
        		
        		//save channels as tiff file	
        		saving_file_name_ch_tif = new_subfolder_tiff+file_name_substr+"c"+ii+".tif";
        		saveAs("Tiff", saving_file_name_ch_tif);
        		print("tiff saved");
        		
        		//save channels as rdd file
        		saving_file_name_ch_nrdd = new_subfolder_nrrd+file_name_substr+"c"+ii+".nrrd";
        		run("Nrrd ... ", "nrrd=[saving_file_name_ch_nrdd]");
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
        
        run("Close All");
    
	}
}

setBatchMode(false); // Disable batch mode at the end of the script
print("You got the end of misery with the lightness of Alice in Wonderland.")
print("Congratulations!")
print("I mean... All your files have been processed and saved.")

waitForUser;
run("Close All");

