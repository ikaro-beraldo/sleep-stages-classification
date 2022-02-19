# Sleep-Wake Cycle Classification Toolbox
MatLab language toolbox for classification of sleep-wake cycle

# Installation
1 - Download all the files from the master branch;

2 - Add all scripts, functions and variable files on MATLAB's 'Search Path' 
(More details: https://www.mathworks.com/help/matlab/matlab_env/add-remove-or-reorder-folders-on-the-search-path.html);

# Usage

For a complete a tutorial, check the file **Sleep-Wake Cycle Classification Toolbox Tutorial.pdf**

Run the following command on MATLAB's command window:
`RMS_pwelch_integrate`

The primary window will be opened

![Main window](/Toolbox_images/Main_interface.png)

## Pre-processing step

#### 1 - Using a raw data

Our algorithm uses a combination of recordings: (1) CA1 local field potentials and (2) electromyogram or accelerometer. Make sure both of the recordings are separated in different vectors stored on a MATLAB file (.mat).

1. Click on the _Load button_ and a file selection window will be opened
2. Select the MAT file containing the recordings and a second window will be opened

![Main window](/Toolbox_images/Load_interface.png)

3. Select which vectors are going to be loaded and the sampling frequency associated with them
4. In the _Sleep-wake cycle sorting_ panel, select the option _1 - Use workspace data_
   - Select the CA1 LFP vector on the _CA1 Channel List Box_
   - If you are using an EMG recording, select the option _EMG_ and select the corresponding vector on the _EMG/Accel Channel list box_
   - If you are using a single accelerometer recording, select the option _Accel 1_and select the corresponding vector on the _EMG/Accel Channel list box_
   - If you are using a 3 channel accelerometer recording, select the option _Accel 3_ and select each one of the accelerometer vector on the list boxes _X_, _Y_ and _Z_
5. Check the box _Include the algorithm pre-processing step_
6. Define the _Power Line Noise_ frequency, the _Epoch Length_, and the _Output Sampling Frequency_
7. Press _Run_
  
#### 2 - Using a data already pre-processed by the toolbox
If a dataset has already been pre-processed or you want to resume/restart a classification

1. In the _Sleep-wake cycle sorting_ panel, select the option _2 - Load pre-processed variables_
2. Select the file _data_variables.mat_ regarding the data set previously used
3. Check the box _Include the algorithm pre-processing step_
4. Define the _Power Line Noise_ frequency, the _Epoch Length_, and the _Output Sampling Frequency_
5. Press _Run_

## Classification itself

After the loading and pre-processing steps a new window will be opened

![Main window](/Toolbox_images/Recording_parameters.png)

#### Defining some classification parameters

1. Press the button _Output Path_ and select the directory where the classification results and figures are going to be saved
2. Define the _Recording Parameters_
3. Define the _Artifact detection amplitude trheshold_ (it is recommended to use the default value)
4. Check the option _Run visual inspection_ if it is the first time this dataset is being labeled
5. Check the option _Save some representative epochs_ if you want to save representative epochs for each state
6. Check the option _Start from the last step completed_ if you are resuming a classification
7. Check the option _Classify the transitions between NREM and REM_ if you want to classify part of the epochs as transitions
8. Check the option _Use a training dataset_ to use a training dataset when the GMM starts running (It is recommended to check this option)

A new window will be opened

![Main window](/Toolbox_images/Add_bands.png)

It is possible to add another frequency band to process of clustering carried out by the GMM algorithm. However the default option _None_ is encouraged. You can press the button _Open PDF files_ to check the EMG RMS and Theta/Delta ratio values for the epochs of this specific recording.

9. Press the button _OK_

#### Selection of preliminary clusters

If you have not checked the option to use a training dataset, you will be shown a new window. The preliminary clusters will be marked in red.

![Main window](/Toolbox_images/Gmm_clustering.png)

1. Press 'Run Again' until an suitable set of clusters is shown
2. Press 'OK' to confirm the preliminary clusters formed

#### Manual inspection of epochs

If the you have checked the option to run the visual inspection, a new window will be opened. You will have to label a specific number of epochs for each state in order to processed with the classification.

![Main window](/Toolbox_images/Visual_Inspection.png)

* Press one of the following buttons to label the epoch shown:
  1. AWAKE: the epoch is classified as an AWAKE period
  2. NREM: the epoch is classified as a NREM sleep period
  3. REM: the epoch is classified as a REM sleep period
  4. Transitions: the epoch is classified as one the transitions
  5. None: the epoch is not labeled

After the specified number of epochs has been classified, the classification algorithm will be resumed.
  
#### Finishing the classification

After all the steps have been completed, the classification will be finished. Check the __Output Path__ defined previously for the results. All the figures produced during the process and MAT files recarding the classification will be stored there. 

Look for the variable 'GMM.All_Sort' inside the 'GMM_Classification.mat' file. It contains the classification coding for the epochs of the recording:
- 1: REM
- 2: NREM
- 3: AWAKE
- -1: Excluded epochs (artifacts)
