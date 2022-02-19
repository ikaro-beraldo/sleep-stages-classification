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

___ Interface Image ____

## Pre-processing step

#### 1 - Using a raw data

Our algorithm uses a combination of recordings: (1) CA1 local field potentials and (2) electromyogram or accelerometer. Make sure both of the recordings are separated in different vectors stored on a MATLAB file (.mat).

1. Click on the _Load button_ and a file selection window will be opened
2. Select the MAT file containing the recordings and a second window will be opened

___ Load Interface ____

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

__Recording Interface__

#### Defining some classification parameters

1. Press the button _Output Path_ and select the directory where the classification results and figures are going to be saved
2. Define the _Recording Parameters_
3. Define the _Artifact detection amplitude trheshold_ (it is recommended to use the default value)
4. Check the option _Run visual inspection_ if it is the first time this dataset is being labeled
5. Check the option _Save some representative epochs_ if you want to save representative epochs for each state
6. Check the option _Start from the last step completed_ if you are resuming a classification
7. Check the option _Classify the transitions between NREM and REM_ if you want to classify part of the epochs as transitions
8. Check the option _Use a training dataset_ to use a training dataset when the GMM starts running

A new window will be opened

_____ Interface de selecionar banda _____

It is possible to add another frequency band to process of clustering carried out by the GMM algorithm. However the default option _None_ is encouraged. You can press the button _Open PDF files_ to check the EMG RMS and Theta/Delta ratio values for the epochs of this specific recording.

9. Press the button _OK_
